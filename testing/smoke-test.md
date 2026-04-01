# Throughput Performance Report

## Test Configuration

| Parameter | Value |
|-----------|-------|
| Date | 2026-04-01T11:25:43-06:00 |
| Proxy address | `[fd20::2]:9000` |
| Metrics URL | `http://10.10.10.20:9100` |
| Shard bits | 2 |
| Num groups | 4 |
| Payload range | 256–512 bytes |
| Target PPS | 100 |
| Duration | 30s |
| LXD collection | true |
| Receivers | recv1, recv2, recv3 |

## Results

| Metric | Value |
|--------|-------|
| Target PPS | 100 |
| Actual PPS | 100 |
| Frames sent | 2999 |
| Bytes sent | 1.22 MiB |
| TX throughput | 0.34 Mbps |
| Duration | 30.001s |
| Proxy RX packets | 2999 |
| Proxy RX bytes | 1.22 MiB |
| Proxy forwarded packets | 2999 |
| Proxy forwarded bytes | 1.22 MiB |
| Proxy dropped packets | 0 |
| Drop rate | 0.00% |
| Egress errors | 0 |
| Ingress errors | 0 |

## Summary

- **Frames sent:** 2999
- **Proxy received:** 2999
- **Proxy forwarded:** 2999
- **Proxy dropped:** 0 (0.00%)
- **Achieved throughput:** 100 pps / 0.34 Mbps

## Multicast Group Distribution (Proxy Egress)

Packets sent by proxy per shard group (from `bsp_flow_packets_total`):

| Group | Packets | Bytes | % of Total |
|-------|---------|-------|------------|
| ff05::0 | 737 | 307.27 KiB | 24.6% |
| ff05::1 | 757 | 319.54 KiB | 25.2% |
| ff05::2 | 743 | 310.59 KiB | 24.8% |
| ff05::3 | 762 | 314.84 KiB | 25.4% |
| **Total** | **2999** | **1.22 MiB** | **100%** |

**Distribution stats:** min=737, max=762, mean=750, stddev=10

## Per-Group Per-Receiver Delivery Matrix

Packets received at each receiver, broken down by destination multicast group (from `tshark` post-processing):

| Group | recv1 | recv2 | recv3 | Subscribed receivers |
|-------|--------|--------|--------|------------------------|
| ff05:: | 737 | — | — | recv1 |
| ff05::1 | 757 | — | 757 | recv1, recv3 |
| ff05::2 | 743 | 743 | — | recv1, recv2 |
| ff05::3 | 762 | — | 762 | recv1, recv3 |
| **Total** | **2999** | **743** | **1519** | |

**Expected vs actual traffic share** (due to uneven group subscriptions):

| Receiver | Groups | Expected share | Actual packets | Actual share |
|----------|--------|----------------|----------------|--------------|
| recv1 | 4/4 | 100% | 2999 | 100.0% |
| recv2 | 1/4 | 25% | 743 | 24.8% |
| recv3 | 2/4 | 50% | 1519 | 50.7% |

## Interface Statistics

Delta of `ip -s link show enp6s0` before and after test:

| VM | Direction | Packets | Bytes | Errors | Dropped |
|----|-----------|---------|-------|--------|---------|
| proxy | RX | 3004 | 1.40 MiB | 0 | 0 |
| proxy | TX | 3004 | 1.40 MiB | 0 | 0 |
| recv1 | RX | 3001 | 1.40 MiB | 0 | 0 |
| recv1 | TX | 2 | 172 B | 0 | 0 |
| recv2 | RX | 745 | 355.71 KiB | 0 | 0 |
| recv2 | TX | 1 | 86 B | 0 | 0 |
| recv3 | RX | 1521 | 726.48 KiB | 0 | 0 |
| recv3 | TX | 2 | 172 B | 0 | 0 |

## Receiver Delivery (recv-test-frames)

| Receiver | Frames received |
|----------|-----------------|
| recv1 | 2999 |
| recv2 | 743 |
| recv3 | 1519 |

## Node Group Membership

| Receiver | Groups joined | Expected share |
|----------|---------------|----------------|
| recv1 | ff05::, ff05::1, ff05::2, ff05::3 | 100% |
| recv2 | ff05::2 | 25% |
| recv3 | ff05::1, ff05::3 | 50% |

