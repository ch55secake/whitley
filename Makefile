TERRAFORM_DIR := terraform

.PHONY: init apply destroy fmt validate

## terraform init
init:
	terraform -chdir=$(TERRAFORM_DIR) init

## Full apply — bootstraps k3s, fetches kubeconfig, then deploys Rancher.
## Internally runs two Terraform applies: the first installs k3s and writes
## the kubeconfig to disk; the second deploys cert-manager and Rancher once
## the kubeconfig exists for the helm/kubernetes providers to consume.
apply:
	terraform -chdir=$(TERRAFORM_DIR) apply -target=module.k3s
	terraform -chdir=$(TERRAFORM_DIR) apply

## Tear down all resources.
## Runs destroy provisioners on k3s nodes (uninstalls k3s) and removes all
## Helm releases and Kubernetes resources managed by Terraform.
## Note: deletes terraform/kubeconfig.yaml after destroy completes.
destroy:
	terraform -chdir=$(TERRAFORM_DIR) destroy
	rm -f $(TERRAFORM_DIR)/kubeconfig.yaml

## Port-forward Rancher UI to https://localhost:8443
ui:
	kubectl port-forward -n cattle-system svc/rancher 8443:443 --kubeconfig $(TERRAFORM_DIR)/kubeconfig.yaml

fmt:
	terraform -chdir=$(TERRAFORM_DIR) fmt -recursive

validate:
	terraform -chdir=$(TERRAFORM_DIR) validate
