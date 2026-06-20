---
story_id: e17s01
title: "craft-skill: validate-contracts — compare data schemas across system boundaries"
status: backlog
bcps: 3
type: feat
context: infra
---

# Story e17s01: validate-contracts skill

Create a `validate-contracts` skill that catches data divergence between front-end,
back-end, and external API boundaries before deploy.

Prevents insidious data bugs — 2 of 8 bugs in big-bolao were data sync issues
(e.g., FLAGS dictionary missing keys that tournament fixtures reference).

## Acceptance Criteria

- [ ] Skill file: `validate-contracts/SKILL.md` with verb-noun naming
- [ ] Contract files live in `specs/contracts/` (documented pattern)
- [ ] Supports JSON Schema and simple key-set comparison
- [ ] Verification: `bash scripts/validate-contracts.sh` returns non-zero on divergence
- [ ] Skill is listed in SKILL-INDEX.md

## Gherkin Scenarios

```gherkin
Given a FLAGS dictionary in the front-end with 200+ country entries
And tournament fixtures from the API that reference country names
When validate-contracts runs
Then every country name in fixtures MUST have a corresponding FLAGS entry
And any missing entries are reported with the country name and expected key
And the exit code is non-zero if divergence exists

Given a BigBase API endpoint /api/jogos
And an expected schema in specs/contracts/jogos.schema.yaml
When validate-contracts runs
Then the live response MUST conform to the schema
And type mismatches are reported with field path and expected vs actual types
```

## Verification

```bash
test -f validate-contracts/SKILL.md && echo "OK: skill file exists" || echo "FAIL: no skill file"
grep -q "name: validate-contracts" validate-contracts/SKILL.md && echo "OK: frontmatter" || echo "FAIL: frontmatter"
grep -qi "schema\|contract\|divergence\|diff" validate-contracts/SKILL.md && echo "OK: contract semantics" || echo "FAIL: missing semantics"
grep -q "validate-contracts" SKILL-INDEX.md && echo "OK: in SKILL-INDEX" || echo "FAIL: not indexed"
```

## Implementation Notes

- Define contract files in `specs/contracts/` (JSON Schema or YAML)
- Compare front-end constants against back-end data sources
- Validate API response shapes against expected schemas
- Flag missing keys, type mismatches, and extra fields
- Integrate as a pre-deploy gate in deploy skill
- Generate a diff report (added/removed/changed keys)
