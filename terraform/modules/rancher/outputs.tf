output "rancher_hostname" {
  description = "Internal hostname configured for the Rancher UI."
  value       = var.rancher_hostname
}

output "ca_cert_pem" {
  description = "PEM-encoded private CA certificate. Trust this in your browser/OS to avoid TLS warnings."
  value       = tls_self_signed_cert.ca.cert_pem
  sensitive   = true
}
