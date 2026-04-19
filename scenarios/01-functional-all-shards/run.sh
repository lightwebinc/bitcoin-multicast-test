#!/usr/bin/env bash
set -euo pipefail
SCENARIO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCENARIO_DIR/../lib/common.sh"

BEFORE="$SCENARIO_DIR/metrics.before.tsv"
AFTER="$SCENARIO_DIR/metrics.after.tsv"

echo "==> Snapshot metrics (before)"
snapshot_metrics "$BEFORE"

frames=$(run_generator)

echo "==> Allow egress pipeline to drain"
sleep 2

echo "==> Snapshot metrics (after)"
snapshot_metrics "$AFTER"

expected_l1=$frames
expected_l2=$(( frames * 1 / 2 * 7 / 8 ))
expected_l3=$(( frames * 1 / 8 ))

assert_near "listener1 forwarded"          "$(diff_metric "$BEFORE" "$AFTER" listener1 bsl_frames_forwarded_total)" "$expected_l1" 0.05
assert_near "listener2 forwarded (shard×subtree filter)" "$(diff_metric "$BEFORE" "$AFTER" listener2 bsl_frames_forwarded_total)" "$expected_l2" 0.10
assert_near "listener3 forwarded (subtree-include)"      "$(diff_metric "$BEFORE" "$AFTER" listener3 bsl_frames_forwarded_total)" "$expected_l3" 0.15

if [[ "$SCENARIO_FAIL" -ne 0 ]]; then
  echo "Scenario 01: FAIL"
  exit 1
fi
echo "Scenario 01: PASS"
