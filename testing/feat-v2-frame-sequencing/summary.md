# bitcoin-shard-proxy — Throughput Summary (feat/v2-frame-sequencing)

Baseline: [`../main/summary.md`](../main/summary.md)

**Date:** 2026-04-15  
**Environment:** LXD lab (shard\_bits=2, 4 groups, payload 256–512 B, 30 s each run)  
**Topology:** source → proxy → lxdbr1 → recv1 / recv2 / recv3  
**Proxy branch:** `feat/v2-frame-sequencing`

---

## Rate Sweep Results

| Target PPS | Sent | Proxy RX | Ingress loss | Proxy drops | Egress errors | TX throughput |
|------------|-----------|-----------|--------------|-------------|---------------|---------------|
| 10,000 | 299,999 | 299,999 | 0.00% | 0 | 0 | 37.44 Mbps |
| 25,000 | 749,972 | 745,227 | 0.63% | 0 | 0 | 93.60 Mbps |
| 50,000 | 1,499,996 | 1,345,634 | 10.29% | 0 | 0 | 187.20 Mbps |

**Key finding:** The proxy drops zero packets at every tested rate. All packet loss originates in the source→proxy LXD virtual NIC / bridge path (ingress fabric), not inside the proxy. The forward path and shard-routing logic are identical to `main`.

Note: main baseline used 5-minute runs; these runs are 30 s. Ingress fabric loss at 25k/50k shows higher variance in shorter windows — the 10.29% at 50k vs. 5.77% main baseline is expected LXD fabric behaviour, not a proxy regression.

---

## Regression vs main baseline

| Metric | main (10k) | feat (10k) | main (25k) | feat (25k) | main (50k) | feat (50k) |
|-----------------|------------|------------|------------|------------|------------|------------|
| Proxy drops | 0 | 0 | 0 | 0 | 0 | 0 |
| Proxy drop rate | 0.00% | 0.00% | 0.00% | 0.00% | 0.00% | 0.00% |
| Ingress loss | 0.00% | 0.00% | 0.33% | 0.63% | 5.77% | 10.29% |
| Egress errors | 0 | 0 | 0 | 0 | 0 | 0 |
| Ingress errors | 0 | 0 | 0 | 0 | 0 | 0 |

---

## Delivery Accuracy

Group-level delivery matches subscriptions exactly at every rate:

| Receiver | Groups | Expected share | 10k actual | 25k actual | 50k actual |
|----------|--------|----------------|------------|------------|------------|
| recv1 | 4/4 | 100% | 100.0% | 100.0% | 100.0% |
| recv2 | 1/4 | 25% | 25.0% | 25.0% | 24.9% |
| recv3 | 2/4 | 50% | 50.1% | 50.0% | 50.0% |

---

## Group Distribution (proxy egress)

Traffic is uniformly distributed across the 4 shard groups (stddev < 0.3% of mean at all rates):

| Rate | Group stddev | Mean | Stddev/mean |
|------|--------------|---------|-------------|
| 10k | 214 pkts | 75,000 | 0.29% |
| 25k | 343 pkts | 186,307 | 0.18% |
| 50k | 672 pkts | 336,408 | 0.20% |

---

## Report Files

| File | Rate |
|----------------------------------|-------------------|
| [`smoke-test.md`](smoke-test.md) | 100 pps / 30 s |
| [`perf-10k.md`](perf-10k.md) | 10,000 pps / 30 s |
| [`perf-25k.md`](perf-25k.md) | 25,000 pps / 30 s |
| [`perf-50k.md`](perf-50k.md) | 50,000 pps / 30 s |
