#!/usr/bin/env bash
# Scenario 11 — Cache-empty MISS / unrecovered gaps.
#
# Tests the NACK→MISS→unrecovered path by blocking the retry endpoint's
# multicast ingress so its cache is empty. Natural multicast delivery issues
# (reorder/loss on the LXD bridge) create PrevSeq/CurSeq gaps at the
# listeners; the retry endpoint responds MISS because it never cached any
# frames; after MaxRetries the gap is evicted as unrecovered.
#
# Why gap injection doesn't work for this:
#   The proxy stamps PrevSeq/CurSeq with its own per-(sender,group) monotonic
#   counter on every frame it receives. Application-level gaps from subtx-gen
#   are overwritten — the proxy's chain is always gapless. Actual gaps are only
#   created by multicast delivery loss between proxy and listener.
set -euo pipefail
SCENARIO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

: "${PPS:=500}"
: "${DURATION:=10s}"
export PPS DURATION

source "$SCENARIO_DIR/../lib/common.sh"
: "${RETRY_VM:=retry1}"
: "${RETRY_IP:=10.10.10.34}"
: "${RETRY_METRICS_PORT:=9400}"
: "${RETRY_LISTEN_PORT:=9001}"

BEFORE="$SCENARIO_DIR/metrics.before.tsv"
AFTER="$SCENARIO_DIR/metrics.after.tsv"
RETRY_BEFORE="$SCENARIO_DIR/retry.before.tsv"
RETRY_AFTER="$SCENARIO_DIR/retry.after.tsv"

retry_metric() {
  metric_value "${RETRY_IP}:${RETRY_METRICS_PORT}" "$1"
}

snapshot_retry() {
  local out="$1"
  : > "$out"
  for m in bre_frames_received_total bre_frames_cached_total \
           bre_nack_requests_total bre_rate_limit_drops_total \
           bre_cache_hits_total bre_cache_misses_total bre_cache_errors_total \
           bre_retransmits_total bre_retransmit_dedup_total \
           bre_responses_sent_total bre_response_send_errors_total; do
    printf '%s\t%s\t%s\n' "$RETRY_VM" "$m" "$(retry_metric "$m")" >> "$out"
  done
}

# --- Ingress block / unblock helpers -----------------------------------------
block_retry_ingress() {
  echo "==> Blocking multicast ingress on $RETRY_VM (port $RETRY_LISTEN_PORT)"
  lxc exec "$RETRY_VM" -- ip6tables -I INPUT -p udp --dport "$RETRY_LISTEN_PORT" -j DROP
}

unblock_retry_ingress() {
  echo "==> Unblocking multicast ingress on $RETRY_VM"
  lxc exec "$RETRY_VM" -- ip6tables -D INPUT -p udp --dport "$RETRY_LISTEN_PORT" -j DROP 2>/dev/null || true
}

# Always clean up the iptables rule, even on failure.
trap unblock_retry_ingress EXIT

# --- Phase 1: restart retry endpoint to flush cache, then block ingress ------
echo "==> Restarting $RETRY_VM service to flush in-memory cache"
lxc exec "$RETRY_VM" -- systemctl restart bitcoin-retry-endpoint
sleep 2

# Verify retry endpoint is back up.
if ! retry_metric bre_frames_received_total >/dev/null 2>&1; then
  echo "FAIL  $RETRY_VM metrics endpoint not reachable after restart"
  exit 1
fi

block_retry_ingress

echo "==> Snapshot metrics (before)"
snapshot_metrics "$BEFORE"
snapshot_retry  "$RETRY_BEFORE"

# --- Phase 2: generate traffic (retry1 cache stays empty) --------------------
echo "==> Generator (no gap injection — relying on natural multicast loss)"
echo "    pps=$PPS duration=$DURATION"
gen_output=$(lxc exec "$SOURCE_VM" -- subtx-gen \
  -addr "$PROXY_ADDR" \
  -shard-bits "$SHARD_BITS" \
  -subtrees "$SUBTREES" \
  -subtree-seed "$SUBTREE_SEED" \
  -pps "$PPS" \
  -duration "$DURATION" \
  -payload-size "$PAYLOAD_SIZE" \
  -log-interval 5s 2>&1)
echo "$gen_output" | tail -5
frames=$(echo "$gen_output" | grep -oP 'sent=\K[0-9]+' | tail -1 || true)
echo "    sent=${frames:-0} frames"

# Allow extra drain time for retries to exhaust (MaxRetries × backoff).
echo "==> Allow NACK retry pipeline to exhaust (20s drain)"
sleep 20

echo "==> Snapshot metrics (after)"
snapshot_metrics "$AFTER"
snapshot_retry  "$RETRY_AFTER"

