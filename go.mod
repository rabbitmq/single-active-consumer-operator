module github.com/rabbitmq/single-active-consumer-operator

go 1.16

require (
	github.com/elastic/crd-ref-docs v0.0.7
	github.com/michaelklishin/rabbit-hole/v2 v2.12.0
	github.com/mitchellh/hashstructure/v2 v2.0.2
	github.com/onsi/ginkgo/v2 v2.1.1
	github.com/onsi/gomega v1.18.0
	github.com/rabbitmq/cluster-operator v1.11.1
	github.com/rabbitmq/messaging-topology-operator v1.3.0
	github.com/sclevine/yj v0.0.0-20200815061347-554173e71934
	k8s.io/api v0.22.2
	k8s.io/apimachinery v0.22.2
	k8s.io/client-go v0.22.2
	k8s.io/utils v0.0.0-20210819203725-bdf08cb9a70a
	sigs.k8s.io/controller-runtime v0.10.3
	sigs.k8s.io/controller-runtime/tools/setup-envtest v0.0.0-20210623192810-985e819db7af
	sigs.k8s.io/controller-tools v0.7.0
	sigs.k8s.io/kustomize/kustomize/v4 v4.4.1
)
