output "server_ip" {
  description = "Private IP of the k3s server node."
  value       = var.server_ip
}

output "kubeconfig_path" {
  description = "Local path to the fetched kubeconfig file."
  value       = var.kubeconfig_local_path
}
