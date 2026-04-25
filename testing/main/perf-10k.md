# Throughput Performance Report

## Test Configuration

| Parameter | Value |
|----------------|---------------------------|
| Date | 2026-04-01T11:28:12-06:00 |
| Proxy address | `[fd20::2]:9000` |
| Metrics URL | `http://10.10.10.20:9100` |
| Shard bits | 2 |
| Num groups | 4 |
| Payload range | 256–512 bytes |
| Target PPS | 10000 |
| Duration | 5m0s |
| LXD collection | true |
| Receivers | recv1, recv2, recv3 |

## Results

| Metric | Value |
|-------------------------|------------|
| Target PPS | 10000 |
| Actual PPS | 10000 |
| Frames sent | 2999999 |
| Bytes sent | 1.20 GiB |
| TX throughput | 34.24 Mbps |
| Duration | 5m0.001s |
| Proxy RX packets | 2999999 |
| Proxy RX bytes | 1.20 GiB |
| Proxy forwarded packets | 2999999 |
| Proxy forwarded bytes | 1.20 GiB |
| Proxy dropped packets | 0 |
| Drop rate | 0.00% |
| Egress errors | 0 |
| Ingress errors | 0 |

## Summary

- **Frames sent:** 2999999
- **Proxy received:** 2999999
- **Proxy forwarded:** 2999999
- **Proxy dropped:** 0 (0.00%)
- **Achieved throughput:** 10000 pps / 34.24 Mbps

## Multicast Group Distribution (Proxy Egress)

Packets sent by proxy per shard group (from `bsp_flow_packets_total`):

| Group | Packets | Bytes | % of Total |
|-----------|-------------|--------------|------------|
| ff05::0 | 748774 | 305.57 MiB | 25.0% |
| ff05::1 | 749771 | 306.06 MiB | 25.0% |
| ff05::2 | 750810 | 306.35 MiB | 25.0% |
| ff05::3 | 750644 | 306.41 MiB | 25.0% |
| **Total** | **2999999** | **1.20 GiB** | **100%** |

**Distribution stats:** min=748774, max=750810, mean=750000, stddev=810

## Per-Group Per-Receiver Delivery Matrix

Packets received at each receiver, broken down by destination multicast group (from `tshark` post-processing):

| Group | recv1 | recv2 | recv3 | Subscribed receivers |
|-----------|-------------|------------|-------------|----------------------|
| ff05:: | 748774 | — | — | recv1 |
| ff05::1 | 749771 | — | 749771 | recv1, recv3 |
| ff05::2 | 750810 | 750810 | — | recv1, recv2 |
| ff05::3 | 750644 | — | 750644 | recv1, recv3 |
| **Total** | **2999999** | **750810** | **1500415** |  |

**Expected vs actual traffic share** (due to uneven group subscriptions):

| Receiver | Groups | Expected share | Actual packets | Actual share |
|----------|--------|----------------|----------------|--------------|
| recv1 | 4/4 | 100% | 2999999 | 100.0% |
| recv2 | 1/4 | 25% | 750810 | 25.0% |
| recv3 | 2/4 | 50% | 1500415 | 50.0% |

## Interface Statistics

Delta of `ip -s link show enp6s0` before and after test:

| VM | Direction | Packets | Bytes | Errors | Dropped |
|-------|-----------|---------|------------|--------|---------|
| proxy | RX | 3000034 | 1.37 GiB | 0 | 0 |
| proxy | TX | 3000027 | 1.37 GiB | 0 | 0 |
| recv1 | RX | 3000015 | 1.37 GiB | 0 | 0 |
| recv1 | TX | 26 | 2.39 KiB | 0 | 0 |
| recv2 | RX | 750826 | 350.74 MiB | 0 | 0 |
| recv2 | TX | 14 | 1.26 KiB | 0 | 0 |
| recv3 | RX | 1500431 | 701.18 MiB | 0 | 0 |
| recv3 | TX | 18 | 1.64 KiB | 0 | 0 |

## Receiver Delivery (recv-test-frames)

| Receiver | Frames received |
|----------|-----------------|
| recv1 | 2999991 |
| recv2 | 750810 |
| recv3 | 1500415 |

## Node Group Membership

| Receiver | Groups joined | Expected share |
|----------|-----------------------------------|----------------|
| recv1 | ff05::, ff05::1, ff05::2, ff05::3 | 100% |
| recv2 | ff05::2 | 25% |
| recv3 | ff05::1, ff05::3 | 50% |

