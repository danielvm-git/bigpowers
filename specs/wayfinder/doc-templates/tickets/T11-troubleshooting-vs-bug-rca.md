<!-- wayfinder:grilling -->
# T11 — troubleshooting-vs-bug-rca

**Type:** Grilling (HITL) · **Status:** CLOSED · **Claim:** driver
**Blocks:** collision #4, last of T7's flagged collisions · **Blocked by:** T7 (closed)

## Question

`troubleshooting/` (TGDP pack) vs. `investigate-bug`'s `BUG-*.md` — both are "something went
wrong, here's the fix." Do they collide?

## Resolution

**Same shape as T9 (changelog vs. release-notes) — mechanical/internal record vs. optional curated
layer, not a real duplication.** Verified against the real source (not the `.okf.md` wiki mirror,
which is already marked for deletion):

- **`BUG-*.md`** (`investigate-bug` contract) — Problem → Root Cause Analysis (explicitly told to
  abstract away file paths/line numbers) → TDD Fix Plan (RED-GREEN, `verify:` commands) →
  Acceptance Criteria → Resolution. An internal engineering record, feeds `registry.yaml`, written
  for a contributor fixing the codebase. Confirmed against `BUG-001` (epic-status YAML drift) —
  pure internal process bug, meaningless to an external reader.
- **`troubleshooting/`** (TGDP) — Symptom → Cause → Solution/workaround → links. Written for a
  product user hitting a known, recurring symptom. No code paths, no tests, no RCA.

**Decision:** `BUG-*.md` unchanged — no new template, stays the engineering record every bug gets.
`docs/troubleshooting/` template created but **on the shelf**, same treatment as T9's
release-notes — optional, no CI gate, no per-bug requirement. It doesn't restate a bug's RCA; it
translates the subset of bugs that surface as a real user-facing symptom into what a user actually
needs (not the internals). Bug records stay visible by default under the `specs/`→`docs/`
dissolution (transparency, per the original session framing) — troubleshooting isn't there to hide
anything, only to make the user-relevant subset actionable without reading an RCA.

**Artifact:** [`templates/troubleshooting.md`](../templates/troubleshooting.md).

**T7's collision list is now fully resolved:** README (T8), changelog/release-notes (T9), glossary
(T10), troubleshooting/bug-RCA (T11) — all four closed.