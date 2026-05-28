variable "server_ip" {
  description = "Private LAN IP of the k3s server/control-plane node."
  type        = string
}

variable "agent_ip" {
  description = "Private LAN IP of the k3s agent/worker node."
  type        = string
}

variable "ssh_user" {
  description = "SSH username for both nodes."
  type        = string
}

variable "ssh_private_key_path" {
  description = "Absolute path to the SSH private key file on the Terraform host."
  type        = string
}

variable "k3s_token" {
  description = "Shared secret used by agent nodes to join the cluster. Use a long random string."
  type        = string
  sensitive   = true
}

variable "rancher_hostname" {
  description = "Internal hostname for the Rancher UI. Add this to /etc/hosts pointing at server_ip."
  type        = string
  default     = "rancher.local"
}

variable "rancher_chart_version" {
  description = "Rancher Helm chart version."
  type        = string
  default     = "2.8.4"
}

variable "cert_manager_chart_version" {
  description = "cert-manager Helm chart version."
  type        = string
  default     = "v1.14.4"
}
