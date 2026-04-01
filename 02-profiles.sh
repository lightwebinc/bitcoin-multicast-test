#!/usr/bin/env bash
set -euo pipefail
exec </dev/null

echo "==> [02] Creating LXD profile: ubuntu-small-mcast (2 NICs)..."
if lxc profile show ubuntu-small-mcast &>/dev/null; then
  echo "     ubuntu-small-mcast already exists, skipping"
else
  lxc profile create ubuntu-small-mcast
  lxc profile set ubuntu-small-mcast limits.cpu=2
  lxc profile set ubuntu-small-mcast limits.memory=2GiB

  lxc profile device add ubuntu-small-mcast eth0 nic network=lxdbr0 name=eth0
  lxc profile device add ubuntu-small-mcast eth1 nic network=lxdbr1 name=eth1
  lxc profile device add ubuntu-small-mcast root disk path=/ pool=vmpool size=15GiB
fi

echo "==> [02] Creating LXD profile: ubuntu-small-single (1 NIC)..."
if lxc profile show ubuntu-small-single &>/dev/null; then
  echo "     ubuntu-small-single already exists, skipping"
else
  lxc profile create ubuntu-small-single
  lxc profile set ubuntu-small-single limits.cpu=2
  lxc profile set ubuntu-small-single limits.memory=2GiB

  lxc profile device add ubuntu-small-single eth0 nic network=lxdbr0 name=eth0
  lxc profile device add ubuntu-small-single root disk path=/ pool=vmpool size=15GiB
fi

echo "==> [02] Done."
