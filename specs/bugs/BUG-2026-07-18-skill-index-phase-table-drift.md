---
bug_id: BUG-2026-07-18-skill-index-phase-table-drift
status: open
severity: high
scope: scripts
title: "SKILL-INDEX.md phase table silently drops 7 skills (TOTAL 72 vs header 79) — no CI guard catches it"
security_impact: NONE
risk_level: medium
parent: e53
files_changed: scripts/generate-skill-index.sh, scripts/golden-g04-selftest.sh, SKILL-INDEX.md, README.md, skills/using-bigpowers/SKILL.md
---

## Problem

**Actual:**
`SKILL-INDEX.md` reports two contradictory totals. The header at line 6 reads
`**Skills:** 79` (correct — matches the filesystem), but the phase-categorization
table sums to `**TOTAL** 72` (line 21) and the footer echoes `**Total: 72 active
skills.**` (line 102). The delta — **7 skills** — are silently absent from every
phase row.

This matters beyond cosmetics: SKILL-INDEX.md is the documented canonical catalog
(`README.md:13`) and the only at-a-glance map of the skill set. A stale phase
table is the direct mechanism behind the recurring "I have a sensation I never use
some skills / I can't tell what I have" pain — the index is lying about coverage.

**The 7 dropped skills** (verified present on disk, present in `skills-lock.json`,
absent from every `phase_of()` branch in `scripts/generate-skill-index.sh:20-37`):

| # | Skill | Proposed phase (needs owner sign-off, §Open questions) |
|---|---|---|
| 1 | `context7-mcp` | Discover |
| 2 | `diagnose-stall` | Verify |
| 3 | `gate-trace` | Verify |
| 4 | `generate-allure-report` | Verify |
| 5 | `harden-vps` | Build |
| 6 | `maintain-wiki` | Sustain |
| 7 | `plan-tests` | Plan |

**Expected:**
`**TOTAL**` row == header count == filesystem count == `skills-lock.json` count.
A drift between them must fail CI, not pass silently.

**Reproduce:**
```bash
cd /Users/danielvm/Developer/bigpowers
bash scripts/generate-skill-index.sh          # regenerates the file; drift persists
grep -E '\*\*Skills:\*\*|\*\*TOTAL\*\*' SKILL-INDEX.md
#   **Skills:** 79
#   | **TOTAL** | **72** |
ls -d skills/*/ | wc -l                        # 79
bash scripts/run-verification-gates.sh         # GOLDEN passes — guard never looks at TOTAL
```

**Prior history:**
Closed issue #40 ("SKILL-INDEX.md missing 3 skills — extract-design, security-review,
visual-dashboard") is the same defect class. It was patched by adding names to
`phase_of()`, which is exactly why it recurred: the structural cause was never
addressed. No `registry.yaml` entry references the phase table, so this regression
has never been formally tracked.

**Security impact:** NONE. Documentation/index drift only.

---

## Root Cause Analysis

### Phase 1 — Reproduce

Regenerating the index from source reproduces `TOTAL 72` while the header prints
`79`. Confirmed on the current tree at commit `a03ada96`.

### Phase 2 — Isolate

Two independent code paths compute the two numbers, and nothing reconciles them:

- **Header count (correct):** `scripts/generate-skill-index.sh:56`
  ```bash
  echo "**Skills:** $(jq '.skills | length' "$LOCKFILE")"
  ```
  Reads the count directly from `skills-lock.json` → **79**.

- **Phase-table total (wrong):** `scripts/generate-skill-index.sh:67-77`
  ```bash
  total=0
  for phase in "${PHASE_ORDER[@]}"; do
    phase_skills=()
    for name in $(jq -r '.skills | keys[]' "$LOCKFILE" | sort); do
      [[ "$(phase_of "$name")" == "$phase" ]] && phase_skills+=("$name")
    done
    total=$((total + count))
  done
  echo "| **TOTAL** | **$total** | |"
  ```
  `total` accumulates only skills for which `phase_of()` returns a non-empty
  string. Any skill absent from `phase_of()` is silently skipped — no error,
  no warning, no log line.

- **The enumeration that drops them:** `scripts/generate-skill-index.sh:20-37`
  ```bash
  phase_of() {
    case "$1" in
      survey-context|research-first|...|audit-plan) echo "Discover" ;;
      ...
    esac
  }
  ```
  None of the 7 skills appears in any `case` branch, so `phase_of` returns empty
  and the table loop drops them.

### Phase 3 — Hypothesize

| # | Hypothesis | Falsification | Verdict |
|---|---|---|---|
| 1 | `skills-lock.json` is missing the 7 skills | `jq -r '.skills \| keys[]' skills-lock.json \| grep -E 'context7-mcp\|diagnose-stall\|gate-trace\|generate-allure-report\|harden-vps\|maintain-wiki\|plan-tests'` returns all 7 | **Rejected** |
| 2 | The 7 directories lack a `SKILL.md` | `find skills -name SKILL.md \| wc -l` = 79; `ls -d skills/*/ \| wc -l` = 79 — both agree | **Rejected** |
| 3 | `SKILL-INDEX.md` was hand-edited and drifted | Header line 3 states `DO NOT EDIT — auto-generated`; deleting and regenerating reproduces `TOTAL 72` | **Rejected** |
| 4 | `phase_of()` omits the 7 skills from its `case` | `grep -E 'context7-mcp\|harden-vps\|...' scripts/generate-skill-index.sh` across lines 20-37 returns nothing | **Confirmed** |
| 5 | CI catches header-vs-lockfile but never header-vs-TOTAL | `scripts/golden-g04-selftest.sh:104-105` parses only `\*\*Skills:\*\* N`; never reads the `\*\*TOTAL\*\*` row | **Confirmed** |

