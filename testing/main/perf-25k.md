# Throughput Performance Report

## Test Configuration

| Parameter | Value |
|-----------|-------|
| Date | 2026-04-01T12:44:11-06:00 |
| Proxy address | `[fd20::2]:9000` |
| Metrics URL | `http://10.10.10.20:9100` |
| Shard bits | 2 |
| Num groups | 4 |
| Payload range | 256–512 bytes |
| Target PPS | 25000 |
| Duration | 5m0s |
| LXD collection | true |
| Receivers | recv1, recv2, recv3 |

## Results

| Metric | Value |
|--------|-------|
| Target PPS | 25000 |
| Actual PPS | 25000 |
| Frames sent | 7499999 |
| Bytes sent | 2.99 GiB |
| TX throughput | 85.60 Mbps |
| Duration | 5m0s |
| Proxy RX packets | 7475454 |
| Proxy RX bytes | 2.98 GiB |
| Proxy forwarded packets | 7475454 |
| Proxy forwarded bytes | 2.98 GiB |
| Proxy dropped packets | 0 |
| Drop rate | 0.00% |
| Egress errors | 0 |
| Ingress errors | 0 |

## Summary

- **Frames sent:** 7499999
- **Proxy received:** 7475454
- **Proxy forwarded:** 7475454
- **Proxy dropped:** 0 (0.00%)
- **Achieved throughput:** 25000 pps / 85.60 Mbps

## Multicast Group Distribution (Proxy Egress)

Packets sent by proxy per shard group (from `bsp_flow_packets_total`):

| Group | Packets | Bytes | % of Total |
|-------|---------|-------|------------|
| ff05::0 | 1869487 | 763.15 MiB | 25.0% |
| ff05::1 | 1868809 | 762.75 MiB | 25.0% |
| ff05::2 | 1867855 | 762.47 MiB | 25.0% |
| ff05::3 | 1869303 | 762.84 MiB | 25.0% |
| **Total** | **7475454** | **2.98 GiB** | **100%** |

**Distribution stats:** min=1867855, max=1869487, mean=1868864, stddev=633

## Per-Group Per-Receiver Delivery Matrix

Packets received at each receiver, broken down by destination multicast group (from `tshark` post-processing):

| Group | recv1 | recv2 | recv3 | Subscribed receivers |
|-------|--------|--------|--------|------------------------|
| ff05:: | 1869487 | — | — | recv1 |
| ff05::1 | 1868809 | — | 1868809 | recv1, recv3 |
| ff05::2 | 1867855 | 1867855 | — | recv1, recv2 |
| ff05::3 | 1869303 | — | 1869303 | recv1, recv3 |
| **Total** | **7475454** | **1867855** | **3738112** | |

**Expected vs actual traffic share** (due to uneven group subscriptions):

| Receiver | Groups | Expected share | Actual packets | Actual share |
|----------|--------|----------------|----------------|--------------|
| recv1 | 4/4 | 100% | 7475454 | 100.0% |
| recv2 | 1/4 | 25% | 1867855 | 25.0% |
| recv3 | 2/4 | 50% | 3738112 | 50.0% |

## Interface Statistics

Delta of `ip -s link show enp6s0` before and after test:

| VM | Direction | Packets | Bytes | Errors | Dropped |
|----|-----------|---------|-------|--------|---------|
| proxy | RX | 7500056 | 3.42 GiB | 0 | 0 |
| proxy | TX | 7475499 | 3.41 GiB | 0 | 0 |
| recv1 | RX | 7475483 | 3.41 GiB | 0 | 0 |
| recv1 | TX | 40 | 3.77 KiB | 0 | 0 |
| recv2 | RX | 1867884 | 872.91 MiB | 0 | 0 |
| recv2 | TX | 22 | 2.02 KiB | 0 | 0 |
| recv3 | RX | 3738141 | 1.71 GiB | 0 | 0 |
| recv3 | TX | 28 | 2.60 KiB | 0 | 0 |

## Receiver Delivery (recv-test-frames)

| Receiver | Frames received |
|----------|-----------------|
| recv1 | 7458626 |
| recv2 | 1867855 |
| recv3 | 3735110 |

## Node Group Membership

| Receiver | Groups joined | Expected share |
|----------|---------------|----------------|
| recv1 | ff05::, ff05::1, ff05::2, ff05::3 | 100% |
| recv2 | ff05::2 | 25% |
| recv3 | ff05::1, ff05::3 | 50% |

