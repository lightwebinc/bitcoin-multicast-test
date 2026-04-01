# bitcoin-multicast-test

LXD-based IPv6 multicast test lab on an Ubuntu host. Five Ubuntu 24.04 VMs testing traffic-source → ingress-proxy → IPv6 multicast → receivers.

## Topology

```
          [mgmt bridge: lxdbr0 — 10.10.10.0/24 (host .1)]
               |        |        |        |        |
            source   proxy    recv1    recv2    recv3
               |       |        |        |        |
          [egress bridge: lxdbr1 — fd20::/64, IPv6 only, multicast snooping on]

 source ──► proxy (ingress) ──► ff05::%enp6s0 ──► recv1/2/3
```

## VM Assignments

All VMs use predictable Ubuntu 24.04 interface names: `enp5s0` (mgmt, lxdbr0) and `enp6s0` (egress, lxdbr1).

| VM     | enp5s0 (mgmt) | enp6s0 (egress) | Role           |
|--------|---------------|-----------------|----------------|
| source | 10.10.10.10   | fd20::10/64     | Traffic source |
| proxy  | 10.10.10.20   | fd20::2/64      | Ingress proxy  |
| recv1  | 10.10.10.21   | fd20::11/64     | Receiver       |
| recv2  | 10.10.10.22   | fd20::12/64     | Receiver       |
| recv3  | 10.10.10.23   | fd20::13/64     | Receiver       |

## Multicast Groups (enp6s0, ff05:: site-local)

| VM    | Groups                                     |
|-------|--------------------------------------------|
| recv1 | `ff05::`, `ff05::1`, `ff05::2`, `ff05::3` |
| recv2 | `ff05::2`                                  |
| recv3 | `ff05::1`, `ff05::3`                       |

MLD joins are maintained by a persistent `mcast-join.service` (systemd) running a Python3 socket script (`/usr/local/bin/mcast-join.py`) inside each receiver VM.

## Quickstart

```bash
# Clone and run on the Ubuntu host where LXD is running
git clone https://github.com/lightwebinc/bitcoin-multicast-test.git
cd bitcoin-multicast-test
chmod +x *.sh
bash deploy.sh
```

## Scripts

| Script             | Purpose                                                        |
|--------------------|----------------------------------------------------------------|
| `deploy.sh`        | Master — runs 01–07 in order, then refreshes bridge MDB        |
| `01-network.sh`    | Configure lxdbr0 DHCP range; create lxdbr1 (IPv6-only, fd20::1/64); enable multicast snooping via sysfs |
| `02-profiles.sh`   | Create `ubuntu-small-mcast` (2 NICs) + `ubuntu-small-single` (1 NIC) profiles |
| `03-launch.sh`     | Launch all 5 VMs with `ubuntu:24.04`, wait for RUNNING state   |
| `04-sudo.sh`       | Passwordless sudo for `ubuntu` user on all VMs                 |
| `05-packages.sh`   | Install tcpdump, iperf3, socat, tshark, scapy, smcroute, etc. |
| `06-netplan.sh`    | Push `06-netplan/<vm>.yaml` → `/etc/netplan/99-lab.yaml` and apply static IPs |
| `07-mcast-join.sh` | Push `systemd/<vm>-mcast-join.py` + `.service` into receivers; enable + start |
| `08-verify.sh`     | Check bridge MDB, multicast snooping, MLD membership, IPv6 addrs |
| `test-send.sh`     | Send test multicast from proxy; unicast from source            |

## Supporting Files

| Path                              | Purpose                                      |
|-----------------------------------|----------------------------------------------|
| `06-netplan/<vm>.yaml`            | Per-VM netplan static IP config              |
| `systemd/<vm>-mcast-join.service` | systemd unit that starts the MLD join script |
| `systemd/<vm>-mcast-join.py`      | Python3 script — joins multicast groups via `IPV6_JOIN_GROUP` socket option and sleeps to maintain membership |

## bitcoin-shard-proxy Integration

The `proxy` VM runs `bitcoin-shard-proxy` (from `bitcoin-ingress` + `bitcoin-shard-proxy` repos),
deployed via Ansible from the `bitcoin-ingress` playbook.

### Deployed state

