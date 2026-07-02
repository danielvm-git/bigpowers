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
