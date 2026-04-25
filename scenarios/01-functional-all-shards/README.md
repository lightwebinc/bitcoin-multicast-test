# Scenario 01 — All shards, all subtrees (listener1)

Drive 10 000 frames at 1000 pps over 8 subtree IDs. `listener1` has no
shard or subtree filtering, so every frame must be received and
forwarded to the local sink.

## Expected

Listener-side metric deltas:

| Listener | `bsl_frames_forwarded_total` Δ | Rationale |
|-----------|--------------------------------|--------------------------------|
| listener1 | ≈ 10 000 | no filter |
| listener2 | ≈ 10 000 × ½ × ⅞ ≈ 4 375 | half the shards × 7/8 subtrees |
| listener3 | ≈ 10 000 × ⅛ ≈ 1 250 | only one subtree allowed |

Tolerance: ±5% (allowing for bridge drops and end-of-duration truncation).

## Run

```bash
bash run.sh
```
