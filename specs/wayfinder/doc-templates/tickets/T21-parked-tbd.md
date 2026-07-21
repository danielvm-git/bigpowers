<!-- wayfinder:grilling -->
# T21 — parked-tbd

**Type:** Grilling (HITL) · **Status:** CLOSED · **Claim:** driver
**Blocks:** the last deferred items in the survivor set · **Blocked by:** T4 ruling #4 (parked),
T16 ruling #2 (receipts shape deferred)

## Question

Three items deliberately deferred earlier: `planning-status.yaml`, `receipts.json`'s exact shape,
and the unenumerated `verifications/reports/**`/`falsification/**`/`security/epics/**` contents.
Resolve all three now that they can actually be checked.

## Resolution

**`planning-status.yaml` — same disposition as `state.yaml` (T16), no new artifact.** Checked the
real file and `run-planning`'s contract: a per-epic checklist of which discover-phase skills have
completed (`survey-context`, `scope-work`, etc., each `done`/`optional`/`todo`). Session/workflow
bookkeeping, not project information — inherits T16's ruling directly rather than needing its own.

**`receipts.json` — data-OKF schema (T16's pattern), the flagship compliance/gate-results
aggregate.** Confirmed real shape: one key per evidence category (`compliance`, `golden_suite`,
`metrics`, `traceability`), each with `value`/`generated_at`/`source`/`command`. **Same
data-integrity rule as `cycle-times.md`:** `source: measured | absent` must render honestly on the
dashboard — an absent category shows as visibly missing, never silently dropped.

**`verifications/reports/*.md` (audit run logs) — stay internal, feed the receipts aggregate,
no template.** Confirmed real shape: timestamped, diagnostic, one per compliance run, with raw
PASS/FAIL detail per assertion. Same pattern as `REVIEW.md`/`THREAT_MODEL.md`: raw evidence stays
internal; only the derived aggregate (`receipts.json`'s `compliance` section) surfaces. Publishing
each individually would be pure noise — likely hundreds of near-duplicate files over a project's
life.

**`security/epics/*/THREAT_MODEL.md` — same disclosure class as `REVIEW.md` (T14), no template.**
Checked a real one (`e32`): names specific unmitigated attack surfaces ("Malicious client could
pass `../../etc/passwd` if not normalized... Mitigation: [required, not yet confirmed
implemented]") at build-epic Step 0, *before* the code exists. Worse to publish than `REVIEW.md` —
a live roadmap of gaps. Never auto-published, confirming rather than reopening T14's ruling.

**`falsification/harness-falsification.feature` — resolves a category left dangling in the fog:
`.feature` files were never actually ticketed despite being referenced since the start of this
map.** All `.feature` files (compliance self-tests like `cleancode.feature`, `karpathy.feature`,
`pocock.feature`) assert whether **bigpowers itself** follows its own philosophical pillars — a
consumer app has no equivalent "does this app follow Akita/Pocock" self-test. Same exclusion class
as the skill catalog (T4 ruling #1): bigpowers-internal only, out of scope for the consumer-app
template set, no template.

**Artifact:** [`templates/receipts.md`](../templates/receipts.md) — the only genuinely new one;
everything else in this round resolved to "correctly excluded" or "inherits an existing ruling,"
which is a legitimate outcome, not a gap.

**This closes the map's entire fog list.** Every category from the original "Not yet specified"
section — cockpit YAML, product intent, delivery, architecture, quality, analysis, authoring, and
now the parked items — has a verdict.