package scenarios

import (
	"context"
	"fmt"
	"strconv"
	"testing"
	"time"

	"github.com/lightwebinc/shard-common/objfmt"
	"github.com/lightwebinc/shard-common/shard"

	"github.com/lightwebinc/multicast-test/harness/metrics"
)

// Scenario 93 — BRC-148 multi-topic submission + in-group topic filter
//
// Two topics chosen to CO-RESIDE in one plane group (found by brute force at
// the default width), so the in-group topic filter — not group election — is
// what separates the listeners. A multi-topic submission emits one frame per
// topic (siblings share a ContentID and must NOT suppress each other — the
// (ContentID, TopicID) pair-dedup regression). listener1 elects topic A,
// listener2 elects topic B, listener3 is an aggregator (explicit group join,
// no topic filter) and receives both.
func TestScenario93_BeefTopicFilter(t *testing.T) {
	ctx := context.Background()

	// Find a colliding pair at the harness default width (4 bits).
	pe, err := shard.NewPlane(0xFF05, shard.DefaultGroupID, 4, shard.DomainBEEF)
	if err != nil {
		t.Fatalf("NewPlane: %v", err)
	}
	topicA := "tm_s93_a"
	tidA := objfmt.TopicID(topicA)
	groupA := pe.GroupIndex(&tidA)
	topicB := ""
	for i := 0; i < 2000; i++ {
		cand := fmt.Sprintf("tm_s93_b%d", i)
		tid := objfmt.TopicID(cand)
		if pe.GroupIndex(&tid) == groupA {
			topicB = cand
			break
		}
	}
	if topicB == "" {
		t.Fatal("no colliding topic found")
	}
	planeRelative := strconv.Itoa(int(groupA - uint32(pe.Base())))

	e, _, _, _ := basicTopology(t, "s93")
	e.PatchEnv("s93-proxy", map[string]string{"TCP_LISTEN_PORT": "9002"})
	e.PatchEnv("s93-listener1", map[string]string{"BEEF_TOPICS": topicA})
	e.PatchEnv("s93-listener2", map[string]string{"BEEF_TOPICS": topicB})
	e.PatchEnv("s93-listener3", map[string]string{"BEEF_GROUPS": planeRelative}) // aggregator
	e.StartAll(ctx)
	e.Sleep(4*time.Second, "MLD querier settle")
	e.Sleep(3*time.Second, "drain residual")

	beforeL := snapshotListeners(t, e, ctx, "s93")
	startGenerator(t, ctx, "s93", []string{
		"beef-gen", "-addr", "[fd10::2]:9002",
		"-topics", topicA + "," + topicB,
		"-count", "20", "-interval", "50ms",
	})
	waitGenerator(t, ctx, "s93")
	e.Sleep(3*time.Second, "pipeline drain")
	afterL := scrapeListeners(t, e, ctx, "s93")

	// 20 submissions × 2 topics = 40 frames on ONE group; every listener
	// receives all 40, the topic filter decides what forwards.
	expects := []struct {
		label   string
		fwd     float64
		dropped float64
	}{
		{"listener1", 20, 20}, // topic A only; B dropped by topic_filter
		{"listener2", 20, 20}, // topic B only
		{"listener3", 40, 0},  // aggregator: absent filter admits all
	}
	for i, exp := range expects {
		delta := metrics.DeltaMap(beforeL[i], afterL[i])
		recv := delta["bsl_frames_received_total"]
		fwd := delta["bsl_frames_forwarded_total"]
		egrErr := delta["bsl_egress_errors_total"]
		dropped := delta["bsl_frames_dropped_total"]
		t.Logf("%s: received=%.0f forwarded=%.0f egrErr=%.0f dropped=%.0f", exp.label, recv, fwd, egrErr, dropped)

		metrics.AssertNear(t, exp.label+" received both sibling emissions", recv, 40, 0.10)
		metrics.AssertNear(t, exp.label+" forwarded per election", fwd+egrErr, exp.fwd, 0.10)
		if exp.dropped > 0 {
			metrics.AssertNear(t, exp.label+" topic-filter drops", dropped, exp.dropped, 0.10)
		}
	}
}
