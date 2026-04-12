# Smoke Test — feat/v2-frame-sequencing

> **Status: pending** — run the steps in [README.md](README.md) §2 and paste results here.

## Test Configuration

| Parameter | Value |
|-----------|-------|
| Date | |
| Proxy branch | `feat/v2-frame-sequencing` |
| Proxy address | `[fd20::2]:9000` |
| Metrics URL | `http://10.10.10.20:9100` |
| Shard bits | 2 |

## Health

```
# paste: lxc exec proxy -- systemctl status bitcoin-shard-proxy
# paste: curl output for /healthz and /readyz
```

## UDP Forwarding

```
# paste: send-test-frames output
# paste: bsp_packets_forwarded_total metric line
```

## Multicast Delivery

```
# paste: tcpdump output from recv1
```

## Result

| Check | Pass/Fail |
|-------|-----------|
| Service active | |
| /healthz = ok | |
| /readyz = ok | |
| forwarded ≥ 4 | |
| drop rate 0% | |
| Multicast arrives at recv1 | |
