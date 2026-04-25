# Throughput Performance Report

## Test Configuration

| Parameter | Value |
|----------------|---------------------------|
| Date | 2026-04-15T13:40:17-06:00 |
| Proxy address | `[fd20::2]:9000` |
| Metrics URL | `http://10.10.10.20:9100` |
| Shard bits | 2 |
| Num groups | 4 |
| Payload range | 256–512 bytes |
| Target PPS | 10000 |
| Duration | 30s |
| LXD collection | true |
| Receivers | recv1, recv2, recv3 |

## Results

| Metric | Value |
|-------------------------|------------|
| Target PPS | 10000 |
| Actual PPS | 10000 |
| Frames sent | 299999 |
| Bytes sent | 133.89 MiB |
| TX throughput | 37.44 Mbps |
| Duration | 30.001s |
| Proxy RX packets | 299999 |
| Proxy RX bytes | 133.89 MiB |
| Proxy forwarded packets | 299999 |
| Proxy forwarded bytes | 133.89 MiB |
| Proxy dropped packets | 0 |
| Drop rate | 0.00% |
| Egress errors | 0 |
| Ingress errors | 0 |

## Summary

- **Frames sent:** 299999
- **Proxy received:** 299999
- **Proxy forwarded:** 299999
- **Proxy dropped:** 0 (0.00%)
- **Achieved throughput:** 10000 pps / 37.44 Mbps

## Multicast Group Distribution (Proxy Egress)

Packets sent by proxy per shard group (from `bsp_flow_packets_total`):

| Group | Packets | Bytes | % of Total |
|-----------|------------|----------------|------------|
| ff05::0 | 74725 | 33.35 MiB | 24.9% |
| ff05::1 | 74972 | 33.46 MiB | 25.0% |
| ff05::2 | 74976 | 33.48 MiB | 25.0% |
| ff05::3 | 75326 | 33.61 MiB | 25.1% |
| **Total** | **299999** | **133.89 MiB** | **100%** |

**Distribution stats:** min=74725, max=75326, mean=75000, stddev=214

## Per-Group Per-Receiver Delivery Matrix

Packets received at each receiver, broken down by destination multicast group (from `tshark` post-processing):

| Group | recv1 | recv2 | recv3 | Subscribed receivers |
|-----------|------------|-----------|------------|----------------------|
| ff05:: | 74725 | — | — | recv1 |
| ff05::1 | 74972 | — | 74972 | recv1, recv3 |
| ff05::2 | 74976 | 74976 | — | recv1, recv2 |
| ff05::3 | 75326 | — | 75326 | recv1, recv3 |
| **Total** | **299999** | **74976** | **150298** |  |

**Expected vs actual traffic share** (due to uneven group subscriptions):

| Receiver | Groups | Expected share | Actual packets | Actual share |
|----------|--------|----------------|----------------|--------------|
| recv1 | 4/4 | 100% | 299999 | 100.0% |
| recv2 | 1/4 | 25% | 74976 | 25.0% |
| recv3 | 2/4 | 50% | 150298 | 50.1% |

## Interface Statistics

Delta of `ip -s link show enp6s0` before and after test:

| VM | Direction | Packets | Bytes | Errors | Dropped |
|-------|-----------|---------|------------|--------|---------|
| proxy | RX | 300009 | 151.63 MiB | 0 | 0 |
| proxy | TX | 300004 | 151.63 MiB | 0 | 0 |
| recv1 | RX | 300007 | 151.63 MiB | 0 | 0 |
| recv1 | TX | 2 | 380 B | 0 | 0 |
| recv2 | RX | 74985 | 37.91 MiB | 0 | 0 |
| recv2 | TX | 2 | 260 B | 0 | 0 |
| recv3 | RX | 150307 | 75.95 MiB | 0 | 0 |
| recv3 | TX | 2 | 300 B | 0 | 0 |

## Receiver Delivery (recv-test-frames)

| Receiver | Frames received |
|----------|-----------------|
| recv1 | 299984 |
| recv2 | 74976 |
| recv3 | 150298 |

## Node Group Membership

| Receiver | Groups joined | Expected share |
|----------|-----------------------------------|----------------|
| recv1 | ff05::, ff05::1, ff05::2, ff05::3 | 100% |
| recv2 | ff05::2 | 25% |
| recv3 | ff05::1, ff05::3 | 50% |

