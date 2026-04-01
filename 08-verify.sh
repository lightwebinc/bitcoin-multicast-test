#!/usr/bin/env bash
set -euo pipefail
exec </dev/null

echo "==> [08] Verification checks..."

echo ""
echo "--- Bridge multicast DB (lax host) ---"
bridge mdb show dev lxdbr1

echo ""
echo "--- Bridge link / MLD snooping state ---"
cat /sys/devices/virtual/net/lxdbr1/bridge/multicast_snooping && echo "  (multicast_snooping=1 means ON)"

echo ""
echo "--- MLD group membership per receiver ---"
for vm in recv1 recv2 recv3; do
  echo ""
  echo "  [$vm] ip maddr show dev enp6s0:"
  lxc exec "$vm" -- ip maddr show dev enp6s0
  echo "  [$vm] ip -6 addr show enp6s0:"
  lxc exec "$vm" -- ip -6 addr show enp6s0
done

echo ""
echo "--- IPv6 addr on proxy enp6s0 ---"
lxc exec proxy -- ip -6 addr show enp6s0

echo ""
echo "==> [08] Done."
