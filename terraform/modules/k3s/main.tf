# modules/k3s/main.tf
# Bootstraps k3s on the server and agent nodes via SSH remote-exec.
# Fetches the kubeconfig from the server and rewrites the server address
# so downstream Terraform providers can connect.

terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# ---------------------------------------------------------------------------
# Server node — install k3s control-plane
# ---------------------------------------------------------------------------
resource "null_resource" "k3s_server" {
  triggers = {
    server_ip = var.server_ip
    k3s_token = var.k3s_token
  }

  connection {
    type        = "ssh"
    host        = var.server_ip
    user        = var.ssh_user
    private_key = file(var.server_ssh_private_key_path)
    timeout     = "5m"
  }

  # Upload the install script
  provisioner "file" {
    source      = "${path.module}/../../../scripts/install-k3s-server.sh"
    destination = "/tmp/install-k3s-server.sh"
  }

  # Execute the install script with required env vars
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install-k3s-server.sh",
      "SERVER_IP=${var.server_ip} K3S_TOKEN=${var.k3s_token} sudo -E /tmp/install-k3s-server.sh",
    ]
  }
}

# ---------------------------------------------------------------------------
# Agent node — install k3s worker and join the cluster
# ---------------------------------------------------------------------------
resource "null_resource" "k3s_agent" {
  depends_on = [null_resource.k3s_server]

  triggers = {
    agent_ip  = var.agent_ip
    server_ip = var.server_ip
    k3s_token = var.k3s_token
  }

  connection {
    type        = "ssh"
    host        = var.agent_ip
    user        = var.ssh_user
    private_key = file(var.agent_ssh_private_key_path)
    timeout     = "5m"
  }

  provisioner "file" {
    source      = "${path.module}/../../../scripts/install-k3s-agent.sh"
    destination = "/tmp/install-k3s-agent.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install-k3s-agent.sh",
      "SERVER_IP=${var.server_ip} AGENT_IP=${var.agent_ip} K3S_TOKEN=${var.k3s_token} sudo -E /tmp/install-k3s-agent.sh",
    ]
  }
}

# ---------------------------------------------------------------------------
# Fetch kubeconfig from server and rewrite the server address
# Runs on the local Terraform host (local-exec) after server is up.
# ---------------------------------------------------------------------------
resource "null_resource" "fetch_kubeconfig" {
  depends_on = [null_resource.k3s_server]

  triggers = {
    server_ip = var.server_ip
  }

  provisioner "local-exec" {
    command = <<-EOT
      scp \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -i ${var.server_ssh_private_key_path} \
        ${var.ssh_user}@${var.server_ip}:/etc/rancher/k3s/k3s.yaml \
        ${var.kubeconfig_local_path}

      # Rewrite the loopback address to the actual server IP so remote
      # providers can reach the API server.
      sed -i 's|https://127.0.0.1:6443|https://${var.server_ip}:6443|g' \
        ${var.kubeconfig_local_path}

      chmod 600 ${var.kubeconfig_local_path}
    EOT
  }
}
