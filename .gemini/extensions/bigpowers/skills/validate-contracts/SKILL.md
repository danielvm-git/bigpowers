---
name: validate-contracts
description: "\"Assert data shape consistency across system boundaries — live API responses against JSON Schema, key-set comparison across layers, data shape validation for migrations and exports. Catches silent data corruption before deploy.\""
---


# Validate Contracts

> **HARD GATE** — Do NOT deploy or migrate data without running `validate-contracts` first. Silent data divergence between system boundaries causes the hardest-to-debug production bugs.
>
> **HARD GATE** — Contract files MUST be version-controlled alongside code. Outdated contracts are worse than no contracts. If a contract hasn't been reviewed in 30 days, flag it as stale.

Validate that data structures stay in sync across system boundaries — front-end vs
back-end, API responses vs expected schemas, config files vs code assumptions,
migration output vs target shape.

## Contract types

Three modes of validation:

| Mode | What it catches | When to use |
|------|----------------|-------------|
| **Schema** | API response shape mismatches (missing field, wrong type) | Before every deploy, after API changes |
| **Key-set** | Missing/unexpected keys across two data sources | Translation files, configs, enum definitions |
| **Shape** | Column type or format violations in data files | After migrations, before consuming exports |

## Contract file convention

All contract files live in `specs/contracts/` and use YAML:

See [REFERENCE.md](REFERENCE.md) for examples.

### 1. API Response Contracts (`--schema`)

Define expected API response shapes and validate live endpoints against them:

See [REFERENCE.md](REFERENCE.md) for examples.

Usage:

```bash
validate-contracts --schema specs/contracts/users.schema.yaml --url https://api.example.com/users
# → PASS: /api/users matches expected schema (3/3 fields, types ok)
# → FAIL: /api/users — field 'email' has type null (expected string)
```

### 2. Key-Set Contracts (`--key-set`)

Assert that two data sources share a consistent set of keys:

See [REFERENCE.md](REFERENCE.md) for examples.

Usage:

See [REFERENCE.md](REFERENCE.md) for examples.

### 3. Data Shape Contracts (`--shape`)

Validate that a data file matches expected column types and constraints:

See [REFERENCE.md](REFERENCE.md) for examples.

Usage:

See [REFERENCE.md](REFERENCE.md) for examples.

## Process

### 1. Define contract

Create a YAML file in `specs/contracts/` following the schema for the mode.

### 2. Run validation

```bash
bash scripts/validate-contracts.sh <contract-file>
```

The runner auto-detects the contract type from the file content (presence of `schema:`,
`sources:`, or `file:` + `fields:` keys).

### 3. Read the report

Output is JSON Lines (one event per line) plus a human-readable summary:

```
{"event":"pass","check":"users.schema","detail":"3/3 fields match types"}
{"event":"warn","check":"users.schema","detail":"field 'avatar' has format: uri (unexpected)"}
{"event":"fail","check":"i18n-keys","detail":"missing: 2 keys in target"}
```

Final summary:

```
=== Validate Contracts Summary ===
Schema: 3/3 pass | Key-set: 1/1 fail | Shape: 2/2 pass
FAILED: 1 contract has divergence
```

### 4. Fix divergence

- **Missing keys** → add to target source
- **Type mismatches** → update schema or fix producer
- **Shape violations** → fix migration or consumer

### 5. Re-validate

```bash
bash scripts/validate-contracts.sh <contract-file>
# → All pass → ready to deploy
```

---

# Validate Contracts — Reference

## Integration

- **Pre-deploy gate:** The `deploy` skill runs `validate-contracts` before smoke-test.
- **CI pipeline:** JSON Lines output is CI-friendly; pipe to `jq` for assertions.
- **Pre-migration:** Run `validate-contracts --shape` before consuming migration output.


