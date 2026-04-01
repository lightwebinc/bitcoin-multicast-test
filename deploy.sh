#!/usr/bin/env bash
set -euo pipefail
exec </dev/null

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================================="
echo " bitcoin-multicast-test — full deployment"
echo "================================================="
echo ""

bash "$SCRIPT_DIR/01-network.sh"
echo ""

bash "$SCRIPT_DIR/02-profiles.sh"
echo ""

bash "$SCRIPT_DIR/03-launch.sh"
echo ""

bash "$SCRIPT_DIR/04-sudo.sh"
echo ""

bash "$SCRIPT_DIR/05-packages.sh"
echo ""

bash "$SCRIPT_DIR/06-netplan.sh"
echo ""

bash "$SCRIPT_DIR/07-mcast-join.sh"
echo ""

echo "==> Enabling bridge MLD querier (required for snooping to suppress flooding)..."
if [ ! -f /etc/systemd/system/lxd-bridge-mcast-querier.service ]; then
  cat << 'EOF' | sudo tee /etc/systemd/system/lxd-bridge-mcast-querier.service > /dev/null
[Unit]
Description=Enable MLD querier on lxdbr1 for multicast snooping
After=sys-devices-virtual-net-lxdbr1.device
BindsTo=sys-devices-virtual-net-lxdbr1.device

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c 'echo 1 > /sys/devices/virtual/net/lxdbr1/bridge/multicast_querier'

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl daemon-reload
fi
sudo systemctl enable --now lxd-bridge-mcast-querier.service
echo ""

echo "==> Refreshing bridge MDB — restarting mcast-join on receivers..."
for vm in recv1 recv2 recv3; do
  lxc exec "$vm" -- systemctl restart mcast-join.service
done
sleep 3
echo ""

echo "================================================="
echo " Deployment complete. Run verification:"
echo "   bash $SCRIPT_DIR/08-verify.sh"
echo ""
echo " To send test traffic:"
echo "   bash $SCRIPT_DIR/test-send.sh [group] [port]"
echo "   Default: ff05:: port 9999"
echo "================================================="
