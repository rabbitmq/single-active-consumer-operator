module github.com/rabbitmq/single-active-consumer-operator

go 1.16

require (
	github.com/michaelklishin/rabbit-hole/v2 v2.12.0
	github.com/mitchellh/hashstructure/v2 v2.0.2
	github.com/onsi/ginkgo/v2 v2.0.0
	github.com/onsi/gomega v1.18.1
	github.com/rabbitmq/cluster-operator v1.12.0
	github.com/rabbitmq/messaging-topology-operator v1.4.0
	k8s.io/api v0.23.4
	k8s.io/apimachinery v0.23.4
	k8s.io/client-go v0.23.4
	k8s.io/utils v0.0.0-20211116205334-6203023598ed
	sigs.k8s.io/controller-runtime v0.11.1
)
