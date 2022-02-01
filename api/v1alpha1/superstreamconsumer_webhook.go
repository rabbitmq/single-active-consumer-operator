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
	"fmt"
	apierrors "k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/util/validation/field"
	ctrl "sigs.k8s.io/controller-runtime"
	logf "sigs.k8s.io/controller-runtime/pkg/log"
	"sigs.k8s.io/controller-runtime/pkg/webhook"
)

// log is for logging in this package.
var superstreamconsumerlog = logf.Log.WithName("superstreamconsumer-resource")

func (r *SuperStreamConsumer) SetupWebhookWithManager(mgr ctrl.Manager) error {
	return ctrl.NewWebhookManagedBy(mgr).
		For(r).
		Complete()
}

//+kubebuilder:webhook:path=/validate-rabbitmq-com-v1alpha1-superstreamconsumer,mutating=false,failurePolicy=fail,sideEffects=None,groups=rabbitmq.com,resources=superstreamconsumers,verbs=create;update,versions=v1alpha1,name=vsuperstreamconsumer.kb.io,admissionReviewVersions=v1

var _ webhook.Validator = &SuperStreamConsumer{}

// ValidateCreate implements webhook.Validator so a webhook will be registered for the type
func (r *SuperStreamConsumer) ValidateCreate() error {
	superstreamconsumerlog.Info("validate create", "name", r.Name)
	return nil
}

// ValidateUpdate implements webhook.Validator so a webhook will be registered for the type
func (r *SuperStreamConsumer) ValidateUpdate(old runtime.Object) error {
	superstreamconsumerlog.Info("validate update", "name", r.Name)

	oldSuperStreamConsumer, ok := old.(*SuperStreamConsumer)
	if !ok {
		return apierrors.NewBadRequest(fmt.Sprintf("expected a superstream but got a %T", old))
	}

	detailMsg := "updates on superStreamReference are forbidden"

	if r.Spec.SuperStreamReference != oldSuperStreamConsumer.Spec.SuperStreamReference {
		return apierrors.NewForbidden(r.GroupResource(), r.Name,
			field.Forbidden(field.NewPath("spec", "superStreamReference"), detailMsg))
	}
	return nil

}

// ValidateDelete implements webhook.Validator so a webhook will be registered for the type
func (r *SuperStreamConsumer) ValidateDelete() error {
	superstreamconsumerlog.Info("validate delete", "name", r.Name)
	return nil
}
