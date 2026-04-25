# Throughput Performance Report

## Test Configuration

| Parameter | Value |
|----------------|---------------------------|
| Date | 2026-04-15T13:41:29-06:00 |
| Proxy address | `[fd20::2]:9000` |
| Metrics URL | `http://10.10.10.20:9100` |
| Shard bits | 2 |
| Num groups | 4 |
| Payload range | 256–512 bytes |
| Target PPS | 25000 |
| Duration | 30s |
| LXD collection | true |
| Receivers | recv1, recv2, recv3 |

## Results

| Metric | Value |
|-------------------------|------------|
| Target PPS | 25000 |
| Actual PPS | 24999 |
| Frames sent | 749972 |
| Bytes sent | 334.74 MiB |
| TX throughput | 93.60 Mbps |
| Duration | 30s |
| Proxy RX packets | 745227 |
| Proxy RX bytes | 332.62 MiB |
| Proxy forwarded packets | 745227 |
| Proxy forwarded bytes | 332.62 MiB |
| Proxy dropped packets | 0 |
| Drop rate | 0.00% |
| Egress errors | 0 |
| Ingress errors | 0 |

## Summary

- **Frames sent:** 749972
- **Proxy received:** 745227
- **Proxy forwarded:** 745227
- **Proxy dropped:** 0 (0.00%)
- **Achieved throughput:** 24999 pps / 93.60 Mbps

## Multicast Group Distribution (Proxy Egress)

Packets sent by proxy per shard group (from `bsp_flow_packets_total`):

| Group | Packets | Bytes | % of Total |
|-----------|------------|----------------|------------|
| ff05::0 | 186784 | 83.38 MiB | 25.1% |
| ff05::1 | 186482 | 83.30 MiB | 25.0% |
| ff05::2 | 185991 | 82.96 MiB | 25.0% |
| ff05::3 | 185970 | 82.98 MiB | 25.0% |
| **Total** | **745227** | **332.62 MiB** | **100%** |

**Distribution stats:** min=185970, max=186784, mean=186307, stddev=343

## Per-Group Per-Receiver Delivery Matrix

Packets received at each receiver, broken down by destination multicast group (from `tshark` post-processing):

| Group | recv1 | recv2 | recv3 | Subscribed receivers |
|-----------|------------|------------|------------|----------------------|
| ff05:: | 186784 | — | — | recv1 |
| ff05::1 | 186482 | — | 186482 | recv1, recv3 |
| ff05::2 | 185991 | 185991 | — | recv1, recv2 |
| ff05::3 | 185970 | — | 185970 | recv1, recv3 |
| **Total** | **745227** | **185991** | **372452** |  |

**Expected vs actual traffic share** (due to uneven group subscriptions):

| Receiver | Groups | Expected share | Actual packets | Actual share |
|----------|--------|----------------|----------------|--------------|
| recv1 | 4/4 | 100% | 745227 | 100.0% |
| recv2 | 1/4 | 25% | 185991 | 25.0% |
| recv3 | 2/4 | 50% | 372452 | 50.0% |

## Interface Statistics

Delta of `ip -s link show enp6s0` before and after test:

| VM | Direction | Packets | Bytes | Errors | Dropped |
|-------|-----------|---------|------------|--------|---------|
| proxy | RX | 749977 | 379.08 MiB | 0 | 0 |
| proxy | TX | 745236 | 376.68 MiB | 0 | 0 |
| recv1 | RX | 745230 | 376.68 MiB | 0 | 0 |
| recv1 | TX | 6 | 516 B | 0 | 0 |
| recv2 | RX | 185994 | 93.96 MiB | 0 | 0 |
| recv2 | TX | 3 | 258 B | 0 | 0 |
| recv3 | RX | 372455 | 188.30 MiB | 0 | 0 |
| recv3 | TX | 4 | 344 B | 0 | 0 |

## Receiver Delivery (recv-test-frames)

| Receiver | Frames received |
|----------|-----------------|
| recv1 | 740486 |
| recv2 | 185991 |
| recv3 | 372353 |

## Node Group Membership

| Receiver | Groups joined | Expected share |
|----------|-----------------------------------|----------------|
| recv1 | ff05::, ff05::1, ff05::2, ff05::3 | 100% |
| recv2 | ff05::2 | 25% |
| recv3 | ff05::1, ff05::3 | 50% |