### Phase 4 — Verify

`GOLDEN-2026-07-18.yaml:48-51` records the `skill-catalog` gate exiting 0 /
status `pass` on the same day the phase table is provably wrong. Direct evidence
that the current gate set has a blind spot for this defect class.

**Risk level:** medium. The fix touches a generated artifact plus one CI gate; the
regression risk is contained because the GOLDEN baseline + the new guard (below)
catch any future recurrence.

---

## TDD Fix Plan

**Cycle 1 — Close the CI blind spot first (RED before touching the generator).**
- **RED:** add an assertion to `scripts/golden-g04-selftest.sh` (or a sibling
  `golden-g12-phase-total.sh`) that parses the `**TOTAL**` row and compares it to
  the lockfile count. Run it on the current tree.
- **GREEN:** the assertion fails today with `TOTAL (72) != lockfile (79)`.
- **verify:** `bash scripts/golden-g04-selftest.sh` exits non-zero on the current
  tree. (This is the *desired* failure — it proves the guard now sees the bug.)

**Cycle 2 — Repair the generator (two options; recommend B).**
- **Option A — minimal:** add the 7 skills to their correct `phase_of()` branches.
  Fast, but the defect class survives — the next new skill will drop silently again.
- **Option B — structural (recommended):** delete the hand-maintained `case` and
  read the phase from each `SKILL.md`'s frontmatter (`phase:` field, with the
  existing `model:`/`effort:`/`description:` fields as precedent). This eliminates
  the enumeration entirely and makes the index self-maintaining.
- **RED:** on the chosen branch, `**TOTAL**` row != 79.
- **GREEN:** after regeneration, `**TOTAL**` row == 79 and all 7 skills appear in
  their phase rows.
- **verify:**
  ```bash
  bash scripts/generate-skill-index.sh
  grep '\*\*TOTAL\*\*' SKILL-INDEX.md          # shows 79
  bash scripts/golden-g04-selftest.sh          # passes
  bash scripts/run-verification-gates.sh       # GOLDEN stays green
  ```

**Cycle 3 — Fix the stale doc annotations.**
- **RED:** `grep -rn '72 skills\|70 agent skills' README.md skills/using-bigpowers/SKILL.md`
  matches `README.md:176` ("72 skills") and `using-bigpowers/SKILL.md:12` ("70").
- **GREEN:** both lines cite the canonical count (or, better, reference the
  auto-stamped badge per `README.md:13` so they never drift again).
- **verify:** the grep above returns nothing.

---

## Acceptance Criteria

- [ ] `SKILL-INDEX.md` `**TOTAL**` row == 79 and == `skills-lock.json` count.
- [ ] All 7 dropped skills appear in their correct phase row.
- [ ] A CI guard (extended `golden-g04` or new `golden-g12`) parses the `**TOTAL**`
      row, not just the `**Skills:** N` header.
- [ ] `bash scripts/run-verification-gates.sh` stays green on the fixed tree
      (GOLDEN baseline re-pinned if structural option B is chosen).
- [ ] `README.md:176` and `skills/using-bigpowers/SKILL.md:12` updated.
- [ ] No skill content (`skills/*/SKILL.md` body) is changed.
- [ ] If structural option B is taken, every `SKILL.md` carries a `phase:` field.

---

## Resolution

TBD — awaiting GO. Recommend Cycle 2 Option B (frontmatter-driven phase lookup)
so the `phase_of()` enumeration is deleted and this regression class ends. Option
A only buys time until the next skill is added without a `case` branch.

---

## Out of scope

- Does not change any skill's body, behavior, or `verify:` command.
- Does not change `skills-lock.json` contents.
- Does not change the header count (already correct at 79).
- Does not change the phase *definitions* (Discover/Design/Plan/Build/Verify/
  Release/Sustain) — only the *assignment* of the 7 orphaned skills.
- Does not consolidate or retire any skill (that is a separate epic in the Fable
  wayfinding proposal — the user's "too many skills" concern is larger than this
  bug and deserves its own countable story).

## Open questions

1. **Phase assignment for the 7 skills** — proposed in the table above; needs
   owner sign-off. `gate-trace` / `diagnose-stall` / `generate-allure-report`
   feel firmly Verify; `context7-mcp` (Discover) and `maintain-wiki` (Sustain)
   are the less obvious calls.
2. **Option A vs B** — minimal patch now + structural follow-up, or do the
   structural fix in this bug? B is more work but ends the regression class.
3. **Should the GOLDEN baseline be re-pinned** if Option B changes generated
   output byte-shape? (`generate-skill-index.sh:53-55` notes output is
   byte-stable for drift detection — adding a `phase:` field to every SKILL.md
   does not change SKILL-INDEX.md byte shape, so re-pinning should not be
   required; confirm at execution time.)
