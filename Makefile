SHELL := bash
PLATFORM := $(shell uname)
platform := $(shell echo $(PLATFORM) | tr A-Z a-z)
ARCHITECTURE := $(shell uname -m)

# runs the target list by default
.DEFAULT_GOAL = list

# Insert a comment starting with '##' after a target, and it will be printed by 'make' and 'make list'
list:    ## list Makefile targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

CURL ?= /usr/bin/curl
ifneq ($(PLATFORM),Darwin)
$(CURL):
	$(error Please install curl)
endif

CLUSTER_OPERATOR_VERSION ?=v1.11.1
TOPOLOGY_OPERATOR_VERSION ?=v1.3.0
CERT_MANAGER_VERSION ?=v1.7.0

LOCAL_BIN = $(CURDIR)/bin
$(LOCAL_BIN):
	mkdir $(LOCAL_BIN)
CMCTL_BIN := cmctl
CMCTL := $(CURDIR)/bin/$(CMCTL_BIN)
CMCTL_FILE := cmctl-$(platform)-$(shell go env GOARCH).tar.gz
CMCTL_URL := https://github.com/jetstack/cert-manager/releases/download/$(CERT_MANAGER_VERSION)/$(CMCTL_FILE)
$(CMCTL): | $(CURL) $(LOCAL_BIN)
	$(CURL) --progress-bar --fail --location --output $(LOCAL_BIN)/$(CMCTL_FILE) "$(CMCTL_URL)"
	cd $(LOCAL_BIN) && \
	tar -xzf $(CMCTL_FILE) $(CMCTL_BIN) && \
	rm -rf $(CMCTL_FILE)

install-tools:
	go mod download
	grep _ tools/tools.go | awk -F '"' '{print $$2}' | xargs -t go install

ENVTEST_K8S_VERSION = 1.22.1
LOCAL_TESTBIN = $(CURDIR)/testbin
# "Control plane binaries (etcd and kube-apiserver) are loaded by default from /usr/local/kubebuilder/bin.
# This can be overridden by setting the KUBEBUILDER_ASSETS environment variable"
# https://pkg.go.dev/sigs.k8s.io/controller-runtime/pkg/envtest
export KUBEBUILDER_ASSETS = $(LOCAL_TESTBIN)/k8s/$(ENVTEST_K8S_VERSION)-$(platform)-$(shell go env GOARCH)

$(KUBEBUILDER_ASSETS): install-tools
	setup-envtest --os $(platform) --arch $(shell go env GOARCH) --bin-dir $(LOCAL_TESTBIN) use $(ENVTEST_K8S_VERSION)

.PHONY: unit-tests
unit-tests: $(KUBEBUILDER_ASSETS) generate fmt vet manifests ## Run unit tests
	ginkgo -r --randomize-all api/ internal/


system-tests: ## run end-to-end tests against Kubernetes cluster defined in ~/.kube/config. Expects cluster operator and messaging topology operator to be installed in the cluster
	NAMESPACE="rabbitmq-system" ginkgo -randomize-all -r system_tests/

# Build manager binary
manager: generate fmt vet
	go build -o bin/manager main.go

# Run against the configured Kubernetes cluster in ~/.kube/config
#
# Since this runs outside a cluster and there's a requirement on cluster-level service
# communication, the connection between them needs to be accounted for.
# https://github.com/telepresenceio/telepresence is one way to do this (just run
# `telepresence connect` and services like `test-service.test-namespace.svc.cluster.local`
# will resolve properly).
run: generate fmt vet manifests just-run

just-run: ## Just runs 'go run main.go' without regenerating any manifests or deploying RBACs
	KUBE_CONFIG=${HOME}/.kube/config OPERATOR_NAMESPACE=rabbitmq-system ENABLE_WEBHOOKS=false go run ./main.go

# Install CRDs into a cluster
install: manifests
	kustomize build config/crd | kubectl apply -f -

# Uninstall CRDs from a cluster
uninstall: manifests
	kustomize build config/crd | kubectl delete -f -

deploy-manager:
	kustomize build config/default/base | kubectl apply -f -

deploy: manifests deploy-rbac deploy-manager

destroy:
	kustomize build config/rbac | kubectl delete --ignore-not-found=true -f -
	kustomize build config/default/base | kubectl delete --ignore-not-found=true -f -

# Deploy operator with local changes
deploy-dev: check-env-docker-credentials docker-build-dev manifests deploy-rbac docker-registry-secret set-operator-image-repo
	kustomize build config/default/overlays/dev | sed 's@((operator_docker_image))@"$(DOCKER_REGISTRY_SERVER)/$(OPERATOR_IMAGE):$(GIT_COMMIT)"@' | kubectl apply -f -

