#!/usr/bin/env bash
set -euo pipefail
exec </dev/null

PACKAGES="tcpdump iproute2 iputils-ping iputils-tracepath net-tools nmap iperf3 mtr-tiny traceroute ethtool bridge-utils socat netcat-openbsd wireshark-common tshark python3-scapy smcroute"

echo "==> [05] Installing network tools on all VMs..."

for vm in source proxy listener1 listener2 listener3; do
  echo "     $vm: apt-get update + install..."
  lxc exec "$vm" -- bash -c "DEBIAN_FRONTEND=noninteractive apt-get update -qq && apt-get install -y $PACKAGES"
done

echo "==> [05] Done."
