#!/usr/bin/env bash
# Deploy both bitcoin-ingress (proxy) and bitcoin-listener (listener1..3)
# using inventories committed to this repo. Idempotent.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INGRESS_DIR=${BITCOIN_INGRESS_DIR:-$HOME/repo/bitcoin-ingress/ansible}
LISTENER_DIR=${BITCOIN_LISTENER_DIR:-$HOME/repo/bitcoin-listener/ansible}

for d in "$INGRESS_DIR" "$LISTENER_DIR"; do
  if [[ ! -f "$d/site.yml" ]]; then
    echo "ERROR: expected playbook at $d/site.yml" >&2
    echo "       override with BITCOIN_INGRESS_DIR / BITCOIN_LISTENER_DIR" >&2
    exit 1
  fi
done

echo "==> Deploying bitcoin-shard-proxy to proxy VM"
(cd "$INGRESS_DIR" && ansible-playbook -i "$SCRIPT_DIR/ingress-hosts.yml" site.yml "$@")

echo "==> Deploying bitcoin-shard-listener to listener1..3"
(cd "$LISTENER_DIR" && ansible-playbook -i "$SCRIPT_DIR/listener-hosts.yml" site.yml "$@")

echo "==> Deploy complete."