| Item | Value |
|------|-------|
| Binary | `/usr/local/bin/bitcoin-shard-proxy` |
| Config | `/etc/bitcoin-shard-proxy/config.env` |
| Service | `bitcoin-shard-proxy.service` (systemd, enabled) |
| Listen | `[::]:9000` UDP (BRC-12 frames in) |
| Egress | `enp6s0` → `ff05::/16` (site-local multicast) |
| Shard bits | 8 (256 groups) |
| Metrics | `http://10.10.10.20:9100/metrics`, `/healthz`, `/readyz` |

### Ansible inventory (`bitcoin-ingress/ansible/inventory/hosts.yml`)

```yaml
all:
  children:
    ingress_nodes:
      vars:
        ansible_user: ubuntu
        ansible_connection: ssh
        ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
        egress_mode: ethernet
        shard_bits: 2
        mc_scope: site
        enable_bgp: false
      hosts:
        proxy:
          ansible_host: 10.10.10.20
          egress_iface: enp6s0
```

### Re-deploy / upgrade

```bash
cd /path/to/bitcoin-ingress/ansible
ansible-playbook -i inventory/hosts.yml site.yml --tags proxy
# Or to pin a version:
ansible-playbook -i inventory/hosts.yml site.yml --tags proxy -e proxy_version=v1.2.0
```

### After any proxy reboot or re-deploy

Restart `mcast-join.service` on receivers to repopulate the bridge MDB (multicast snooping state
is lost on service restart):

```bash
for vm in recv1 recv2 recv3; do lxc exec $vm -- systemctl restart mcast-join.service; done
bridge mdb show dev lxdbr1
```

### Known integration notes

- Ubuntu 24.04 LXD VMs use predictable NIC names (`enp5s0`, `enp6s0`), not `eth0`/`eth1`.
- `egress_iface` must be a **host-level** inventory var, not a group `vars:` entry — `group_vars/all.yml` takes higher precedence than inventory group vars in Ansible.
- The `acl` package must be installed on the target VM for Ansible `become` to work with system users.
- The `ExecStartPre` `ip route add` command in the systemd unit requires `/bin/sh -c '...'` wrapping — systemd does not expand shell syntax in `ExecStartPre` directly.
- `send-test-frames` uses IPv6 sockets; send from the `source` VM via `fd20::10` on `enp6s0`, or from the proxy itself using `[::1]:9000`.
- Bridge MDB is volatile — MLD membership reports are not re-sent automatically after a bridge restart. Restart `mcast-join.service` on all receivers to re-populate.

## Notes

- All scripts use `exec </dev/null` to prevent stdin blocking when run non-interactively.
- `lxc profile set` / `device add` is used instead of `lxc profile edit` (heredoc hangs in non-interactive shells).
- Multicast snooping is set via `/sys/devices/virtual/net/lxdbr1/bridge/multicast_snooping` (not `bridge link set`).
- `ip maddr add` does not work for IPv6 group joins — only the Python `IPV6_JOIN_GROUP` socket approach works.

## Verification

```bash
# Run verification checks on the host
bash 08-verify.sh

# Capture multicast on a receiver
lxc exec recv1 -- tcpdump -i enp6s0 -n 'ip6 and udp'

# Check MLD service status on a receiver
lxc exec recv1 -- systemctl status mcast-join.service

# Send test traffic (optional group and port args)
bash test-send.sh ff05:: 9999
bash test-send.sh ff05::1 9999
```

### bitcoin-shard-proxy verification

```bash
# Service status
lxc exec proxy -- systemctl status bitcoin-shard-proxy

# Health and readiness
lxc exec proxy -- curl -s http://localhost:9100/healthz
lxc exec proxy -- curl -s http://localhost:9100/readyz

# Send BRC-12 test frames from source VM via IPv6 to proxy ingress
lxc exec source -- /tmp/send-test-frames -addr '[fd20::2]:9000' -shard-bits 2 -spread
# Or from the proxy itself via loopback
lxc exec proxy -- /tmp/send-test-frames -addr '[::1]:9000' -shard-bits 2 -spread

# Confirm forwarded packet counter incremented
lxc exec proxy -- curl -s http://localhost:9100/metrics | grep bsp_packets_forwarded_total

# Capture multicast delivery on recv1 (write to pcap, then read)
lxc exec recv1 -- tcpdump -i enp6s0 -n 'ip6 and udp' -c 8 -w /tmp/cap.pcap &
lxc exec source -- /tmp/send-test-frames -addr '[fd20::2]:9000' -shard-bits 2 -spread
sleep 3 && lxc exec recv1 -- tcpdump -r /tmp/cap.pcap -n
```
