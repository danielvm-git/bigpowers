---
story_id: e24s01
title: "elaborate-spec writes specs/planning-context.yaml"
status: backlog
bcps: 1
type: feat
context: infra
---

# Story e24s01: elaborate-spec → planning-context.yaml

The planning chain (elaborate-spec → scope-work → slice-tasks → plan-work)
loses context at every handoff. Each downstream skill re-derives the same
facts from the conversation. Add a structured output file that persists
the key decisions from elaborate-spec so downstream skills can read rather
than re-derive.

## Acceptance Criteria

- [ ] `elaborate-spec/SKILL.md` documents writing `specs/planning-context.yaml`
- [ ] Output schema includes: feature_name, problem_statement, constraints[], out_of_scope[], key_decisions[]
- [ ] File is written at the end of the elaborate-spec process

## Gherkin Scenarios

```gherkin
Given a user runs elaborate-spec for "add dark mode to dashboard"
When elaborate-spec completes
Then it writes specs/planning-context.yaml with:
  feature_name: "dark mode for dashboard"
  problem_statement: "..."
  constraints: ["must work in TUI", "no new dependencies"]
  out_of_scope: ["mobile", "print styles"]
  key_decisions: [{decision: "CSS variables approach", rationale: "..."}]

Given specs/planning-context.yaml already exists
When elaborate-spec runs
Then it reads the existing file and prompts "Update existing context? [Y/n]"
And merges or overwrites based on user choice
```

## Verification

```bash
grep -c "planning-context\|planning.context" elaborate-spec/SKILL.md | awk '{if($1>=1) print "OK: elaborate-spec outputs context"; else print "FAIL"}'
```

## Implementation Notes

- Schema (minimal): `feature_name`, `problem_statement`, `constraints[]`, `out_of_scope[]`, `key_decisions[]`
- Write at the END of elaborate-spec, after dialogue is complete — not during
- File lives at `specs/planning-context.yaml` (not versioned per-epic; one active context at a time)
- On conflict (file exists from prior feature): prompt to overwrite or append
