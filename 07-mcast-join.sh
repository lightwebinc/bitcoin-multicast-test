#!/usr/bin/env bash
set -euo pipefail
exec </dev/null

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEMD_DIR="$SCRIPT_DIR/systemd"

echo "==> [07] Installing MLD multicast join services on receivers..."

for vm in recv1 recv2 recv3; do
  echo "     $vm: pushing mcast-join.py to /usr/local/bin/..."
  lxc file push "$SYSTEMD_DIR/$vm-mcast-join.py" \
    "$vm/usr/local/bin/mcast-join.py"
  lxc exec "$vm" -- chmod 755 /usr/local/bin/mcast-join.py
  echo "     $vm: pushing mcast-join.service..."
  lxc file push "$SYSTEMD_DIR/$vm-mcast-join.service" \
    "$vm/etc/systemd/system/mcast-join.service"
  echo "     $vm: enabling and starting mcast-join.service..."
  lxc exec "$vm" -- systemctl daemon-reload
  lxc exec "$vm" -- systemctl enable mcast-join.service
  lxc exec "$vm" -- systemctl restart mcast-join.service
  sleep 2
  echo "     $vm: verifying groups..."
  lxc exec "$vm" -- ip maddr show dev enp6s0
done

echo "==> [07] Done."
