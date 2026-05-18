# Checkpoints: Progress Reporting & Verification Points

**Purpose:** Checkpoints are non-blocking progress reports that verify success, emit status, and ask for confirmation. Unlike gates, checkpoints don't stop execution, but they do require explicit user approval to continue.

**Checkpoint Types (3 categories):**

## 1. Human-Verify Checkpoint

**When:** Requires human judgment to confirm correctness  
**Behavior:** Agent pauses, shows evidence, waits for user to type "continue" or request changes  
**Time to Resolve:** Minutes to hours (user decision)  
**Example:** "slopcheck returned [SUS] for colors@2.0.0 (typosquatter risk detected). Review before continuing?"

**Usage in Orchestration:**
- After **Plan** phase: `slopcheck` tags packages [OK]/[SUS]/[SLOP]; [SUS] packages require human-verify
- After **Build** phase: Coverage drops unexpectedly; manual review needed
- After **Verify** phase: Integration tests fail in unexpected way; need manual judgment

**What Evidence to Show:**
```
slopcheck output: { "package": "colors@2.0.0", "verdict": "SUS", "reason": "typosquatter similar to colors.js" }
Manual action: Type "continue" to proceed anyway, or "block" to remove from recommendations
```

## 2. Integration Checkpoint

**When:** Cross-system verification before release  
**Behavior:** Agent runs integration tests, reports results, pauses if any test fails  
**Time to Resolve:** Minutes (tests run automatically; user decides whether to revert)  
**Example:** "All 6-phase orchestration tests PASS. Integration test results: ✓ Database ✓ Auth ✓ API. Ready to release?"

**Usage in Orchestration:**
- After **Verify** phase: Run full integration suite against staging environment
- Before **Release** phase: Verify backward compatibility with v1.x clients
- After **Release** phase: Smoke tests in production

**What Evidence to Show:**
```
Integration Test Suite Results:
  ✅ Database migrations apply without error (5/5 pass)
  ✅ Authentication flow works end-to-end (3/3 pass)
  ✅ API endpoints respond correctly (12/12 pass)
  ✅ Skill artifacts sync correctly (41/41 pass)
  Result: 21/21 PASS

User approval needed: Type "release" to ship, or "rollback" to revert
```

## 3. Safety Checkpoint

**When:** Destructive or irreversible action, or security-sensitive operation  
**Behavior:** Agent shows what will happen, waits for explicit user confirmation (must type full command, not just "yes")  
**Time to Resolve:** Minutes (user makes security decision)  
**Example:** "About to force-push to origin/main, overwriting 3 commits. This cannot be undone. Type 'force-push origin/main' to confirm:"

**Usage in Orchestration:**
- Before **Release** phase: force-push to main (destructive)
- Before **Build** phase: Drop production database table (destructive)
- Before **Release** phase: Announce breaking change (security concern)

**What Evidence to Show:**
```
Action: Force-push 3 commits to origin/main
This will overwrite:
  - c2ee71b feat(v1.17.0): add guardrails
  - bd9006e feat(audit): implement evidence scripts
  - ba7d054 feat(v1.16.0): add testing mandates

Consequence: History rewritten; upstream PRs may break

Security check: Type the full command to proceed:
  force-push origin/main
(Partial confirmation like "yes" or "ok" will be rejected)
```

---

## Checkpoint State Machine

Each checkpoint goes through this state sequence:

```
RUNNING → VERIFY_NEEDED → AWAITING_USER → APPROVED/REJECTED
  ↓            ↓               ↓              ↓
Test/show   Display      User decides    Continue/
evidence    options      & types         Remediate
```

**State Transitions:**

| State | Action | Next State | Example |
|-------|--------|-----------|---------|
| RUNNING | Execute test/gather evidence | VERIFY_NEEDED | Test finishes with results |
| VERIFY_NEEDED | Show results to user | AWAITING_USER | "slopcheck results: [SUS] for colors@2.0.0" |
| AWAITING_USER | Wait for input | APPROVED / REJECTED | User types "continue" or "block" |
| APPROVED | Record decision, emit evidence | Continue to next phase | Evidence logged in VERIFICATION.md |
| REJECTED | Agent stops, routes to remediation | Call remediation skill or ask user | Revert, fix, retry |

---

## Checkpoint Output Format

**Standard Checkpoint Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CHECKPOINT: [Type] - [Description]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Evidence:
[factual results of test/verification]

Status: [OK] | [WARN] | [NEEDS_REVIEW]

Action Required:
[What user should do or decide]

User Input: [type to proceed]
```

**Example: human-verify Checkpoint**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CHECKPOINT: human-verify - Package Security Verdict
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Evidence:
slopcheck result for @openai/api@4.28.0:
  verdict: [SUS]
  reason: Unusual post-install hook detected
  recommendation: manual review recommended

Status: NEEDS_REVIEW

Action Required:
Review slopcheck verdict above. Type one of:
  "continue"  — proceed with this package anyway
  "block"     — remove from recommendations
  "research"  — pause and let me check the package myself

User Input: ?
```

---

## Checkpoint Truth Table: When to Use

| Checkpoint Type | When | How to Decide | Blocks Progress |
|-----------------|------|---------------|-----------------|
| **human-verify** | Requires human judgment | Judgment can't be automated | ✓ Pause, wait for user |
| **integration** | Cross-system correctness | Tests can be run; user decides on failure | ✓ Pause if tests fail |
| **safety** | Destructive or irreversible | User must explicitly acknowledge risk | ✓ Pause, require full confirmation |

---

## Integration with Gates

**Gates vs. Checkpoints:**

| Aspect | Gate | Checkpoint |
|--------|------|-----------|
| **Purpose** | Block progress until condition met | Report progress; wait for approval |
| **Automation** | Can be fully automated | Always requires human judgment |
| **User Control** | User can override (with evidence) | User decides each time |
| **Blocking** | Hard stop if fails | Reports + pauses for decision |
| **Evidence** | Condition + pass/fail | Detailed results + options |
| **Time** | Seconds to minutes | Minutes to hours |

**Example Flow with Both:**
```
Discover phase:
  ┌─ Transition gate: PROJECT.md exists? [HARD STOP if missing]
  └─ Confirm gate: Problem clear? [Wait for user "yes"]

Plan phase:
  ┌─ Quality gate: request-review ≥94%? [Hard stop if <94%]
  ├─ Safety gate: assess-impact risk? [If high-risk, require acknowledgment]
  └─ human-verify checkpoint: slopcheck [SUS] packages? [Pause, let user decide]

Build phase:
  ├─ Transition gate: PLAN.md executable? [Hard stop if not]
  └─ integration checkpoint: All tests pass? [Report results, wait for approval]

Release phase:
  ├─ Safety checkpoint: Force-push origin/main? [Require full confirmation]
  └─ Confirm gate: Release ready? [Wait for user "yes"]
```

---

## See Also

- gates.md — How gates differ from checkpoints
- orchestration.md — How checkpoints fit into the 6-phase loop
- verify: cd /Users/danielvm/Developer/skills && grep -r "CHECKPOINT\|checkpoint:" . | wc -l
