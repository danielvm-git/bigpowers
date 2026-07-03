STORY KEY: E40-S05
TITLE:     DORA four keys per story, computed from git/deploy events (lead time, deploy frequency, change failure, restore time) — median/rate aggregation only
TYPE:      Story
PARENT:    e40
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      M

### 1. Business narrative
The e35 "DORA Metrics Extension" planned to extend the hand-written cycle-times.yaml
with DORA four keys, but its premise rested on the unreliable metric e40 is replacing.
This story absorbs e35's intent — tracking the industry-standard DORA four keys
(lead time for changes, deployment frequency, change failure rate, time to restore
service) — but computes them from git/deploy events using the honest, additive
approach. Each story captures raw DORA events; the DORA metric itself is the
cross-story aggregate (lead time / restore = median; deploy freq / change failure
= rate). Never a per-story headline. bcp_per_hour is retired.

### 2. Value statement
As a delivery manager, I want DORA four keys computed from git/deploy events
rather than agent self-reporting, so the delivery metrics are honest and
comparable to industry benchmarks.

### 3. Actors and permissions
- record-cycle-time.sh (system) — computes per-story DORA events.
- Benchmark consumer (system) — aggregates across stories.

### 4. Trigger and preconditions
Trigger: record-cycle-time.sh append invocation (per story).
Precondition: git history and deploy event data available.

### 5. Main flow and business logic
1. Per story: capture raw DORA events.
   - lead_time_for_changes_min: first commit → merge timestamp.
   - deployment_frequency: was this story part of a deploy? (1/0).
   - change_failure: did this change cause a failure/revert? (true/false).
   - time_to_restore_min: if failed, detect → restore timestamp diff.
2. Per story fields are raw inputs — NEVER presented as "this story's DORA score."
3. Cross-story aggregate: lead_time and restore_time aggregate by ⌀ median;
   deploy_frequency and change_failure aggregate by % rate over window.
4. Retire bcp_per_hour: remove from cycle-times.yaml schema and release-branch.

### 6-16. Not applicable (standard metric computation pattern)

### 17. Acceptance criteria
Scenario: DORA events captured per story
  GIVEN record-cycle-time.sh is called at merge
  WHEN the OKF bundle is emitted
  THEN it contains dora.lead_time_for_changes_min, deployment_frequency,
       change_failure, time_to_restore_min fields
  AND grep -q 'lead_time_for_changes|change_failure|time_to_restore|deployment_frequency' 
       specs/templates/story-metrics.okf.md exits 0
  AND bcp_per_hour is retired from release-branch

### 18. Out of scope
- Implementing a real-time DORA dashboard (deferred to visual-dashboard).
- Computing DORA for non-deploy events (e.g., purely internal refactors).

### 19. Open questions
- What counts as a "deploy"? Any merge to main that triggers CI publish.
- What about change failures that are detected days later? Time to restore
  uses the detection timestamp, not the deploy timestamp.

### 20. References
- specs/templates/story-metrics.okf.md (bundle template).
- scripts/record-cycle-time.sh (e40s01).
- Accelerate (Forsgren, Humble, Kim, 2018) — canonical DORA source.
- specs/epics/e35-dora-metrics/ (superseded epic).
