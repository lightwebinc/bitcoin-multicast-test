#!/usr/bin/env bash
set -euo pipefail
exec </dev/null

GROUP="${1:-ff05::}"
PORT="${2:-9999}"

echo "==> test-send.sh"
echo "    Multicast group : $GROUP"
echo "    Port            : $PORT"
echo ""
echo "    To capture on receivers, run in separate terminals:"
echo "      lxc exec recv1 -- tcpdump -i enp6s0 -n 'ip6 and udp'"
echo "      lxc exec recv2 -- tcpdump -i enp6s0 -n 'ip6 and udp'"
echo "      lxc exec recv3 -- tcpdump -i enp6s0 -n 'ip6 and udp'"
echo ""

echo "--- Sending multicast UDP from proxy to [$GROUP]:$PORT on enp6s0 ---"
lxc exec proxy -- bash -c "
  echo 'hello-multicast-from-proxy' | socat - UDP6-DATAGRAM:[${GROUP}]:${PORT},interface=enp6s0,ip-multicast-ttl=5
"

echo ""
echo "--- Sending unicast UDP from source to proxy ingress (IPv4 10.10.10.20:9000) ---"
lxc exec source -- bash -c "
  echo 'hello-from-source-ipv4' | socat - UDP:10.10.10.20:9000
"

echo ""
echo "--- Sending BRC-12 test frames from source to proxy ingress (IPv6 [fd20::2]:9000) ---"
lxc exec source -- send-test-frames -addr '[fd20::2]:9000' -shard-bits 2 -spread

echo ""
echo "==> Done."
