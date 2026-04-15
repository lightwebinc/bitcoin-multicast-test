# Throughput Performance Report

## Test Configuration

| Parameter | Value |
|-----------|-------|
| Date | 2026-04-15T13:39:24-06:00 |
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
| Bytes sent | 1.34 MiB |
| TX throughput | 0.37 Mbps |
| Duration | 30.001s |
| Proxy RX packets | 2999 |
| Proxy RX bytes | 1.34 MiB |
| Proxy forwarded packets | 2999 |
| Proxy forwarded bytes | 1.34 MiB |
| Proxy dropped packets | 0 |
| Drop rate | 0.00% |
| Egress errors | 0 |
| Ingress errors | 0 |

## Summary

- **Frames sent:** 2999
- **Proxy received:** 2999
- **Proxy forwarded:** 2999
- **Proxy dropped:** 0 (0.00%)
- **Achieved throughput:** 100 pps / 0.37 Mbps

## Multicast Group Distribution (Proxy Egress)

Packets sent by proxy per shard group (from `bsp_flow_packets_total`):

| Group | Packets | Bytes | % of Total |
|-------|---------|-------|------------|
| ff05::0 | 750 | 344.77 KiB | 25.0% |
| ff05::1 | 723 | 330.54 KiB | 24.1% |
| ff05::2 | 748 | 340.69 KiB | 24.9% |
| ff05::3 | 778 | 353.98 KiB | 25.9% |
| **Total** | **2999** | **1.34 MiB** | **100%** |

**Distribution stats:** min=723, max=778, mean=750, stddev=19

## Per-Group Per-Receiver Delivery Matrix

Packets received at each receiver, broken down by destination multicast group (from `tshark` post-processing):

| Group | recv1 | recv2 | recv3 | Subscribed receivers |
|-------|--------|--------|--------|------------------------|
| ff05:: | 750 | — | — | recv1 |
| ff05::1 | 723 | — | 723 | recv1, recv3 |
| ff05::2 | 748 | 748 | — | recv1, recv2 |
| ff05::3 | 778 | — | 778 | recv1, recv3 |
| **Total** | **2999** | **748** | **1501** | |

**Expected vs actual traffic share** (due to uneven group subscriptions):

| Receiver | Groups | Expected share | Actual packets | Actual share |
|----------|--------|----------------|----------------|--------------|
| recv1 | 4/4 | 100% | 2999 | 100.0% |
| recv2 | 1/4 | 25% | 748 | 24.9% |
| recv3 | 2/4 | 50% | 1501 | 50.1% |

## Interface Statistics

Delta of `ip -s link show enp6s0` before and after test:

| VM | Direction | Packets | Bytes | Errors | Dropped |
|----|-----------|---------|-------|--------|---------|
| proxy | RX | 3004 | 1.52 MiB | 0 | 0 |
| proxy | TX | 3007 | 1.52 MiB | 0 | 0 |
| recv1 | RX | 3001 | 1.52 MiB | 0 | 0 |
| recv1 | TX | 6 | 516 B | 0 | 0 |
| recv2 | RX | 750 | 386.11 KiB | 0 | 0 |
| recv2 | TX | 3 | 258 B | 0 | 0 |
| recv3 | RX | 1503 | 775.52 KiB | 0 | 0 |
| recv3 | TX | 4 | 344 B | 0 | 0 |

## Receiver Delivery (recv-test-frames)

| Receiver | Frames received |
|----------|-----------------|
| recv1 | 2999 |
| recv2 | 748 |
| recv3 | 1501 |

## Node Group Membership

| Receiver | Groups joined | Expected share |
|----------|---------------|----------------|
| recv1 | ff05::, ff05::1, ff05::2, ff05::3 | 100% |
| recv2 | ff05::2 | 25% |
| recv3 | ff05::1, ff05::3 | 50% |

