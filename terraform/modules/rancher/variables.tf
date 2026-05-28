variable "kubeconfig_path" {
  description = "Path to the kubeconfig file for the k3s cluster."
  type        = string
}

variable "rancher_hostname" {
  description = "Internal hostname for the Rancher UI (e.g. rancher.local). Add to /etc/hosts manually."
  type        = string
  default     = "rancher.local"
}

variable "rancher_chart_version" {
  description = "Rancher Helm chart version to install. Pin this for reproducibility."
  type        = string
  default     = "2.8.4"
}

variable "cert_manager_chart_version" {
  description = "cert-manager Helm chart version to install."
  type        = string
  default     = "v1.14.4"
}
