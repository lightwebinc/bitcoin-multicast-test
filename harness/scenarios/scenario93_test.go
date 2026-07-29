package scenarios

import (
	"context"
	"testing"
	"time"

	"github.com/lightwebinc/multicast-test/harness/env"
	"github.com/lightwebinc/multicast-test/harness/metrics"
)

// Scenario 93 — fragmented BEEF under loss: fragment-level NACK recovery
//
// The missing composition of 95 (BEEF fragmentation) and 96 (BEEF NACK
// recovery): large objects leave the proxy as BRC-130 fragments
// (OrigFrameVer 0x09), 10% netem loss drops individual FRAGMENTS on the
// listeners, and recovery must operate at fragment granularity — the
// listeners feed every fragment to the gap tracker, NACK the missing SeqNums
// with a ZERO SubtreeID (the V9 flow contract, blocker B1), and the
// BEEF-enabled retry serves the cached fragments back. Reassembly then
// completes with the ContentID (SHA-256d) check armed, so a recovered object
// delivered with wrong bytes would fail loudly rather than pass silently.
//
// Tail losses (final fragments of the train, with nothing behind them to
// expose the gap) time out rather than recover — same as scenario 34 — so
// completion asserts near-total delivery, not exactness, while every
// recovery counter must move.
func TestScenario93_BeefFragmentLossRecovery(t *testing.T) {
	ctx := context.Background()
	e, _ := retryTopology(t, "s93")
	e.PatchEnv("s93-proxy", map[string]string{
		"TCP_LISTEN_PORT": "9002",
		"FRAG_MTU":        "1280",
	})
	for _, l := range []string{"s93-listener1", "s93-listener2", "s93-listener3"} {
		e.PatchEnv(l, map[string]string{
			"BEEF_TOPICS":         "tm_s93",
			"VERIFY_PAYLOAD_HASH": "true", // arms the reassembly SHA-256d (= ContentID) check
		})
	}
	// The retry must join the band and cache V3 fragments (OrigFrameVer 0x09)
	// or every fragment NACK dies unanswered.
	e.PatchEnv("s93-retry1", map[string]string{"BEEF_ENABLED": "true"})
	e.StartAll(ctx)
	e.Sleep(4*time.Second, "MLD querier settle")

	for _, l := range []string{"s93-listener1", "s93-listener2", "s93-listener3"} {
		if err := env.ApplyNetemLoss(ctx, l, 10.0); err != nil {
			t.Fatalf("netem loss %s: %v", l, err)
		}
		t.Cleanup(func() { env.RemoveNetemLoss(ctx, l) }) //nolint:errcheck
	}

	const objects = 40.0
	beforeL := snapshotListeners(t, e, ctx, "s93")
	beforeR := e.Snapshot(ctx, "s93-retry1")

	// 4 KiB objects at FRAG_MTU 1280 → 4 fragments each; 40 objects ≈ 160
	// fragments per listener, so 10% loss yields dozens of fragment gaps per
	// run — zero recoveries can never pass by luck.
	startGenerator(t, ctx, "s93", []string{
		"beef-gen", "-addr", "[fd10::2]:9002", "-topics", "tm_s93",
		"-object-bytes", "4096", "-count", "40", "-interval", "80ms",
	})
	waitGenerator(t, ctx, "s93")
	e.Sleep(12*time.Second, "fragment NACK pipeline drain")

	afterL := scrapeListeners(t, e, ctx, "s93")
	afterR := metrics.ScrapeOrFail(t, e.MetricsURL(ctx, "s93-retry1"))

	gaps := sumListenerDelta("s93", "bsl_gaps_detected_total", beforeL, afterL)
	nacks := sumListenerDelta("s93", "bsl_nacks_dispatched_total", beforeL, afterL)
	completed := sumListenerDelta("s93", "bsl_reassembly_completed_total", beforeL, afterL)
	mismatch := sumListenerDelta("s93", "bsl_reassembly_hash_mismatch_total", beforeL, afterL)

	deltaR := metrics.DeltaMap(beforeR, afterR)
	retransmits := deltaR["bre_retransmits_total"]
	cached := deltaR["bre_frames_cached_total"]

	t.Logf("listeners: completed=%.0f mismatch=%.0f gaps=%.0f nacks=%.0f",
		completed, mismatch, gaps, nacks)
	t.Logf("retry: cached=%.0f retransmits=%.0f", cached, retransmits)

	// The recovery machinery must move at FRAGMENT granularity...
	metrics.AssertGT(t, "fragment gaps detected under loss", gaps)
	metrics.AssertGT(t, "fragment NACKs dispatched", nacks)
	metrics.AssertGT(t, "retry cached band frames", cached)
	metrics.AssertGT(t, "retry retransmits served", retransmits)
	// ...and convert into COMPLETED objects: at 10% fragment loss with no
	// recovery, P(all 4 fragments arrive) ≈ 0.9⁴ ≈ 0.656, so ~34% of
	// reassemblies would fail per listener — ≥90% of the 3×40 expected
	// completions is unreachable without working retransmission, while still
	// tolerating tail-loss timeouts.
	metrics.AssertNear(t, "objects reassembled across listeners", completed, 3*objects, 0.10)
	metrics.AssertZero(t, "recovered bytes verify (ContentID)", mismatch)
}
