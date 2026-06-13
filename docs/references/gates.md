# Gates: Enforcement Points in the 6-Phase Core Loop

**Purpose:** Gates are decision points that block forward progress if conditions aren't met. Every gate has a clear, measurable pass/fail criterion.

**Gate Types (4 categories):**

## 1. Confirm Gate

**When:** User confirmation required before proceeding  
**Pass Condition:** User explicitly approves in chat  
**Fail Condition:** User rejects or asks for clarification  
**Example:** "Plan looks good?" → user types "yes, proceed"

**Usage in Orchestration:**
- End of **Discover** phase: "Is the problem statement clear? Should I elaborate?"
- End of **Elaborate** phase: "Are the design decisions locked? Should I plan?"
- End of **Plan** phase: "Is the plan executable? Should I build?"

## 2. Quality Gate

**When:** Output quality must meet threshold before proceeding  
**Pass Condition:** Measurable quality score ≥ threshold (e.g., 94% from request-review). The score is the SCORE value emitted by `npm run compliance` (scripts/audit-compliance.sh): SCORE = passing Gherkin scenarios / total scenarios × 100; 94% is the pass threshold.  
**Fail Condition:** Quality score < threshold; routes to remediation  
**Example:** request-review returns 89/100 → must fix before advancing

**Usage in Orchestration:**
- After **Plan** phase: `request-review` scores plan; must pass 94% threshold
- After **Build** phase: `audit-code` + `request-review` verify code quality
- After **Verify** phase: Compliance audit scores ≥ 93%

## 3. Safety Gate

**When:** Risky or irreversible changes require explicit acknowledgment  
**Pass Condition:** User explicitly acknowledges the risk  
**Fail Condition:** User requests alternative approach  
**Example:** "This will delete 50 lines of production code. Proceed?" → user must type "yes, confirmed"

**Usage in Orchestration:**
- Before **Build** phase: `assess-impact` flags high-risk changes; requires user sign-off
- Before **Verify** phase: If coverage drops, requires decision to proceed or fix
- Before **Release** phase: Force-push or major refactor requires acknowledgment

## 4. Transition Gate

**When:** Phase-boundary gate; ensures handoff artifact exists and is valid  
**Pass Condition:** Required YAML artifact exists + has minimum structure  
**Fail Condition:** Artifact missing or incomplete  
**Example:** Check that an `specs/epics/eNN-*.yaml` shard exists before proceeding to Build phase

**Usage in Orchestration:**
- Discover → Elaborate: `specs/state.yaml` (`active_epic_id`) + `specs/product/SCOPE_LATEST.yaml` must exist
- Elaborate → Plan: `specs/product/SCOPE_LATEST.yaml` with locked decisions must exist
- Plan → Build: `specs/epics/eNN-*.yaml` shard with `verify:` commands per task must exist
- Build → Verify: `specs/state.yaml` `handoff` block describing what was built must exist
- Verify → Release: `specs/verifications/` results + all `verify:` commands green must exist

---

## Gate Implementation Patterns

### Pattern 1: Hard Gate (Non-Negotiable)

```
Condition fails → Agent STOPS, asks user to fix
Example: "specs/epics/eNN-*.yaml shard not found. Create it with plan-work before proceeding."
```

**Hard gates in Bigpowers 2.0:**
- HARD_GATE: define-success (plan-work)
- HARD_GATE: zoom-out mandate (plan-work, for existing modules)
- HARD_GATE: quality threshold 94% (request-review)
- HARD_GATE: loop-until-green (validate-fix)

### Pattern 2: Soft Gate (Negotiable with Rationale)

```
Condition fails → Agent WARNS + offers remediation path
Example: "Coverage <95%. You can proceed [fast-track] but quality risk increases."
```

**Soft gates in Bigpowers 2.0:**
- SOFT_GATE: assess-impact risk classification (warns if high-risk, allows override)
- SOFT_GATE: slopcheck [SUS] verdict (pauses for human review, allows override)

### Pattern 3: Checkpoint (Progress Milestone)

```
Condition met → Agent REPORTS progress + asks confirmation
Example: "All 6 compliance audits PASS. Ready to release?"
```

**Checkpoints in Bigpowers 2.0:**
- CHECKPOINT: All tests pass
- CHECKPOINT: All audits pass (Akita/Karpathy/Clean Code)
- CHECKPOINT: All verify commands run successfully

---

## Gate Truth Table

| Gate Type | When | Pass | Fail | User Control |
|-----------|------|------|------|--------------|
| **Confirm** | Human decision required | User approves | User rejects/asks for changes | Full control |
| **Quality** | Output must meet threshold | Score ≥ threshold | Score < threshold | Can override with evidence |
| **Safety** | Risky operation | User acknowledges risk | User rejects | Can override with explicit yes |
| **Transition** | Artifact must exist | File exists + valid | File missing/incomplete | Hard stop, must create |

---

## Mode Behavior: How Gates Change by Mode

### Standard Mode (Enforce All Gates)
- All Confirm gates → require user approval
- All Quality gates → hard stop if <threshold
- All Safety gates → require explicit risk acknowledgment
- All Transition gates → hard stop if artifact missing
- **Result:** Zero scope creep, max quality

### Fast-Track Mode (Skip Negotiable Gates)
- Confirm gates → skip if code exists (discover) or tests pass (verify)
- Quality gates → skip if score ≥ 90% (lenient)
- Safety gates → auto-approve if risk < threshold
- Transition gates → remain hard stop
- **Result:** 30% faster, acceptable quality tradeoff (90% vs. 94%)

### Ad-Hoc Mode (Legacy, Warnings Only)
- All gates → emit warnings, don't block
- User can skip any step
- **Result:** Fastest, highest risk, lowest quality (78% success vs. 93%)

---

## See Also

- checkpoints.md — Progress reporting milestones
- orchestration.md — How gates fit into the 6-phase loop
- verify: cd /Users/danielvm/Developer/skills && grep -r "HARD.GATE\|Quality.*gate\|Safety.*gate" . | wc -l
