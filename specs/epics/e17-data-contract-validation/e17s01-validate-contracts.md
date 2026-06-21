---
story_id: e17s01
title: "craft-skill: validate-contracts — assert data shape consistency across system boundaries"
status: backlog
bcps: 3
type: feat
context: infra
---

# Story e17s01: validate-contracts skill

Create a `validate-contracts` skill that catches data structure divergence between
system boundaries — front-end vs back-end, API responses vs expected schemas,
config files vs code assumptions, migrations vs target shape.

Prevents silent data corruption that manifests as confusing UI bugs, API errors,
or data-loss in production. Common failure modes that this skill detects:

- **Key drift:** Translation keys added in one layer but not another
- **Shape mismatch:** API returns `{user_name}` but front-end expects `{username}`
- **Enum divergence:** A status enum gets a new value in the DB but not in the API types
- **Schema regression:** A deploy changes an API response shape without updating consumers
- **Config asymmetry:** `.env.example` promises a variable that the code no longer reads

## Contract types

The skill supports three modes of contract validation:

### 1. API Response Contracts (JSON Schema)

Define expected API response shapes in `specs/contracts/` using JSON Schema or YAML,
then validate live endpoints against them:

```yaml
# specs/contracts/users.schema.yaml
endpoint: /api/users
method: GET
expected:
  type: object
  required: [id, name, email]
  properties:
    id: { type: number }
    name: { type: string }
    email: { type: string, format: email }
```

```bash
validate-contracts --schema specs/contracts/users.schema.yaml --url https://api.example.com/users
# → PASS: /api/users matches expected schema (3/3 fields present, types match)
```

### 2. Key-Set Contracts

Assert that two data sources have the same set of keys. Useful for translation files,
enum definitions, config keys, and any parallel data structure:

```yaml
# specs/contracts/i18n-keys.yaml
left: src/frontend/locales/en.json     # reference source
right: src/backend/messages/en.json     # target to validate
type: key-set
require: subset                         # all right-side keys must exist in left
```

```bash
validate-contracts --key-set specs/contracts/i18n-keys.yaml
# → "added: 2 keys found in right but not left: ['welcome_back', 'logout']"
# → "missing: 1 key in left but not right: ['dashboard']"
```

### 3. Data Shape Contracts

Validate that a data file (CSV, JSON, YAML) matches an expected column/field schema.
Useful for data migrations, exports, and generated manifests:

```yaml
# specs/contracts/migration-output.yaml
file: data/users-export.json
type: shape
fields:
  - name: user_id
    type: number
    required: true
  - name: full_name
    type: string
    required: true
  - name: created_at
    type: string
    format: date-time
    required: false
```

```bash
validate-contracts --shape specs/contracts/migration-output.yaml
# → "PASS: 3/3 fields match, 1000 rows OK"
# → "WARN: field 'full_name' has 12 null values (1.2%)"
```

## Integration

- Can run standalone: `bash scripts/validate-contracts.sh [contract-file]`
- Integrates as a pre-deploy gate in the `deploy` skill
- Integrates as a pre-migration check in the `validate-fix` skill
- Output is machine-parseable (JSON lines) for CI pipeline integration

## Gherkin Scenarios

```gherkin
Given an API endpoint /api/users
And a contract file specs/contracts/users.schema.yaml defines {id, name, email}
When validate-contracts --schema specs/contracts/users.schema.yaml --url http://localhost/users runs
Then the live response is validated against the schema
And PASS is reported if all required fields exist with correct types
And FAIL with field paths if a field is missing or type-mismatched
And the exit code is 0 on pass, non-zero on failure

Given a front-end locale file with 150 translation keys
And a back-end locale file with 148 keys
When validate-contracts --key-set compares them
Then it reports 2 keys missing in back-end: ['settings.privacy', 'help.faq']
And the exit code is non-zero

Given a data migration produces a 5000-row JSON file
And a shape contract expects columns: user_id (number), name (string), email (string)
When validate-contracts --shape validates the file
Then it reports column-level type conformance across all rows
And flags rows that fail type checks with line numbers
```

## Acceptance Criteria

- [ ] Skill file: `validate-contracts/SKILL.md` with verb-noun naming
- [ ] Supports three contract modes: schema, key-set, shape
- [ ] Contract files live in `specs/contracts/` (documented pattern)
- [ ] Verification: `bash scripts/validate-contracts.sh` returns non-zero on divergence
- [ ] Machine-parseable output (JSON Lines) for CI
- [ ] Skill is listed in SKILL-INDEX.md

## Verification

```bash
test -f validate-contracts/SKILL.md && echo "OK: skill file exists" || echo "FAIL: no skill file"
grep -q "name: validate-contracts" validate-contracts/SKILL.md && echo "OK: frontmatter" || echo "FAIL: frontmatter"
grep -qi "schema\|contract\|key.set\|data.shape\|divergence\|diff" validate-contracts/SKILL.md && echo "OK: contract semantics" || echo "FAIL: missing semantics"
grep -q "validate-contracts" SKILL-INDEX.md && echo "OK: in SKILL-INDEX" || echo "FAIL: not indexed"
```

## Implementation Notes

- Contract files live in `specs/contracts/` — documented convention
- Each contract type (schema, key-set, shape) is a separate subcommand or mode
- JSON Schema validation uses a lightweight library or inline jsonschema checker
- Key-set comparison is straightforward: parse both sides, compute diff
- Shape validation reads file header or first N rows, matches against expected types
- Output format: JSON Lines (one event per line) for CI parsing + human-readable summary
- Pre-deploy gate integration: `deploy` skill runs `validate-contracts` before smoke-test
