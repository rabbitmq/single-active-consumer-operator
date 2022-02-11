# RabbitMQ Single Active Consumer Kubernetes Operator

**NOTE**: This software is provided in an alpha state, as a preview of upcoming RabbitMQ features,
and as such provides no guarantees of stability.

This Kubernetes operator serves as an automated orchestration layer to create a single-active-consumer topology
on a RabbitMQ Cluster with SuperStreams. In this topology, a single SuperStream can be partitioned into smaller
partition streams; the purpose of this operator is to ensure that for each partition, exactly one application Pod
is consuming from the partition stream at any given time.

## Quickstart

Before deploying the Single Active Consumer Operator, you need to have:

1. A Running k8s cluster
2. RabbitMQ [Cluster Operator](https://github.com/rabbitmq/cluster-operator) installed in the k8s cluster
3. RabbitMQ [Messaging Topology Operator](https://github.com/rabbitmq/messaging-topology-operator) installed in the k8s cluster
4. [Cert-manager](https://cert-manager.io/docs/installation/kubernetes/) installed in the k8s cluster
5. A [RabbitMQ cluster](https://github.com/rabbitmq/cluster-operator/tree/main/docs/examples) deployed using the Cluster Operator,
running RabbitMQ 3.9 and with the streams plugin enabled

Assuming you have `kubectl` configured to access your running k8s cluster, you can then run the following command to install the Single Active Consumer Topology Operator:

```bash
kubectl apply -f https://github.com/rabbitmq/single-active-consumer-operator/releases/latest/download/single-active-consumer-operator-with-certmanager.yaml
```

## Documentation

A documented example of using this topology can be found in the [examples directory](./docs/examples/README.md).

## Contributing

This project follows the typical GitHub pull request model. Before starting any work, please either comment on an [existing issue](https://github.com/rabbitmq/messaging-topology-operator/issues), or file a new one.

Please read [contribution guidelines](CONTRIBUTING.md) if you are interested in contributing to this project.

## License

[Licensed under the MPL](LICENSE.txt), same as RabbitMQ server and operators.

## Copyright

Copyright 2022 VMware, Inc. All Rights Reserved.