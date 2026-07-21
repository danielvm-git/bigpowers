<!-- wayfinder:grilling -->
# T16 — cockpit-yaml

**Type:** Grilling (HITL) · **Status:** CLOSED · **Claim:** driver
**Blocks:** the data-OKF group in the survivor set (`state`, `release-plan`, `execution-status`,
`cycle-times`) · **Blocked by:** T1 (doctrine, closed)
**Group ticket:** first data-OKF round — everything before this (README through TEST_PLAN) was
narrative-OKF or Wave 2. `receipts.json` stays parked per T4 ruling #2, not covered here.

## Question

Four cockpit files, none with OKF envelopes today. What does "template" even mean for files no
human ever hand-authors, and which of them actually surface on the published site?

## Resolution

**Not a fill-in-template round — a schema-contract round.** Per bigspec B8: tool-owned data kinds
"are never hand-templated — the producing tool owns the schema." Verified all four live files
(`state.yaml`, `release-plan.yaml`, `execution-status.yaml` — 2776 lines, `cycle-times.yaml` — 483
lines): none carry OKF frontmatter. Each artifact here is a field contract (name/type/required),
not a `{placeholder}` prose template.

**Finding surfaced during investigation:** `cycle-times.yaml` contains a documented past
data-integrity incident — early entries carry `backfill_note: "Fabricated by agent-self-reported
hand-arithmetic (e40 remediation 2026-07-03)"`. **User-confirmed hard requirement:** the Metrics
dashboard must visually distinguish `source: measured` from `source: backfilled`, never blend them
into one headline number silently.

**Disposition (user-confirmed):**

| File | Disposition |
|---|---|
| `state.yaml` | **Internal only** — session-scratchpad content (`handoff.context`, skill timings), not project information. The one deliberate exception in this group, for a different reason than `REVIEW.md` (process noise, not safety). Exception: `active_epic` alone may surface as a derived "in progress" indicator on the Roadmap dashboard. |
| `release-plan.yaml` | Feeds **Roadmap dashboard** — sorted by `build_order`, not raw WSJF (they can legitimately differ). |
| `execution-status.yaml` | Feeds **Epic Status Board** — the exact "which epics are done" view named in this project's original brief. Confirmed as the sole source of truth (a prior bug, `BUG-001`, was epic-status drift between this file and `epic.yaml` — the schema reinforces never re-deriving status from the wrong source). |
| `cycle-times.yaml` | Feeds **Metrics dashboard**, with the measured/backfilled distinction enforced as a hard rendering rule. |

**Artifacts:** [`templates/cockpit-state.md`](../templates/cockpit-state.md),
[`templates/release-plan.md`](../templates/release-plan.md),
[`templates/execution-status.md`](../templates/execution-status.md),
[`templates/cycle-times.md`](../templates/cycle-times.md).