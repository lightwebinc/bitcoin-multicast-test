# bitcoin-multicast-test

LXD-based IPv6 multicast test lab. Five Ubuntu 24.04 VMs forming a source → ingress-proxy → IPv6 multicast → receivers pipeline.

```
 source ──► proxy (ingress) ──► ff05::%enp6s0 ──► recv1/2/3
```

## Documentation

- [docs/network.md](docs/network.md) — bridge layout, VM IP assignments, multicast group configuration, bridge MDB notes
- [docs/bitcoin-shard-proxy.md](docs/bitcoin-shard-proxy.md) — proxy deployment, Ansible inventory, verification steps

## Quickstart

```bash
git clone https://github.com/lightwebinc/bitcoin-multicast-test.git
cd bitcoin-multicast-test
chmod +x *.sh
bash deploy.sh
```

`deploy.sh` runs scripts `01`–`07` in order, then restarts `mcast-join.service` on all receivers to ensure the bridge MDB is populated.

## Scripts

| Script             | Purpose                                                              |
|--------------------|----------------------------------------------------------------------|
| `deploy.sh`        | Master — runs 01–07 in order, then refreshes bridge MDB             |
| `01-network.sh`    | Create lxdbr0/lxdbr1, enable multicast snooping                     |
| `02-profiles.sh`   | Create LXD profiles (`ubuntu-small-mcast`, `ubuntu-small-single`)   |
| `03-launch.sh`     | Launch all 5 VMs, wait for RUNNING                                  |
| `04-sudo.sh`       | Passwordless sudo for `ubuntu` user                                 |
| `05-packages.sh`   | Install tcpdump, iperf3, socat, tshark, scapy, smcroute             |
| `06-netplan.sh`    | Push static IP netplan configs and apply                            |
| `07-mcast-join.sh` | Install and start `mcast-join.service` on receivers                 |
| `08-verify.sh`     | Check bridge MDB, snooping state, MLD membership, IPv6 addrs        |
| `test-send.sh`     | Send multicast from proxy and BRC-12 frames from source             |

## Verification

```bash
bash 08-verify.sh
bash test-send.sh
```

## Notes

- All scripts use `exec </dev/null` to avoid stdin blocking when run non-interactively.
- `lxc profile set` / `device add` is used instead of `lxc profile edit` (heredoc hangs in non-interactive shells).
- Multicast snooping is configured via sysfs — `ip link set` does not persist in this setup.
- `ip maddr add` does not work for IPv6 group joins; only the Python `IPV6_JOIN_GROUP` socket approach works.
