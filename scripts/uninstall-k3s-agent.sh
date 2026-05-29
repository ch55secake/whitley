#!/usr/bin/env bash
# uninstall-k3s-agent.sh
# Uninstalls k3s from the agent (worker) node.
# Called by Terraform via remote-exec destroy provisioner.
set -euo pipefail

echo "[k3s-agent] Uninstalling k3s agent ..."

if [ -f /usr/local/bin/k3s-agent-uninstall.sh ]; then
  /usr/local/bin/k3s-agent-uninstall.sh
else
  echo "[k3s-agent] k3s-agent-uninstall.sh not found — k3s may already be removed."
fi

echo "[k3s-agent] Uninstall complete."
