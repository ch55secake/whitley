#!/usr/bin/env bash
# install-k3s-server.sh
# Installs k3s as a server (control-plane) node.
# Called by Terraform via remote-exec provisioner.
# All arguments are passed via environment variables set by Terraform.
#
# Required env vars:
#   SERVER_IP   — private LAN IP of this node (bind + advertise)
#   K3S_TOKEN   — shared secret for agent nodes to join the cluster
#
set -euo pipefail

: "${SERVER_IP:?SERVER_IP must be set}"
: "${K3S_TOKEN:?K3S_TOKEN must be set}"

echo "[k3s-server] Installing k3s server on ${SERVER_IP} ..."

export K3S_TOKEN="${K3S_TOKEN}"

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="\
  server \
  --bind-address ${SERVER_IP} \
  --advertise-address ${SERVER_IP} \
  --node-ip ${SERVER_IP} \
  --tls-san ${SERVER_IP} \
  --disable traefik \
  --disable servicelb \
  --cluster-cidr 10.42.0.0/16 \
  --service-cidr 10.43.0.0/16 \
  --write-kubeconfig-mode 0644" sh -

echo "[k3s-server] Waiting for k3s to become ready ..."
timeout 120 bash -c 'until /usr/local/bin/k3s kubectl get nodes &>/dev/null; do sleep 3; done'

echo "[k3s-server] Installation complete."
echo "[k3s-server] Node token is at: /var/lib/rancher/k3s/server/node-token"
