#!/usr/bin/env bash
# install-k3s-agent.sh
# Installs k3s as an agent (worker) node and joins the server.
# Called by Terraform via remote-exec provisioner.
#
# Required env vars:
#   SERVER_IP   — private LAN IP of the k3s server node
#   AGENT_IP    — private LAN IP of this agent node
#   K3S_TOKEN   — shared secret matching the server installation
#
set -euo pipefail

: "${SERVER_IP:?SERVER_IP must be set}"
: "${AGENT_IP:?AGENT_IP must be set}"
: "${K3S_TOKEN:?K3S_TOKEN must be set}"

echo "[k3s-agent] Joining cluster at https://${SERVER_IP}:6443 ..."

export K3S_URL="https://${SERVER_IP}:6443"
export K3S_TOKEN="${K3S_TOKEN}"

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="\
  agent \
  --node-ip ${AGENT_IP}" sh -

echo "[k3s-agent] Agent installation complete."
