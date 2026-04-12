# Throughput Performance Report — 25k pps (feat/v2-frame-sequencing)

> **Status: pending** — run `perf-test -pps 25000` per [README.md](README.md) §3 and save output here.

Baseline: [`../main/perf-25k.md`](../main/perf-25k.md)

## Test Configuration

| Parameter | Value |
|-----------|-------|
| Date | |
| Proxy branch | `feat/v2-frame-sequencing` |
| Proxy address | `[fd20::2]:9000` |
| Metrics URL | `http://10.10.10.20:9100` |
| Shard bits | 2 |
| Num groups | 4 |
| Payload range | 256–512 bytes |
| Target PPS | 25,000 |
| Duration | 30s |
| LXD collection | true |
| Receivers | recv1, recv2, recv3 |

<!-- perf-test output replaces this section -->
