/*
Copyright 2022.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package v1alpha1

import (
	topology "github.com/rabbitmq/messaging-topology-operator/api/v1beta1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime/schema"
)

// SuperStreamConsumerSpec defines the desired state of SuperStreamConsumer
type SuperStreamConsumerSpec struct {
	// Reference to the SuperStream that the SuperStreamConsumer will consume from, in the same namespace.
	// Required property.
	// +kubebuilder:validation:Required
	SuperStreamReference SuperStreamReference `json:"superStreamReference"`
	// ConsumerPodSpec defines the PodSpecs to use for any consumer Pods that are created for the SuperStream.
	// +kubebuilder:validation:Required
	ConsumerPodSpec SuperStreamConsumerPodSpec `json:"consumerPodSpec"`
}

type SuperStreamConsumerPodSpec struct {
	// Default defines the PodSpec to use for all consumer Pods, if no routing key-specific PodSpec is provided.
	// +kubebuilder:validation:Optional
	Default *corev1.PodSpec `json:"default,omitempty"`
	// PerRoutingKey maps PodsSpecs to specific routing keys. If a consumer is spun up for a SuperStream partition,
	// and the routing key for that partition matches an entry in PerRoutingKey, that PodSpec will be used for the
	// consumer Pod; otherwise the default PodSpec is used.
	// +kubebuilder:validation:Optional
	PerRoutingKey map[string]*corev1.PodSpec `json:"perRoutingKey,omitempty"`
}

// SuperStreamConsumerStatus defines the observed state of SuperStreamConsumer
type SuperStreamConsumerStatus struct {
	// observedGeneration is the most recent successful generation observed for this SuperStreamConsumer. It corresponds to the
	// SuperStreamConsumer's generation, which is updated on mutation by the API Server.
	ObservedGeneration int64                `json:"observedGeneration,omitempty"`
	Conditions         []topology.Condition `json:"conditions,omitempty"`
}

//+kubebuilder:object:root=true
//+kubebuilder:subresource:status

// SuperStreamConsumer is the Schema for the superstreamconsumers API
type SuperStreamConsumer struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   SuperStreamConsumerSpec   `json:"spec,omitempty"`
	Status SuperStreamConsumerStatus `json:"status,omitempty"`
}

//+kubebuilder:object:root=true

// SuperStreamConsumerList contains a list of SuperStreamConsumer
type SuperStreamConsumerList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []SuperStreamConsumer `json:"items"`
}

func (s *SuperStreamConsumer) GroupResource() schema.GroupResource {
	return schema.GroupResource{
		Group:    s.GroupVersionKind().Group,
		Resource: s.GroupVersionKind().Kind,
	}
}

type SuperStreamReference struct {
	// The name of the SuperStream to reference.
	// +kubebuilder:validation:Required
	Name string `json:"name"`
	// The namespace of the SuperStream to reference.
	Namespace string `json:"namespace,omitempty"`
}

func init() {
	SchemeBuilder.Register(&SuperStreamConsumer{}, &SuperStreamConsumerList{})
}
