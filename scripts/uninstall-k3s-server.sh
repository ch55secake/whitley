#!/usr/bin/env bash
# uninstall-k3s-server.sh
# Uninstalls k3s from the server (control-plane) node.
# Called by Terraform via remote-exec destroy provisioner.
set -euo pipefail

echo "[k3s-server] Uninstalling k3s server ..."

if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
  /usr/local/bin/k3s-uninstall.sh
else
  echo "[k3s-server] k3s-uninstall.sh not found — k3s may already be removed."
fi

echo "[k3s-server] Uninstall complete."
