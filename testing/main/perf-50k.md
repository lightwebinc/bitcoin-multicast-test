# Throughput Performance Report

## Test Configuration

| Parameter | Value |
|-----------|-------|
| Date | 2026-04-01T13:02:54-06:00 |
| Proxy address | `[fd20::2]:9000` |
| Metrics URL | `http://10.10.10.20:9100` |
| Shard bits | 2 |
| Num groups | 4 |
| Payload range | 256–512 bytes |
| Target PPS | 50000 |
| Duration | 5m0s |
| LXD collection | true |
| Receivers | recv1, recv2, recv3 |

## Results

| Metric | Value |
|--------|-------|
| Target PPS | 50000 |
| Actual PPS | 50000 |
| Frames sent | 14999993 |
| Bytes sent | 5.98 GiB |
| TX throughput | 171.22 Mbps |
| Duration | 5m0s |
| Proxy RX packets | 14135144 |
| Proxy RX bytes | 5.63 GiB |
| Proxy forwarded packets | 14135144 |
| Proxy forwarded bytes | 5.63 GiB |
| Proxy dropped packets | 0 |
| Drop rate | 0.00% |
| Egress errors | 0 |
| Ingress errors | 0 |

## Summary

- **Frames sent:** 14999993
- **Proxy received:** 14135144
- **Proxy forwarded:** 14135144
- **Proxy dropped:** 0 (0.00%)
- **Achieved throughput:** 50000 pps / 171.22 Mbps

## Multicast Group Distribution (Proxy Egress)

Packets sent by proxy per shard group (from `bsp_flow_packets_total`):

| Group | Packets | Bytes | % of Total |
|-------|---------|-------|------------|
| ff05::0 | 3535461 | 1.41 GiB | 25.0% |
| ff05::1 | 3537171 | 1.41 GiB | 25.0% |
| ff05::2 | 3534376 | 1.41 GiB | 25.0% |
| ff05::3 | 3528136 | 1.41 GiB | 25.0% |
| **Total** | **14135144** | **5.63 GiB** | **100%** |

**Distribution stats:** min=3528136, max=3537171, mean=3533786, stddev=3411

## Per-Group Per-Receiver Delivery Matrix

Packets received at each receiver, broken down by destination multicast group (from `tshark` post-processing):

| Group | recv1 | recv2 | recv3 | Subscribed receivers |
|-------|--------|--------|--------|------------------------|
| ff05:: | 3534360 | — | — | recv1 |
| ff05::1 | 3536079 | — | 3535986 | recv1, recv3 |
| ff05::2 | 3531782 | 3534376 | — | recv1, recv2 |
| ff05::3 | 3526960 | — | 3526857 | recv1, recv3 |
| **Total** | **14129181** | **3534376** | **7062843** | |

**Expected vs actual traffic share** (due to uneven group subscriptions):

| Receiver | Groups | Expected share | Actual packets | Actual share |
|----------|--------|----------------|----------------|--------------|
| recv1 | 4/4 | 100% | 14129181 | 100.0% |
| recv2 | 1/4 | 25% | 3534376 | 25.0% |
| recv3 | 2/4 | 50% | 7062843 | 50.0% |

## Interface Statistics

Delta of `ip -s link show enp6s0` before and after test:

| VM | Direction | Packets | Bytes | Errors | Dropped |
|----|-----------|---------|-------|--------|---------|
| proxy | RX | 14996281 | 6.84 GiB | 0 | 0 |
| proxy | TX | 14135195 | 6.45 GiB | 0 | 0 |
| recv1 | RX | 14129226 | 6.45 GiB | 0 | 0 |
| recv1 | TX | 60 | 5.65 KiB | 0 | 0 |
| recv2 | RX | 3534421 | 1.61 GiB | 0 | 0 |
| recv2 | TX | 33 | 3.03 KiB | 0 | 0 |
| recv3 | RX | 7062888 | 3.22 GiB | 0 | 0 |
| recv3 | TX | 42 | 3.90 KiB | 0 | 0 |

## Receiver Delivery (recv-test-frames)

| Receiver | Frames received |
|----------|-----------------|
| recv1 | 13739018 |
| recv2 | 3530766 |
| recv3 | 7049122 |

## Node Group Membership

| Receiver | Groups joined | Expected share |
|----------|---------------|----------------|
| recv1 | ff05::, ff05::1, ff05::2, ff05::3 | 100% |
| recv2 | ff05::2 | 25% |
| recv3 | ff05::1, ff05::3 | 50% |