---

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CONTRACTS_DIR` | `specs/contracts/` | Directory containing contract YAML files |
| `VALIDATE_ALL` | `false` | If true, run all contracts in the directory |
| `STRICT_MODE` | `false` | Treat warnings as failures |
| `OUTPUT_FORMAT` | `text` | `text` or `json` |


---

## Verification

→ verify: `test -f validate-contracts/SKILL.md && grep -q 'name: validate-contracts' validate-contracts/SKILL.md && echo OK`
→ verify: `grep -qi 'specs/contracts\|JSON Schema\|key.set\|data.shape' validate-contracts/SKILL.md && echo OK`
→ verify: `grep -ci 'divergence\|missing key\|type mismatch\|diff\|conforms\|column' validate-contracts/SKILL.md | awk '{if($1>=3) print "OK"; else print "FAIL"}'`
→ verify: `grep -ci 'JSON Lines\|machine.parse\|CI\|deploy.*gate\|pre.deploy' validate-contracts/SKILL.md | awk '{if($1>=2) print "OK"; else print "FAIL"}'`
→ verify: `grep -q 'validate-contracts' SKILL-INDEX.md && echo OK`

---

## Reference block 1

```yaml
# specs/contracts/users.schema.yaml
endpoint: /api/users
method: GET
schema:
  type: object
  required: [id, name, email]
  properties:
    id: { type: number }
    name: { type: string }
    email: { type: string, format: email }
```

---

## Reference block 2

```yaml
# specs/contracts/migration-output.yaml
file: data/users-export.json
format: json
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

---

## Example 1

```
specs/contracts/
├── users.schema.yaml        # API response schema
├── i18n-keys.yaml           # Key-set comparison
├── migration-output.yaml    # Data shape contract
└── README.md                # Local conventions
```

---

## Example 2

```yaml
# specs/contracts/users.schema.yaml
endpoint: /api/users
method: GET
schema:
  type: object
  required: [id, name, email]
  properties:
    id: { type: number }
    name: { type: string }
    email: { type: string, format: email }
```

---

## Example 3

```yaml
# specs/contracts/i18n-keys.yaml
sources:
  reference: src/frontend/locales/en.json
  target: src/backend/messages/en.json
mode: subset      # all target keys must exist in reference
```

---

## Example 4

```bash
validate-contracts --key-set specs/contracts/i18n-keys.yaml
# → missing: 2 keys in reference not found in target: ['settings.privacy', 'help.faq']
# → added: 1 key in target not in reference: ['deprecated.field']
# → exit 1 (divergence)
```

---

## Example 5

```yaml
# specs/contracts/migration-output.yaml
file: data/users-export.json
format: json
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

---

## Example 6

```bash
validate-contracts --shape specs/contracts/migration-output.yaml
# → PASS: 3/3 fields validated, 5000 rows OK
# → WARN: field 'full_name' has 12 null values (0.24%)
# → FAIL: field 'user_id' has 3 rows with type string (expected number)
```

---

## Integration

- **Pre-deploy gate:** The `deploy` skill runs `validate-contracts` before smoke-test.
- **CI pipeline:** JSON Lines output is CI-friendly; pipe to `jq` for assertions.
- **Pre-migration:** Run `validate-contracts --shape` before consuming migration output.


---

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CONTRACTS_DIR` | `specs/contracts/` | Directory containing contract YAML files |
| `VALIDATE_ALL` | `false` | If true, run all contracts in the directory |
| `STRICT_MODE` | `false` | Treat warnings as failures |
| `OUTPUT_FORMAT` | `text` | `text` or `json` |


---

## Verification

→ verify: `test -f validate-contracts/SKILL.md && grep -q 'name: validate-contracts' validate-contracts/SKILL.md && echo OK`
→ verify: `grep -qi 'specs/contracts\|JSON Schema\|key.set\|data.shape' validate-contracts/SKILL.md && echo OK`
→ verify: `grep -ci 'divergence\|missing key\|type mismatch\|diff\|conforms\|column' validate-contracts/SKILL.md | awk '{if($1>=3) print "OK"; else print "FAIL"}'`
→ verify: `grep -ci 'JSON Lines\|machine.parse\|CI\|deploy.*gate\|pre.deploy' validate-contracts/SKILL.md | awk '{if($1>=2) print "OK"; else print "FAIL"}'`
→ verify: `grep -q 'validate-contracts' SKILL-INDEX.md && echo OK`
