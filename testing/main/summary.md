# bitcoin-shard-proxy — Throughput Summary

**Date:** 2026-04-01  
**Environment:** LXD lab (shard\_bits=2, 4 groups, payload 256–512 B, 5 min each run)  
**Topology:** source → proxy → lxdbr1 → recv1 / recv2 / recv3

---

## Rate Sweep Results

| Target PPS | Sent | Proxy RX | Ingress loss | Proxy drops | Egress errors | TX throughput |
|-----------|------|----------|-------------|-------------|---------------|---------------|
| 10,000    | 2,999,999  | 2,999,999  | 0.00% | 0 | 0 | 34.24 Mbps  |
| 25,000    | 7,499,999  | 7,475,454  | 0.33% | 0 | 0 | 85.60 Mbps  |
| 50,000    | 14,999,993 | 14,135,144 | 5.77% | 0 | 0 | 171.22 Mbps |

**Key finding:** The proxy itself drops zero packets at every tested rate. All packet loss originates in the source→proxy LXD virtual NIC / bridge path (ingress fabric), not inside the proxy. The proxy is not the bottleneck in this lab.

---

## Delivery Accuracy (all rates)

Group-level delivery matches subscriptions exactly at every rate:

| Receiver | Groups | Expected share | 10k actual | 25k actual | 50k actual |
|----------|--------|----------------|-----------|-----------|-----------|
| recv1    | 4/4    | 100%           | 100.0%    | 100.0%    | 100.0%    |
| recv2    | 1/4    | 25%            | 24.8%     | 25.0%     | 25.0%     |
| recv3    | 2/4    | 50%            | 50.7%     | 50.0%     | 50.0%     |

MLD snooping correctly prevents unsubscribed groups from being delivered to receivers.

---

## Group Distribution (proxy egress)

Traffic is uniformly distributed across the 4 shard groups (stddev < 0.1% of mean at all rates).

| Rate   | Group stddev |
|--------|-------------|
| 10k    | 10 pkts / 750k mean  |
| 25k    | 633 pkts / 1.87M mean |
| 50k    | 3,411 pkts / 3.53M mean |

---

## Source→Proxy Ingress Capacity

The LXD virtual NIC saturates between 25k–50k pps:

- At 25k pps: 0.33% loss (fabric near limit)
- At 50k pps: 5.77% loss (fabric saturated)

The proxy's actual ceiling is above 50k pps; a hardware sender or kernel-bypass source is needed to characterise it further.

---

## Proxy Drop Rate

Zero drops at all tested rates. `bsp_packets_received_total` == `bsp_flow_packets_total` throughout every run.

---

## Report Files

| File | Rate |
|------|------|
| `report-10k.md`  | 10,000 pps |
| `report-25k.md`  | 25,000 pps |
| `report-50k.md`  | 50,000 pps |
