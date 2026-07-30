package scenarios

import (
	"context"
	"testing"
	"time"

	"github.com/lightwebinc/multicast-test/harness/env"
	"github.com/lightwebinc/multicast-test/harness/metrics"
)

// Scenario 75 — NACK repair across an INTER-FABRIC path
//
// Why this exists: every prior NACK proof (scenario 99) ran on an unshaped
// container veth at ~0.8ms RTT. Production, and the current standard ops posture,
// join regions over an interconnect at 60-160ms RTT — three orders of magnitude
// slower. Timing that repairs perfectly on a LAN can misbehave there for a reason
// that never appears unshaped: the retry interval is compared against the round
// trip, not against the loss rate.
//
// The binding constraint is BackoffBase vs RTT. A retry fires BackoffBase after
// the previous NACK. If BackoffBase < RTT, the reply to attempt N is still on the
// wire when attempt N+1 goes out, so the listener burns its MaxRetries budget
// re-asking for frames already in flight and the retry endpoint serves the same
// frame repeatedly. The gap often still gets repaired — by whichever reply lands
// first — but the budget is spent, so a second loss on the repair path is fatal,
// and the wasted NACKs scale with listener count.
//
// This shapes listener ingress to an inter-fabric RTT and compares LAN-tuned
// against inter-fabric-tuned timing, so the shipped defaults are justified by
// measurement on the path they target rather than the path that is convenient.
func TestScenario75_NACKRepairInterFabric(t *testing.T) {
	const (
		owDelayMs = 40  // one-way; ~80ms RTT, a transcontinental interconnect
		jitterMs  = 8   // netem jitter reorders too, exercising forward-jump
		lossPct   = 3.0 // enough gaps to measure a ratio, not enough to swamp
	)

	variants := []struct {
		name  string
		short string
		env   map[string]string
	}{
		{"lan-tuned", "l", map[string]string{
			// What the commercial listener hardcoded before it was configurable.
			"NACK_JITTER_MAX":   "20ms",
			"NACK_BACKOFF_BASE": "200ms", // < RTT: retries outrun replies
			"NACK_BACKOFF_MAX":  "2s",
			"NACK_MAX_RETRIES":  "6",
		}},
		{"interfabric-tuned", "i", map[string]string{
			"NACK_JITTER_MAX":   "50ms",
			"NACK_BACKOFF_BASE": "400ms", // >= 2x RTT: a reply can land first
			"NACK_BACKOFF_MAX":  "5s",
			"NACK_MAX_RETRIES":  "8",
		}},
	}

	ratio := make(map[string]float64)
	nacksPerGap := make(map[string]float64)

	for _, v := range variants {
		prefix := "s75" + v.short
		t.Run(v.name, func(t *testing.T) {
			ctx := context.Background()
			e := retryTopologyNACKEnv(t, prefix, v.env)
			e.StartAll(ctx)
			e.Sleep(4*time.Second, "MLD querier settle")

			for _, sfx := range []string{"1", "2", "3"} {
				l := prefix + "-listener" + sfx
				if err := env.ApplyNetemWAN(ctx, l, owDelayMs, jitterMs, lossPct); err != nil {
					t.Fatalf("netem wan %s: %v", l, err)
				}
				name := l
				// Always restore — a scenario must never leave the rig shaped.
				t.Cleanup(func() { env.RemoveNetemLoss(ctx, name) }) //nolint:errcheck
			}

			beforeL := snapshotListeners(t, e, ctx, prefix)
			beforeR := e.Snapshot(ctx, prefix+"-retry1")

			gen := subtxGenCmd("[fd10::2]:8725")
			gen = append(gen, "-duration", "30s")
			startGenerator(t, ctx, prefix, gen)
			waitGenerator(t, ctx, prefix)

			// Drain must exceed the worst-case retry ladder plus a full RTT, or
			// in-flight repairs get scored as unrecovered and the slower-backoff
			// variant is penalised for the harness's impatience.
			e.Sleep(15*time.Second, "NACK ladder + inter-fabric RTT drain")

			afterL := scrapeListeners(t, e, ctx, prefix)
			afterR := metrics.ScrapeOrFail(t, e.MetricsURL(ctx, prefix+"-retry1"))

			detected := sumListenerDelta(prefix, "bsl_gaps_detected_total", beforeL, afterL)
			suppressed := sumListenerDelta(prefix, "bsl_gaps_suppressed_total", beforeL, afterL)
			deltaR := metrics.DeltaMap(beforeR, afterR)
			nacksRecv := deltaR["bre_nack_requests_total"]
			rtx := deltaR["bre_retransmits_total"]

			if detected == 0 {
				t.Fatalf("no gaps detected at %.1f%% loss — netem not applied?", lossPct)
			}
			r := suppressed / detected
			// NACKs the retry endpoint had to answer per gap. Materially above 1
			// means retries fired before replies could arrive.
			ampl := nacksRecv / detected

			t.Logf("%s: detected=%.0f suppressed=%.0f ratio=%.3f retransmits=%.0f nacks_per_gap=%.2f",
				v.name, detected, suppressed, r, rtx, ampl)

			ratio[v.name] = r
			nacksPerGap[v.name] = ampl

			metrics.AssertGT(t, "gaps suppressed (recovered)", suppressed)
		})
	}

	lan, lanOK := ratio["lan-tuned"]
	itf, itfOK := ratio["interfabric-tuned"]
	if !lanOK || !itfOK {
		t.Skip("a variant did not complete; nothing to compare")
	}
	t.Logf("RTT ~%dms: lan-tuned ratio=%.3f (%.2f nacks/gap) vs interfabric-tuned ratio=%.3f (%.2f nacks/gap)",
		owDelayMs*2, lan, nacksPerGap["lan-tuned"], itf, nacksPerGap["interfabric-tuned"])

	// What this guard asserts is the RECOVERY RATIO, because that is the effect
	// the instrument can actually resolve. An earlier version of this test
	// asserted NACK amplification (nacks-per-gap) instead, on the theory that
	// sub-RTT backoff wastes retries. That assertion was invalid: a single NACK
	// covers a seqnum RANGE while gaps_detected counts individual missing
	// seqnums, so nacks-per-gap sits near 0.29 regardless of timing and the two
	// variants differ only in float noise. It is recorded here so the metric is
	// not mistaken for a discriminator again — it is logged for information only.
	//
	// The ratio difference is the real signal: at inter-fabric RTT, backoff below
	// the round trip abandons gaps that longer backoff still repairs.
	const minGain = 0.02 // guard the direction, not a single run's exact margin
	if itf < lan+minGain {
		t.Errorf("inter-fabric timing (400ms base, 8 retries) should repair a HIGHER share of gaps "+
			"than LAN timing (200ms base, 6 retries) at %dms RTT; got interfabric=%.3f lan=%.3f "+
			"(needed >= %.3f). If this stops holding, re-derive the shipped defaults rather than "+
			"keeping them",
			owDelayMs*2, itf, lan, lan+minGain)
	}
	// Slower backoff is only acceptable if recovery still holds up outright.
	if itf < 0.80 {
		t.Errorf("inter-fabric timing repaired only %.1f%% of gaps at %dms RTT / %.1f%% loss — too low",
			itf*100, owDelayMs*2, lossPct)
	}
}
