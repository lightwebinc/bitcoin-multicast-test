# Throughput Performance Report

## Test Configuration

| Parameter | Value |
|----------------|---------------------------|
| Date | 2026-04-15T13:43:21-06:00 |
| Proxy address | `[fd20::2]:9000` |
| Metrics URL | `http://10.10.10.20:9100` |
| Shard bits | 2 |
| Num groups | 4 |
| Payload range | 256–512 bytes |
| Target PPS | 50000 |
| Duration | 30s |
| LXD collection | true |
| Receivers | recv1, recv2, recv3 |

## Results

| Metric | Value |
|-------------------------|-------------|
| Target PPS | 50000 |
| Actual PPS | 50000 |
| Frames sent | 1499996 |
| Bytes sent | 669.47 MiB |
| TX throughput | 187.20 Mbps |
| Duration | 30s |
| Proxy RX packets | 1345634 |
| Proxy RX bytes | 600.57 MiB |
| Proxy forwarded packets | 1345634 |
| Proxy forwarded bytes | 600.57 MiB |
| Proxy dropped packets | 0 |
| Drop rate | 0.00% |
| Egress errors | 0 |
| Ingress errors | 0 |

## Summary

- **Frames sent:** 1499996
- **Proxy received:** 1345634
- **Proxy forwarded:** 1345634
- **Proxy dropped:** 0 (0.00%)
- **Achieved throughput:** 50000 pps / 187.20 Mbps

## Multicast Group Distribution (Proxy Egress)

Packets sent by proxy per shard group (from `bsp_flow_packets_total`):

| Group | Packets | Bytes | % of Total |
|-----------|-------------|----------------|------------|
| ff05::0 | 336758 | 150.31 MiB | 25.0% |
| ff05::1 | 337336 | 150.57 MiB | 25.1% |
| ff05::2 | 335709 | 149.84 MiB | 24.9% |
| ff05::3 | 335831 | 149.85 MiB | 25.0% |
| **Total** | **1345634** | **600.57 MiB** | **100%** |

**Distribution stats:** min=335709, max=337336, mean=336408, stddev=672

## Per-Group Per-Receiver Delivery Matrix

Packets received at each receiver, broken down by destination multicast group (from `tshark` post-processing):

| Group | recv1 | recv2 | recv3 | Subscribed receivers |
|-----------|-------------|------------|------------|----------------------|
| ff05:: | 336675 | — | — | recv1 |
| ff05::1 | 337251 | — | 336964 | recv1, recv3 |
| ff05::2 | 335637 | 335709 | — | recv1, recv2 |
| ff05::3 | 335745 | — | 335470 | recv1, recv3 |
| **Total** | **1345308** | **335709** | **672434** |  |

**Expected vs actual traffic share** (due to uneven group subscriptions):

| Receiver | Groups | Expected share | Actual packets | Actual share |
|----------|--------|----------------|----------------|--------------|
| recv1 | 4/4 | 100% | 1345308 | 100.0% |
| recv2 | 1/4 | 25% | 335709 | 24.9% |
| recv3 | 2/4 | 50% | 672434 | 50.0% |

## Interface Statistics

Delta of `ip -s link show enp6s0` before and after test:

| VM | Direction | Packets | Bytes | Errors | Dropped |
|-------|-----------|---------|------------|--------|---------|
| proxy | RX | 1499171 | 757.74 MiB | 0 | 0 |
| proxy | TX | 1345644 | 680.14 MiB | 0 | 0 |
| recv1 | RX | 1345312 | 679.97 MiB | 0 | 0 |
| recv1 | TX | 6 | 516 B | 0 | 0 |
| recv2 | RX | 335713 | 169.69 MiB | 0 | 0 |
| recv2 | TX | 3 | 258 B | 0 | 0 |
| recv3 | RX | 672438 | 339.85 MiB | 0 | 0 |
| recv3 | TX | 4 | 344 B | 0 | 0 |

## Receiver Delivery (recv-test-frames)

| Receiver | Frames received |
|----------|-----------------|
| recv1 | 1242996 |
| recv2 | 335424 |
| recv3 | 667466 |

## Node Group Membership

| Receiver | Groups joined | Expected share |
|----------|-----------------------------------|----------------|
| recv1 | ff05::, ff05::1, ff05::2, ff05::3 | 100% |
| recv2 | ff05::2 | 25% |
| recv3 | ff05::1, ff05::3 | 50% |

