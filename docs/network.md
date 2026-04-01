# Network topology

## Bridges

| Bridge   | Subnet            | Purpose                                        |
|----------|-------------------|------------------------------------------------|
| lxdbr0   | 10.10.10.0/24     | Management — SSH, LXD agent, package installs  |
| lxdbr1   | fd20::/64 (IPv6)  | Egress fabric — multicast traffic only         |

Multicast snooping is enabled on `lxdbr1` via sysfs:

```
/sys/devices/virtual/net/lxdbr1/bridge/multicast_snooping = 1
/sys/devices/virtual/net/lxdbr1/bridge/multicast_querier   = 1
```

**Both settings are required.** Snooping alone is insufficient — without a querier the bridge never sends MLD queries, so receiver ports appear silent and the bridge floods all multicast to all ports. The querier is persisted by `lxd-bridge-mcast-querier.service` (installed on the LXD host by the deployment scripts).

## VM assignments

All VMs use Ubuntu 24.04 predictable interface names: `enp5s0` (mgmt, lxdbr0) and `enp6s0` (egress, lxdbr1).

| VM     | enp5s0 (mgmt) | enp6s0 (egress) | LXD profile          | Role           |
|--------|---------------|-----------------|----------------------|----------------|
| source | 10.10.10.10   | fd20::10/64     | ubuntu-small-mcast   | Traffic source |
| proxy  | 10.10.10.20   | fd20::2/64      | ubuntu-small-mcast   | Ingress proxy  |
| recv1  | 10.10.10.21   | fd20::11/64     | ubuntu-small-mcast   | Receiver       |
| recv2  | 10.10.10.22   | fd20::12/64     | ubuntu-small-mcast   | Receiver       |
| recv3  | 10.10.10.23   | fd20::13/64     | ubuntu-small-mcast   | Receiver       |

Default gateway for all VMs: `10.10.10.1` (lxdbr0 host address).

## LXD profiles

| Profile              | NICs              | Notes                              |
|----------------------|-------------------|------------------------------------|
| ubuntu-small-mcast   | eth0 + eth1       | 2 vCPU, 2 GiB RAM, 15 GiB disk    |
| ubuntu-small-single  | eth0 only         | Same resources; kept for reference |

`eth0` attaches to `lxdbr0`; `eth1` attaches to `lxdbr1`. Inside Ubuntu 24.04 VMs these appear as `enp5s0` and `enp6s0` respectively.

## Topology diagram

```
          [mgmt bridge: lxdbr0 — 10.10.10.0/24 (host .1)]
               |        |        |        |        |
            source   proxy    recv1    recv2    recv3
               |       |        |        |        |
          [egress bridge: lxdbr1 — fd20::/64, IPv6 only, multicast snooping on]

 source ──► proxy (ingress) ──► ff05::%enp6s0 ──► recv1/2/3
```

## Multicast groups

Scope: site-local (`ff05::/16`), joined on `enp6s0` inside each receiver VM.

| VM    | Groups joined                              |
|-------|--------------------------------------------|
| recv1 | `ff05::`, `ff05::1`, `ff05::2`, `ff05::3` |
| recv2 | `ff05::2`                                  |
| recv3 | `ff05::1`, `ff05::3`                       |

MLD group membership is maintained by `mcast-join.service` (systemd) running `/usr/local/bin/mcast-join.py` — a persistent Python3 script that calls `IPV6_JOIN_GROUP` and sleeps to hold the socket open.

### Bridge MDB volatility

The bridge multicast database (MDB) is populated by MLD membership reports and is **not persisted** across service restarts. After any reboot or `mcast-join.service` restart, re-trigger membership reports:

```bash
for vm in recv1 recv2 recv3; do lxc exec "$vm" -- systemctl restart mcast-join.service; done
bridge mdb show dev lxdbr1
```

The `multicast_querier` sysfs setting is also cleared on reboot. `lxd-bridge-mcast-querier.service` restores it automatically when `lxdbr1` comes up. Verify with:

```bash
cat /sys/devices/virtual/net/lxdbr1/bridge/multicast_querier  # expect: 1
systemctl is-active lxd-bridge-mcast-querier.service           # expect: active
```

## Netplan configs

Per-VM static IP configs live in `06-netplan/<vm>.yaml` and are pushed to `/etc/netplan/99-lab.yaml` by `06-netplan.sh`. The `source` VM has both `enp5s0` (IPv4 mgmt) and `enp6s0` (IPv6 egress) configured so it can send frames directly to the proxy over the egress fabric.
