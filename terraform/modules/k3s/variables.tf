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

variable "server_ssh_private_key_path" {
  description = "Absolute path to the SSH private key file used to connect to the server (control-plane) node."
  type        = string
}

variable "agent_ssh_private_key_path" {
  description = "Absolute path to the SSH private key file used to connect to the agent (worker) node."
  type        = string
}

variable "k3s_token" {
  description = "Shared secret used for agent nodes to join the cluster."
  type        = string
  sensitive   = true
}

variable "kubeconfig_local_path" {
  description = "Local path where the kubeconfig will be written after cluster is up."
  type        = string
  default     = "${path.root}/kubeconfig.yaml"
}