# Load operator image and deploy operator into current KinD cluster
deploy-kind: manifests deploy-rbac
	docker build --build-arg=GIT_COMMIT=$(GIT_COMMIT) -t $(DOCKER_REGISTRY_SERVER)/$(OPERATOR_IMAGE):$(GIT_COMMIT) .
	kind load docker-image $(DOCKER_REGISTRY_SERVER)/$(OPERATOR_IMAGE):$(GIT_COMMIT)
	kustomize build config/default/overlays/kind | sed 's@((operator_docker_image))@"$(DOCKER_REGISTRY_SERVER)/$(OPERATOR_IMAGE):$(GIT_COMMIT)"@' | kubectl apply -f -

deploy-rbac:
	kustomize build config/rbac | kubectl apply -f -

# Generate manifests e.g. CRD, RBAC etc.
manifests: install-tools
	controller-gen crd rbac:roleName=manager-role webhook paths="./..." output:crd:artifacts:config=config/crd/bases
	./hack/remove-podspec-descriptions.sh

# Generate API reference documentation
api-reference:
	crd-ref-docs \
		--source-path ./api \
		--config ./docs/api/autogen/config.yaml \
		--templates-dir ./docs/api/autogen/templates \
		--output-path ./docs/api/rabbitmq.com.ref.asciidoc \
		--max-depth 30

# Run go fmt against code
fmt:
	go fmt ./...

# Run go vet against code
vet:
	go vet ./...

# Generate code & docs
generate: install-tools api-reference
	controller-gen object:headerFile="hack/boilerplate.go.txt" paths="./..."

check-env-docker-credentials: check-env-registry-server
ifndef DOCKER_REGISTRY_USERNAME
	$(error DOCKER_REGISTRY_USERNAME is undefined: Username for accessing the docker registry)
endif
ifndef DOCKER_REGISTRY_PASSWORD
	$(error DOCKER_REGISTRY_PASSWORD is undefined: Password for accessing the docker registry)
endif
ifndef DOCKER_REGISTRY_SECRET
	$(error DOCKER_REGISTRY_SECRET is undefined: Name of Kubernetes secret in which to store the Docker registry username and password)
endif

docker-build-dev: check-env-docker-repo  git-commit-sha
	docker build --build-arg=GIT_COMMIT=$(GIT_COMMIT) -t $(DOCKER_REGISTRY_SERVER)/$(OPERATOR_IMAGE):$(GIT_COMMIT) .
	docker push $(DOCKER_REGISTRY_SERVER)/$(OPERATOR_IMAGE):$(GIT_COMMIT)

docker-registry-secret: check-env-docker-credentials operator-namespace
	echo "creating registry secret and patching default service account"
	@kubectl -n $(K8S_OPERATOR_NAMESPACE) create secret docker-registry $(DOCKER_REGISTRY_SECRET) --docker-server='$(DOCKER_REGISTRY_SERVER)' --docker-username="$$DOCKER_REGISTRY_USERNAME" --docker-password="$$DOCKER_REGISTRY_PASSWORD" || true
	@kubectl -n $(K8S_OPERATOR_NAMESPACE) patch serviceaccount single-active-consumer-operator -p '{"imagePullSecrets": [{"name": "$(DOCKER_REGISTRY_SECRET)"}]}'

git-commit-sha:
ifeq ("", git diff --stat)
GIT_COMMIT=$(shell git rev-parse --short HEAD)
else
GIT_COMMIT=$(shell git rev-parse --short HEAD)-
endif

check-env-registry-server:
ifndef DOCKER_REGISTRY_SERVER
	$(error DOCKER_REGISTRY_SERVER is undefined: URL of docker registry containing the Operator image (e.g. registry.my-company.com))
endif

check-env-docker-repo: check-env-registry-server set-operator-image-repo

set-operator-image-repo:
OPERATOR_IMAGE?=p-rabbitmq-for-kubernetes/single-active-consumer-operator

operator-namespace:
ifeq (, $(K8S_OPERATOR_NAMESPACE))
K8S_OPERATOR_NAMESPACE=rabbitmq-system
endif

dependency-operators: | $(LOCAL_BIN) $(CMCTL)
	@kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/$(CERT_MANAGER_VERSION)/cert-manager.yaml
	@kubectl apply -f https://github.com/rabbitmq/cluster-operator/releases/download/$(CLUSTER_OPERATOR_VERSION)/cluster-operator.yml
	@$(CMCTL) check api --wait=2m
	@kubectl apply -f https://github.com/rabbitmq/messaging-topology-operator/releases/download/$(TOPOLOGY_OPERATOR_VERSION)/messaging-topology-operator-with-certmanager.yaml

destroy-dependency-operators:
	@kubectl delete -f https://github.com/rabbitmq/messaging-topology-operator/releases/download/$(TOPOLOGY_OPERATOR_VERSION)/messaging-topology-operator-with-certmanager.yaml --ignore-not-found
	@kubectl delete -f https://github.com/rabbitmq/cluster-operator/releases/download/$(CLUSTER_OPERATOR_VERSION)/cluster-operator.yml --ignore-not-found
	@kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/$(CERT_MANAGER_VERSION)/cert-manager.yaml --ignore-not-found

## used in CI pipeline to create release artifact
generate-manifests:
	mkdir -p releases
	kustomize build config/installation/ > releases/single-active-consumer-operator-with-certmanager.yaml
