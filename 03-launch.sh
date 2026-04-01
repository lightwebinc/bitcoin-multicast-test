#!/usr/bin/env bash
set -euo pipefail
exec </dev/null

wait_for_vm() {
  local vm="$1"
  echo "     Waiting for $vm to reach RUNNING state..."
  for i in $(seq 1 60); do
    state=$(lxc list "$vm" --format csv -c s 2>/dev/null | head -1)
    if [[ "$state" == "RUNNING" ]]; then
      echo "     $vm is RUNNING"
      return 0
    fi
    sleep 3
  done
  echo "ERROR: $vm did not reach RUNNING state in time" >&2
  return 1
}

echo "==> [03] Launching VM: source (ubuntu-small-mcast)..."
if lxc info source &>/dev/null; then
  echo "     source already exists, skipping"
else
  lxc launch ubuntu:24.04 source --vm --profile ubuntu-small-mcast
fi

echo "==> [03] Launching VM: proxy (ubuntu-small-mcast)..."
if lxc info proxy &>/dev/null; then
  echo "     proxy already exists, skipping"
else
  lxc launch ubuntu:24.04 proxy --vm --profile ubuntu-small-mcast
fi

echo "==> [03] Launching VM: recv1 (ubuntu-small-mcast)..."
if lxc info recv1 &>/dev/null; then
  echo "     recv1 already exists, skipping"
else
  lxc launch ubuntu:24.04 recv1 --vm --profile ubuntu-small-mcast
fi

echo "==> [03] Launching VM: recv2 (ubuntu-small-mcast)..."
if lxc info recv2 &>/dev/null; then
  echo "     recv2 already exists, skipping"
else
  lxc launch ubuntu:24.04 recv2 --vm --profile ubuntu-small-mcast
fi

echo "==> [03] Launching VM: recv3 (ubuntu-small-mcast)..."
if lxc info recv3 &>/dev/null; then
  echo "     recv3 already exists, skipping"
else
  lxc launch ubuntu:24.04 recv3 --vm --profile ubuntu-small-mcast
fi

echo "==> [03] Waiting for all VMs to be RUNNING..."
for vm in source proxy recv1 recv2 recv3; do
  wait_for_vm "$vm"
done

echo "==> [03] All VMs running:"
lxc list

echo "==> [03] Done."
