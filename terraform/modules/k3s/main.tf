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
# Download k3s binary + install script onto the local machine once.
# Both cluster nodes are LAN-only with no internet access, so files are
# fetched here and copied to the nodes via SCP rather than pulled remotely.
# ---------------------------------------------------------------------------
resource "null_resource" "k3s_download" {
  triggers = {
    k3s_version = var.k3s_version
  }

  provisioner "local-exec" {
    command = <<-EOT
      K3S_VERSION="${var.k3s_version}"
      K3S_VERSION_ENCODED=$(echo "$${K3S_VERSION}" | sed 's/+/%2B/g')
      echo "[k3s-download] Fetching k3s ${var.k3s_version} ..."
      curl -sfL "https://github.com/k3s-io/k3s/releases/download/$${K3S_VERSION_ENCODED}/k3s" \
        -o /tmp/k3s-binary
      chmod +x /tmp/k3s-binary
      curl -sfL https://get.k3s.io -o /tmp/k3s-install.sh
      chmod +x /tmp/k3s-install.sh
      echo "[k3s-download] Done."
    EOT
  }
}

# ---------------------------------------------------------------------------
# Server node — install k3s control-plane
# ---------------------------------------------------------------------------
resource "null_resource" "k3s_server" {
  depends_on = [null_resource.k3s_download]

  triggers = {
    server_ip            = var.server_ip
    k3s_token            = var.k3s_token
    ssh_user             = var.ssh_user
    ssh_private_key_path = var.server_ssh_private_key_path
  }

  connection {
    type        = "ssh"
    host        = self.triggers.server_ip
    user        = self.triggers.ssh_user
    private_key = file(self.triggers.ssh_private_key_path)
    timeout     = "5m"
  }

  # Copy the pre-downloaded k3s binary and install script to the server
  provisioner "file" {
    source      = "/tmp/k3s-binary"
    destination = "/usr/local/bin/k3s"
  }

  provisioner "file" {
    source      = "/tmp/k3s-install.sh"
    destination = "/tmp/k3s-install.sh"
  }

  # Upload the install script
  provisioner "file" {
    source      = "${path.module}/../../../scripts/install-k3s-server.sh"
    destination = "/tmp/install-k3s-server.sh"
  }

  # Execute the install script with required env vars
  provisioner "remote-exec" {
    inline = [
      "chmod +x /usr/local/bin/k3s /tmp/k3s-install.sh /tmp/install-k3s-server.sh",
      "SERVER_IP=${self.triggers.server_ip} K3S_TOKEN=${self.triggers.k3s_token} sudo -E /tmp/install-k3s-server.sh",
    ]
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "sudo /usr/local/bin/k3s-uninstall.sh || echo 'k3s-uninstall.sh not found, may already be removed'",
    ]
    on_failure = continue
  }
}

# ---------------------------------------------------------------------------
# Agent node — install k3s worker and join the cluster
# ---------------------------------------------------------------------------
resource "null_resource" "k3s_agent" {
  depends_on = [null_resource.k3s_server]

  triggers = {
    agent_ip             = var.agent_ip
    server_ip            = var.server_ip
    k3s_token            = var.k3s_token
    ssh_user             = var.ssh_user
    ssh_private_key_path = var.agent_ssh_private_key_path
  }

  connection {
    type        = "ssh"
    host        = self.triggers.agent_ip
    user        = self.triggers.ssh_user
    private_key = file(self.triggers.ssh_private_key_path)
    timeout     = "5m"
  }

  provisioner "file" {
    source      = "/tmp/k3s-binary"
    destination = "/usr/local/bin/k3s"
  }

  provisioner "file" {
    source      = "/tmp/k3s-install.sh"
    destination = "/tmp/k3s-install.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../../../scripts/install-k3s-agent.sh"
    destination = "/tmp/install-k3s-agent.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /usr/local/bin/k3s /tmp/k3s-install.sh /tmp/install-k3s-agent.sh",
      "SERVER_IP=${self.triggers.server_ip} AGENT_IP=${self.triggers.agent_ip} K3S_TOKEN=${self.triggers.k3s_token} sudo -E /tmp/install-k3s-agent.sh",
    ]
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "sudo /usr/local/bin/k3s-agent-uninstall.sh || echo 'k3s-agent-uninstall.sh not found, may already be removed'",
    ]
    on_failure = continue
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
