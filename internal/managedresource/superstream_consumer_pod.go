package managedresource

import (
	"fmt"
	"github.com/mitchellh/hashstructure/v2"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	"strconv"
	"strings"
)

const (
	AnnotationSuperStream           = "rabbitmq.com/super-stream"
	AnnotationSuperStreamPartition  = "rabbitmq.com/super-stream-partition"
	AnnotationSuperStreamRoutingKey = "rabbitmq.com/super-stream-routing-key"
	AnnotationConsumerPodSpecHash   = "rabbitmq.com/consumer-pod-spec-hash"
)

type SuperStreamConsumerPodBuilder struct {
	objectOwner     metav1.Object
	scheme          *runtime.Scheme
	podSpec         corev1.PodSpec
	superStreamName string
	partition       string
}

func SuperStreamConsumerPod(objectOwner metav1.Object, scheme *runtime.Scheme, podSpec corev1.PodSpec, superStreamName, partition string) *SuperStreamConsumerPodBuilder {
	return &SuperStreamConsumerPodBuilder{objectOwner, scheme, podSpec, superStreamName, partition}
}

func (builder *SuperStreamConsumerPodBuilder) Build() (client.Object, error) {
	podSpecHash, err := hashstructure.Hash(builder.podSpec, hashstructure.FormatV2, nil)
	if err != nil {
		return nil, err
	}
	return &corev1.Pod{
		ObjectMeta: metav1.ObjectMeta{
			GenerateName: fmt.Sprintf("%s-%s-", builder.objectOwner.GetName(), builder.partition),
			Namespace:    builder.objectOwner.GetNamespace(),
			Labels: map[string]string{
				AnnotationSuperStream:          builder.superStreamName,
				AnnotationSuperStreamPartition: builder.partition,
				AnnotationConsumerPodSpecHash:  strconv.FormatUint(podSpecHash, 16),
			},
		},
		Spec: builder.podSpec,
	}, nil
}

func (builder *SuperStreamConsumerPodBuilder) Update(object client.Object) error {
	if err := controllerutil.SetControllerReference(builder.objectOwner, object, builder.scheme); err != nil {
		return fmt.Errorf("failed setting controller reference: %w", err)
	}

	return nil
}

func (builder *SuperStreamConsumerPodBuilder) ResourceType() string { return "SuperStreamConsumerPod" }

func PartitionNameToRoutingKey(parentObjectName, partitionName string) string {
	return strings.TrimPrefix(partitionName, fmt.Sprintf("%s-", parentObjectName))
}