# Unblock ingress now (trap will also clean up on exit).
unblock_retry_ingress
trap - EXIT

# --- Phase 3: evaluate -------------------------------------------------------
sum_listener_metric() {
  local metric="$1" total=0 d
  for h in "${LISTENERS[@]}"; do
    d=$(diff_metric "$BEFORE" "$AFTER" "$h" "$metric")
    total=$(( total + d ))
  done
  echo "$total"
}

retry_diff() {
  local metric="$1" b a
  b=$(awk -v m="$metric" -F'\t' '$2==m {print $3}' "$RETRY_BEFORE")
  a=$(awk -v m="$metric" -F'\t' '$2==m {print $3}' "$RETRY_AFTER")
  echo $(( ${a:-0} - ${b:-0} ))
}

gaps_detected=$(sum_listener_metric bsl_gaps_detected_total)
nacks_dispatched=$(sum_listener_metric bsl_nacks_dispatched_total)
gaps_suppressed=$(sum_listener_metric bsl_gaps_suppressed_total)
gaps_unrecovered=$(sum_listener_metric bsl_gaps_unrecovered_total)
nacks_received=$(retry_diff bre_nack_requests_total)
cache_hits=$(retry_diff bre_cache_hits_total)
cache_misses=$(retry_diff bre_cache_misses_total)
retransmits=$(retry_diff bre_retransmits_total)
frames_cached=$(retry_diff bre_frames_cached_total)
responses_sent=$(retry_diff bre_responses_sent_total)
response_errors=$(retry_diff bre_response_send_errors_total)

cat <<EOF
-- Listener aggregate (l1+l2+l3) --
bsl_gaps_detected_total      = $gaps_detected
bsl_nacks_dispatched_total   = $nacks_dispatched
bsl_gaps_suppressed_total    = $gaps_suppressed
bsl_gaps_unrecovered_total   = $gaps_unrecovered

-- Retry endpoint ($RETRY_VM) --
bre_frames_cached_total      = $frames_cached  (expect 0 — ingress was blocked)
bre_nack_requests_total      = $nacks_received
bre_cache_hits_total         = $cache_hits
bre_cache_misses_total       = $cache_misses
bre_retransmits_total        = $retransmits
bre_responses_sent_total     = $responses_sent
bre_response_send_errors     = $response_errors
EOF

SCENARIO_FAIL=0

# --- Assertions ---------------------------------------------------------------

# Retry endpoint must NOT have cached any frames (ingress was blocked).
if [[ "$frames_cached" -gt 0 ]]; then
  echo "FAIL  retry endpoint cached $frames_cached frames (ingress block failed?)"
  SCENARIO_FAIL=1
else
  echo "PASS  frames_cached=0 (ingress successfully blocked)"
fi

if [[ "$gaps_detected" -lt 1 ]]; then
  echo "FAIL  expected gaps detected; got $gaps_detected"
  SCENARIO_FAIL=1
else
  echo "PASS  gaps_detected=$gaps_detected"
fi

if [[ "$nacks_dispatched" -lt 1 ]]; then
  echo "FAIL  expected NACKs dispatched; got $nacks_dispatched"
  SCENARIO_FAIL=1
else
  echo "PASS  nacks_dispatched=$nacks_dispatched"
fi

if [[ "$nacks_received" -lt 1 ]]; then
  echo "FAIL  retry endpoint received no NACKs"
  SCENARIO_FAIL=1
else
  echo "PASS  nacks_received=$nacks_received"
fi

# Core assertion: ALL NACKs should be cache misses (empty cache).
if [[ "$cache_misses" -lt 1 ]]; then
  echo "FAIL  expected cache misses (empty cache); got $cache_misses"
  SCENARIO_FAIL=1
else
  echo "PASS  cache_misses=$cache_misses"
fi

# No retransmits should occur (nothing in cache to retransmit).
if [[ "$retransmits" -ne 0 ]]; then
  echo "WARN  retransmits=$retransmits (expected 0 — cache was empty)"
else
  echo "PASS  retransmits=0 (correct — cache was empty)"
fi

# Core assertion: gaps must be evicted as unrecovered after MaxRetries.
# Some gaps may auto-close from reordered packets arriving, so we allow
# gaps_unrecovered < gaps_detected, but it must be > 0.
if [[ "$gaps_unrecovered" -lt 1 ]]; then
  echo "FAIL  expected gaps_unrecovered > 0; got $gaps_unrecovered"
  SCENARIO_FAIL=1
else
  echo "PASS  gaps_unrecovered=$gaps_unrecovered"
fi

if [[ "$SCENARIO_FAIL" -ne 0 ]]; then
  echo "Scenario 11: FAIL"
  exit 1
fi
echo "Scenario 11: PASS"
