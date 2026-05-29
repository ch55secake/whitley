# terraform/main.tf
# Root module — wires the k3s bootstrap and Rancher deployment together.
#
# Execution order (managed via depends_on and provider config):
#   1. module.k3s  — installs k3s on both nodes, fetches kubeconfig locally
#   2. module.rancher — deploys cert-manager + Rancher via Helm

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  # Local backend — suitable for a single-operator home lab.
  # For team use, replace with a remote backend (S3, Terraform Cloud, etc.)
  # and ensure the state file is encrypted at rest.
  backend "local" {
    path = "terraform.tfstate"
  }
}

# ---------------------------------------------------------------------------
# Providers — configured after kubeconfig is available on disk.
# The kubeconfig is written by module.k3s; both providers reference it by
# path so they pick it up on the apply that creates it.
# ---------------------------------------------------------------------------
provider "helm" {
  kubernetes {
    config_path = local.kubeconfig_path_or_null
  }
}

provider "kubernetes" {
  config_path = local.kubeconfig_path_or_null
}

locals {
  kubeconfig_path = "${path.module}/kubeconfig.yaml"

  # fileexists() is evaluated at plan time. When the kubeconfig has not yet
  # been fetched (stage-1 apply) this resolves to null, which causes the
  # helm and kubernetes providers to skip client initialisation gracefully.
  # After stage-1 completes the file exists and stage-2 picks it up.
  kubeconfig_path_or_null = fileexists("${path.module}/kubeconfig.yaml") ? local.kubeconfig_path : null
}

# ---------------------------------------------------------------------------
# Module: k3s
# Bootstraps the server and agent nodes via SSH remote-exec.
# ---------------------------------------------------------------------------
module "k3s" {
  source = "./modules/k3s"

  server_ip                   = var.server_ip
  agent_ip                    = var.agent_ip
  ssh_user                    = var.ssh_user
  server_ssh_private_key_path = var.server_ssh_private_key_path
  agent_ssh_private_key_path  = var.agent_ssh_private_key_path
  k3s_token                   = var.k3s_token
  kubeconfig_local_path       = local.kubeconfig_path
}

# ---------------------------------------------------------------------------
# Module: rancher
# Deploys cert-manager and Rancher via Helm onto the k3s cluster.
# Must run after k3s is up and kubeconfig is available.
#
# IMPORTANT: apply must be split into two stages:
#   Stage 1 — bootstrap k3s and fetch kubeconfig:
#     terraform apply -target=module.k3s
#   Stage 2 — deploy Rancher (kubeconfig now exists on disk):
#     terraform apply
#
# See the Makefile in the repo root for convenience targets.
# ---------------------------------------------------------------------------
module "rancher" {
  source     = "./modules/rancher"
  depends_on = [module.k3s]

  kubeconfig_path            = module.k3s.kubeconfig_path
  rancher_hostname           = var.rancher_hostname
  rancher_chart_version      = var.rancher_chart_version
  cert_manager_chart_version = var.cert_manager_chart_version
}
