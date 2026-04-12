# bitcoin-shard-proxy — Throughput Summary (feat/v2-frame-sequencing)

> **Status: pending** — fill in after all perf runs complete.

Baseline: [`../main/summary.md`](../main/summary.md)

**Date:**  
**Environment:** LXD lab (shard\_bits=2, 4 groups, payload 256–512 B, 30 s each run)  
**Topology:** source → proxy → lxdbr1 → recv1 / recv2 / recv3  
**Proxy branch:** `feat/v2-frame-sequencing`

---

## Rate Sweep Results

| Target PPS | Sent | Proxy RX | Ingress loss | Proxy drops | Egress errors | TX throughput |
|-----------|------|----------|-------------|-------------|---------------|---------------|
| 10,000 | | | | | | |
| 25,000 | | | | | | |
| 50,000 | | | | | | |

## Regression vs main baseline

| Metric | main (10k) | feat (10k) | main (25k) | feat (25k) | main (50k) | feat (50k) |
|--------|-----------|-----------|-----------|-----------|-----------|-----------|
| Proxy drops | 0 | | 0 | | 0 | |
| Drop rate | 0.00% | | 0.33% | | 5.77% | |
| Egress errors | 0 | | 0 | | 0 | |
| Ingress errors | 0 | | 0 | | 0 | |

## Delivery Accuracy

| Receiver | Groups | Expected share | 10k actual | 25k actual | 50k actual |
|----------|--------|----------------|-----------|-----------|-----------|
| recv1 | 4/4 | 100% | | | |
| recv2 | 1/4 | 25% | | | |
| recv3 | 2/4 | 50% | | | |
