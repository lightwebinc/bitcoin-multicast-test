# Testing

Test results are organised by the proxy branch that was deployed when the tests were run.

| Directory | Proxy branch | Status |
|-----------|-------------|--------|
| [`main/`](main/) | `main` | baseline results |
| [`feat-v2-frame-sequencing/`](feat-v2-frame-sequencing/) | `feat/v2-frame-sequencing` | in progress |

## What changed between branches

| Area | `main` | `feat/v2-frame-sequencing` |
|------|--------|---------------------------|
| UDP env var | `LISTEN_PORT` | `UDP_LISTEN_PORT` |
| TCP ingress | absent | `TCP_LISTEN_PORT` (0 = disabled) |
| Removed flags | — | `-proxy-seq`, `-static-subtree-id`, `-static-subtree-height` |
| v1 frames | not accepted | accepted, forwarded verbatim |
| v2 byte 7 | `SubtreeHeight uint8` | `Reserved 0x00` |
| Forward path | zero-copy verbatim | zero-copy verbatim (unchanged) |

The forward path and shard-routing logic are identical. All existing perf baselines in `main/` remain valid as regression comparators.
