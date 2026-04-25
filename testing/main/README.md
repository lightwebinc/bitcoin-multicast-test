# bitcoin-shard-proxy — Test Results

Performance and smoke-test results for the LXD multicast lab.

## Lab topology

```
source (fd20::10)
  └─► proxy (fd20::2)  [shard_bits=2 → 4 groups]
        └─► lxdbr1 multicast fabric
              ├─► recv1 (ff05::, ff05::1, ff05::2, ff05::3)  100% share
              ├─► recv2 (ff05::2)                              25% share
              └─► recv3 (ff05::1, ff05::3)                    50% share
```

## Running tests

Tests are driven by the `perf-test` binary from the
[bitcoin-shard-proxy](https://github.com/jefflightweb/bitcoin-shard-proxy)
repository (`cmd/perf-test/`).

```bash
# Build
cd ~/repo/bitcoin-shard-proxy
go build -o perf-test ./cmd/perf-test/

# Smoke test (100 pps, 30 s)
./perf-test \
  -proxy-addr '[fd20::2]:9000' \
  -metrics-url http://10.10.10.20:9100 \
  -shard-bits 2 -pps 100 -duration 30s \
  -payload-min 256 -payload-max 512 \
  -lxd -receivers recv1,recv2,recv3 \
  -output testing/smoke-test.md

# Full perf test (adjust -pps as needed)
./perf-test \
  -proxy-addr '[fd20::2]:9000' \
  -metrics-url http://10.10.10.20:9100 \
  -shard-bits 2 -pps 10000 -duration 5m \
  -payload-min 256 -payload-max 512 \
  -lxd -receivers recv1,recv2,recv3 \
  -output testing/perf-10k.md
```

## Prerequisites

Before running, ensure the bridge MLD querier is active on the host:

```bash
cat /sys/devices/virtual/net/lxdbr1/bridge/multicast_querier  # should be 1
```

This is persisted by `lxd-bridge-mcast-querier.service` (installed on the host
during lab setup). If missing, enable it:

```bash
sudo systemctl start lxd-bridge-mcast-querier.service
```

## Reports

| File | Type | Rate | Date |
|----------------------------------------------------|------------------------------|--------------------|------------|
| [functional-scenarios.md](functional-scenarios.md) | Functional (scenarios 01–03) | ~920 pps / 10 s | 2026-04-21 |
| [smoke-test.md](smoke-test.md) | Smoke test | 100 pps / 30 s | 2026-04-01 |
| [perf-10k.md](perf-10k.md) | Perf | 10,000 pps / 5 min | 2026-04-01 |
| [perf-25k.md](perf-25k.md) | Perf | 25,000 pps / 5 min | 2026-04-01 |
| [perf-50k.md](perf-50k.md) | Perf | 50,000 pps / 5 min | 2026-04-01 |
| [summary.md](summary.md) | Summary | all rates | 2026-04-01 |

See [functional-scenarios.md](functional-scenarios.md) for the latest end-to-end listener scenario results.
See [summary.md](summary.md) for proxy throughput analysis.
