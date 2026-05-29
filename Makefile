TERRAFORM_DIR := terraform

.PHONY: init stage1 stage2 apply destroy fmt validate

## terraform init
init:
	terraform -chdir=$(TERRAFORM_DIR) init

## Stage 1 — bootstrap k3s nodes and fetch kubeconfig
## Must complete before stage2; writes kubeconfig.yaml to terraform/
stage1:
	terraform -chdir=$(TERRAFORM_DIR) apply -target=module.k3s

## Stage 2 — deploy cert-manager + Rancher (requires kubeconfig from stage1)
stage2:
	terraform -chdir=$(TERRAFORM_DIR) apply

## Full apply (only safe after kubeconfig already exists from a prior stage1)
apply:
	terraform -chdir=$(TERRAFORM_DIR) apply

## Tear down all resources.
## Runs destroy provisioners on k3s nodes (uninstalls k3s) and removes all
## Helm releases and Kubernetes resources managed by Terraform.
## Note: deletes terraform/kubeconfig.yaml after destroy completes.
destroy:
	terraform -chdir=$(TERRAFORM_DIR) destroy
	rm -f $(TERRAFORM_DIR)/kubeconfig.yaml

fmt:
	terraform -chdir=$(TERRAFORM_DIR) fmt -recursive

validate:
	terraform -chdir=$(TERRAFORM_DIR) validate
