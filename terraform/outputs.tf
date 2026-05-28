output "rancher_hostname" {
  description = "Internal Rancher hostname. Add '${module.k3s.server_ip} ${module.rancher.rancher_hostname}' to /etc/hosts."
  value       = module.rancher.rancher_hostname
}

output "server_ip" {
  description = "k3s server (control-plane) private IP."
  value       = module.k3s.server_ip
}

output "kubeconfig_path" {
  description = "Local path to the fetched kubeconfig."
  value       = module.k3s.kubeconfig_path
}

output "ca_cert_pem" {
  description = "Private CA certificate PEM. Import into your OS/browser trust store to avoid TLS warnings."
  value       = module.rancher.ca_cert_pem
  sensitive   = true
}
