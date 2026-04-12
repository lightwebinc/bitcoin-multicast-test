# Tests — feat/v2-frame-sequencing

Results for the `feat/v2-frame-sequencing` branch of `bitcoin-shard-proxy`, deployed via the matching branch of `bitcoin-ingress`.

Baseline comparison: [`../main/summary.md`](../main/summary.md)

---

## What's new in this deployment

| Area | Change |
|------|--------|
| `UDP_LISTEN_PORT` | Replaces `LISTEN_PORT` — **breaking env-var rename** |
| `TCP_LISTEN_PORT` | New; `0` = disabled (default) |
| `-proxy-seq` | Removed flag (was no-op in config anyway) |
| `-static-subtree-id/height` | Removed flags (were no-op in config anyway) |
| v1 BRC-12 frames | Now accepted and forwarded verbatim (was rejected) |
| v2 byte 7 | `SubtreeHeight` field removed; byte is `Reserved 0x00` |
| Forward path | Zero-copy verbatim — unchanged from `main` |

---

## 1. Deploy

From the `feat/v2-frame-sequencing` branch of `bitcoin-ingress`:

```bash
cd /path/to/bitcoin-ingress/ansible
ansible-playbook -i inventory/hosts.yml site.yml
```

`proxy_version` is already set to `feat/v2-frame-sequencing` in `group_vars/all.yml` on this branch. No extra flags needed.

After deployment, restart `mcast-join.service` on receivers:

```bash
for vm in recv1 recv2 recv3; do lxc exec "$vm" -- systemctl restart mcast-join.service; done
```

---

## 2. Smoke test

**Health check**

```bash
lxc exec proxy -- systemctl status bitcoin-shard-proxy
lxc exec proxy -- curl -s http://localhost:9100/healthz
lxc exec proxy -- curl -s http://localhost:9100/readyz
```

Expected: service `active (running)`, health endpoints return `ok`.

**UDP v2 frame forwarding**

```bash
lxc exec source -- send-test-frames -addr '[fd20::2]:9000' -shard-bits 2 -spread
lxc exec proxy -- curl -s http://localhost:9100/metrics | grep bsp_packets_forwarded_total
```

Expected: `bsp_packets_forwarded_total` ≥ 4 (one per shard group), drop rate 0%.

**Multicast delivery to receivers**

```bash
# In a separate terminal, start a capture on recv1 before sending
lxc exec recv1 -- tcpdump -i enp6s0 -n 'ip6 and udp' -c 8
```

Expected: UDP multicast datagrams arrive on `enp6s0`.

Save results → [`smoke-test.md`](smoke-test.md)

---

## 3. Perf regression

Same commands as the `main` baseline. Run from the LXD host with `perf-test` built from this branch.

**10 k pps (30 s)**

```bash
perf-test \
  -proxy-addr '[fd20::2]:9000' \
  -metrics-url http://10.10.10.20:9100 \
  -shard-bits 2 \
  -pps 10000 \
  -duration 30s \
  -payload-min 256 -payload-max 512 \
  -lxd -receivers recv1,recv2,recv3 \
  -output testing/feat-v2-frame-sequencing/perf-10k.md
```

**25 k pps (30 s)**

```bash
perf-test ... -pps 25000 -output testing/feat-v2-frame-sequencing/perf-25k.md
```

**50 k pps (30 s)**

```bash
perf-test ... -pps 50000 -output testing/feat-v2-frame-sequencing/perf-50k.md
```

### Pass criteria

| Test | Criterion | Baseline (`main`) |
|------|-----------|-------------------|
| Smoke | drop rate 0%, health ok | — |
| 10 k pps | drop rate 0% | 0.00% |
| 25 k pps | drop rate ≤ 0.5% | 0.33% |
| 50 k pps | drop rate ≤ 6% | 5.77% |
| All rates | proxy internal drops = 0 | 0 at all rates |
| All rates | group distribution stddev < 1% of mean | < 0.1% at all rates |

---

## Result files

| File | Status |
|------|--------|
| [`smoke-test.md`](smoke-test.md) | pending |
| [`perf-10k.md`](perf-10k.md) | pending |
| [`perf-25k.md`](perf-25k.md) | pending |
| [`perf-50k.md`](perf-50k.md) | pending |
| [`summary.md`](summary.md) | pending |
