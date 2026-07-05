# Reborn M0 Spine — OKF Envelope & Core Kinds

> **Status:** v0.1 draft — M0 document foundation **complete**
> **Purpose:** Single coherent contract the M0 seed skills author against. Universal OKF envelope + 6 core bodies to run the loop end-to-end.
> **Rule:** Every generated file in `specs/` uses the OKF envelope. Tool-owned kinds (`bcp-count`, `verification-report`, `story-metrics`) are never hand-templated — the producing tool owns the schema.
> **Reborn doc set:** [`REBORN-DOC-INDEX.md`](REBORN-DOC-INDEX.md) · [`reborn-constitution.md`](reborn-constitution.md) (B8, B4, B9) · [`BIGPOWERS-REBORN.md`](BIGPOWERS-REBORN.md) §12–§13

---

## 1. The Universal OKF Envelope (Frontmatter)

Every artifact MUST start with this YAML frontmatter. The `validate-okf` gate checks this structure and provenance.

```yaml
---
okf_kind: <string>           # e.g., "story", "epic", "cockpit-state"
okf_version: "1.0"
generated_by: <string>       # e.g., "skill:elaborate-spec", "human"
generated_at: <iso-8601>
supersedes: <filepath|null>  # if this replaces an older file
commit_range: <string|null>  # e.g., "HEAD~1..HEAD", for traceability
---
```

---

## 2. Cockpit State Schema (`okf_kind: cockpit-state`)

The machine state, read and written by the Kernel (via `bp-yaml`). This is the "real API" from Day 0.

```yaml
---
okf_kind: cockpit-state
okf_version: "1.0"
generated_by: "kernel"
generated_at: 2026-07-04T00:00:00Z
---
active_epic: "specs/epics/e01-reborn/"
active_story: "specs/epics/e01-reborn/story-01.md"
current_movement: "PLAN"          # FRAME, SPECIFY, PLAN, BUILD, PROVE
handoff:
  next_skill: "plan-work"         # The exact next skill to invoke
  reason: "Glossary approved, ready to slice stories"
  context_pointers:               # Explicit pointers to relevant specs
    - "specs/product/glossary.md"
```

---

## 3. Story Contract (`okf_kind: story`)

The durable intent and input to the BCP counter. **Crucially, it contains no gestalt `SIZE` field.** It provides coverage and clarity; the Element Router owns partitioning.

```yaml
---
okf_kind: story
okf_version: "1.0"
generated_by: "skill:elaborate-spec"
generated_at: 2026-07-04T00:00:00Z
---
# Story: [Title]

## 1. Context & Goal
Why are we building this, and what is the desired outcome?

## 2. Target Users / Actors
Who interacts with this slice? (References roles in the Glossary).

## 3. Elements (Data, UI, Interfaces, Logic)
Clear, unambiguous description of the moving parts. 
*Do not pre-partition into BCP dimensions; just describe the system exhaustively.*

## 4. Non-Functional Requirements (NFRs)
Security, performance, and compliance constraints specific to this story.

## 5. Acceptance Criteria (Gherkin)
Scenario: [Name]
  Given [context]
  When [action]
  Then [verifiable outcome]
```

---

## 4. Glossary / Knowledge Bundle (`okf_kind: glossary`)

The domain ground truth. Output of the SPECIFY movement and **input to native `count-bcp`** (B9).

```yaml
---
okf_kind: glossary
okf_version: "1.0"
generated_by: "skill:define-language"
generated_at: 2026-07-04T00:00:00Z
---
# Domain Glossary

## Entities (Dims 6 & 7)
- **[Entity Name]**: [Definition]. (State: New | Existing)

## Roles (Dim 5)
- **[Role Name]**: [Definition]. (Access level / responsibilities)

## Quality & Compliance (Dims 11-13)
- **[Standard/Rule]**: [Definition and system-wide application]
```

---

## 5. Epic Roll-up (`okf_kind: epic`)

The container for roadmap management. It sums the BCP of its constituent stories.

```yaml
---
okf_kind: epic
okf_version: "1.0"
generated_by: "skill:plan-work"
generated_at: 2026-07-04T00:00:00Z
---
# Epic: [Title]

## WSJF & Prioritization
- Value: [1-10]
- Time Criticality: [1-10]
- Risk Reduction: [1-10]
- Job Size (Total BCP): [Sum of stories]
- WSJF Score: [Calculated]

## Stories
| Story | BCP | Status | Risk Tier |
|-------|-----|--------|-----------|
| story-01.md | [from bcp-count] | pending | P1 |
```

---

## 6. Execution Tasks Ledger (`okf_kind: tasks`)

The bridge from spec to execution. An assertion ledger derived from the story's acceptance criteria.

```yaml
---
okf_kind: tasks
okf_version: "1.0"
generated_by: "skill:plan-work"
generated_at: 2026-07-04T00:00:00Z
---
# Execution Ledger for [Story Title]

## Checkpoints
- id: chk-01
  intent: "API returns 200 OK for valid request"
  verify_cmd: "npm run test -- -t 'returns 200'"
  status: "FAILING"  # Transitions: FAILING -> PASSING -> VERIFIED
  
- id: chk-02
  intent: "Invalid payload yields 400 with remediation hint"
  verify_cmd: "npm run test -- -t 'yields 400'"
  status: "FAILING"
```

---

## 7. Tool-owned kinds (do not hand-template)

These OKF bundles are emitted by kernel tools. The methodology references them but does not define their bodies — the producing tool is the schema authority.

| `okf_kind` | Producer | Consumed by |
|---|---|---|
| `bcp-count` | `count-bcp` skill / kernel module | epic roll-up, cockpit metrics (B9) |
| `verification-report` | gate scripts / `verify-work` | Prove movement |
| `story-metrics` | metrics generator | quality ledger (§7) |

See [`BIGPOWERS-REBORN.md`](BIGPOWERS-REBORN.md) §13.5 and [`reborn-constitution.md`](reborn-constitution.md) B8–B9.
