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

expected_received=$(( frames / 2 ))
expected_subtree_drop=$(( frames / 2 / 8 ))
expected_forwarded=$(( frames / 2 * 7 / 8 ))

# MLD snooping delivers only groups 0+1 to listener2; verify via received count.
assert_near "listener2 received (shard 0+1 only)" "$(diff_metric "$BEFORE" "$AFTER" listener2 bsl_frames_received_total)"                 "$expected_received"     0.05
assert_near "listener2 dropped subtree_exclude"    "$(diff_metric "$BEFORE" "$AFTER" listener2 'bsl_frames_dropped_total|subtree_exclude')" "$expected_subtree_drop" 0.20
assert_near "listener2 forwarded"                  "$(diff_metric "$BEFORE" "$AFTER" listener2 bsl_frames_forwarded_total)"                 "$expected_forwarded"    0.10

if [[ "$SCENARIO_FAIL" -ne 0 ]]; then
  echo "Scenario 02: FAIL"
  exit 1
fi
echo "Scenario 02: PASS"
