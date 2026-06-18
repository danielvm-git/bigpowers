# Orchestration: The 6-Phase Core Loop

**Purpose:** Orchestration defines the prescriptive core loop that guides all projects from conception to release. Every project follows this sequence, with gates and checkpoints enforcing quality at each boundary.

**The 6-Phase Loop:**

```
discover → elaborate → plan → build → verify → release
   ↑         ↑        ↑       ↑       ↑        ↓
   └─────────└────────└───────┴───────┴────────┘
   (Confirm Gate after each phase)
```

See [`orchestration-modes.md`](orchestration-modes.md) for Standard / Fast-Track / Ad-Hoc tradeoffs.  
See [`orchestration-state.md`](orchestration-state.md) for state.yaml tracking details.

---

## Phase 1: Discover (30 min – 3 hours)

**Goal:** Understand the problem space completely before proposing solutions.

**Outputs:** `specs/product/SCOPE_LATEST.yaml`, `specs/state.yaml` (active_epic_id set)

**Activities:** `survey-context` → `grill-me` → document in SCOPE_LATEST.yaml

**Gates:** Transition gate (artifacts exist) + Confirm gate ("Is the problem statement clear?")

**Definition of Done:**
- Problem statement is explicit (not implied)
- Success criteria are measurable (verifiable)
- Constraints documented; existing related code identified; risks surfaced

---

## Phase 2: Elaborate (1–2 hours)

**Goal:** Research solutions and lock design decisions before writing any code.

**Outputs:** `specs/tech-architecture/` (ADRs + decisions locked), `specs/state.yaml` updated

**Activities:** `elaborate-spec` → `grill-me` → lock decisions → document in specs/tech-architecture/

**Gates:** Transition gate (decisions locked) + Quality gate (grill-me review) + Confirm gate

**Red Flags:** "We'll decide this during code" — go back and lock it now.

**Definition of Done:**
- Solution approach documented; key design decisions explicit (why, not just what)
- API contracts defined (if relevant); architectural tradeoffs documented

---

## Phase 3: Plan (1–2 hours)

**Goal:** Write a detailed, verifiable implementation plan before writing any code.

**Outputs:** `specs/epics/eNN-*.yaml` with verify: commands per task

**Activities:** `plan-work` → every step gets a runnable verify: → define success criteria

**Gates:**
- HARD_GATE: `define-success` (if ambiguous)
- HARD_GATE: zoom-out mandate (if modifying existing modules)
- Transition gate (epics shard with verify: commands exists)
- Quality gate: request-review ≥94%; slopcheck: [SUS]/[SLOP] verdicts

**Definition of Done:**
- Every step atomic (one outcome); every step has a runnable verify: command
- Success criteria explicit and measurable; all recommendations [OK] (no [SLOP])

---

## Phase 4: Build (80% of total project time)

**Goal:** Implement the plan, step by step, with no deviations.

**Outputs:** Code/docs/configs per specs/epics/eNN-*.yaml; `specs/state.yaml` handoff block updated

**Activities:** `develop-tdd` → run verify: after each step → document changes in state.yaml handoff

**Gates:** Transition gate (epics shard exists) + integration checkpoint (all verify: commands pass)

**Red Flags:**
- Deviation from specs/epics/eNN-*.yaml — stop and return to Plan
- Scope creep — document for next release, do not act now

**Definition of Done:**
- All tasks executed; all verify: commands PASS; no undocumented deviations
- Boy Scout Rule applied; state.yaml handoff describes what was built

---

## Phase 5: Verify (30 min – 2 hours)

**Goal:** Validate that implementation meets all success criteria.

**Outputs:** `specs/verifications/` (evidence); compliance audit report

**Activities:** `validate-fix` → `audit-code` → `request-review` → collect evidence

**Gates:**
- Quality gate: audit-code PASS (no ✗ items)
- Quality gate: request-review ≥94% (hard stop if lower)
- Quality gate: compliance audit ≥93%
- Integration checkpoint: all tests PASS, coverage ≥95%

**Definition of Done:**
- All success criteria verified; all tests PASS; coverage ≥95%; compliance ≥93%; quality ≥94%

---

## Phase 6: Release (30 min)

**Goal:** Ship to production with confidence and traceability.

**Outputs:** Release tag, release notes, `CHANGELOG.md`, epic shard archived

**Activities:** `git tag -a vX.Y.Z` → write release notes → push → archive epic shard

**Gates:**
- Safety checkpoint: "About to push to main. Type 'release' to confirm:"
- Integration checkpoint: smoke tests in staging pass

**Red Flags:** Verification didn't pass — STOP, return to Phase 5.

**Definition of Done:**
- Tag created; release notes written (features, fixes, breaking changes)
- Pushed to origin/main; epic shard archived to specs/archive/

---

## See Also

- [`orchestration-modes.md`](orchestration-modes.md) — Standard vs Fast-Track vs Ad-Hoc gate behavior
- [`orchestration-state.md`](orchestration-state.md) — state.yaml tracking, example snapshot, resume logic
- [`gates.md`](gates.md) — How gates enforce quality at phase boundaries
- [`checkpoints.md`](checkpoints.md) — How checkpoints report progress
- `verify: bash scripts/validate-doctrine.sh`
