# Scenario 99 — NACK / retransmit (PLACEHOLDER)

**Status:** blocked on [`bitcoin-retry-endpoint`](https://github.com/lightwebinc/bitcoin-retry-endpoint)
being implemented. Do not run — the listener's `retry_endpoints` list
is empty in the lab inventory, so NACKs dispatch to nowhere.

## Intended design

Drive `subtx-gen` with gap injection:

```bash
lxc exec source -- subtx-gen \
  -addr '[fd20::2]:9000' \
  -shard-bits 2 -subtrees 8 -subtree-seed 'lax-lab-2026' \
  -pps 1000 -duration 30s \
  -seq-gap-every 500 \
  -seq-gap-size 1 \
  -seq-gap-delay 50ms     # 0 = permanent gap
```

Assertions (all listeners):

| Metric                                    | Expected with `-seq-gap-delay 50ms`      | With permanent gap (`-seq-gap-delay 0`) |
|-------------------------------------------|------------------------------------------|------------------------------------------|
| `bsl_gaps_detected_total`                 | > 0 (roughly `frames / seq_gap_every`)   | same                                     |
| `bsl_nacks_dispatched_total`              | > 0                                      | > 0                                      |
| `bsl_gaps_suppressed_total`               | ≈ `gaps_detected`                        | 0                                        |
| `bsl_nacks_unrecovered_total`             | 0                                        | ≈ `gaps_detected` × NACK_MAX_RETRIES     |

## Activation checklist (once retry-endpoint exists)

1. Deploy `bitcoin-retry-endpoint` to a new VM (e.g. `retry1`).
2. Set `retry_endpoints: "10.10.10.<retry-ip>:9300"` in
   `ansible/listener-hosts.yml` group vars.
3. Re-run `ansible/run-deploy.sh` and `lab/09-metrics-update.sh`.
4. Move this placeholder into a real `run.sh` using the generator command
   above, with the four assertions listed.
