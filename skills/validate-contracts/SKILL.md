# story: e80s02
---
name: validate-contracts
phase: verify
description: "Assert data shape consistency across system boundaries — live API responses against JSON Schema, key-set comparison across layers, data shape validation for migrations and exports. Catches silent data corruption before deploy."
model: sonnet
effort: standard
---

# Validate Contracts

> **HARD GATE** — Do NOT deploy or migrate data without running `validate-contracts` first. Silent data divergence between system boundaries causes the hardest-to-debug production bugs.
>
> **HARD GATE** — Contract files MUST be version-controlled alongside code. Outdated contracts are worse than no contracts. If a contract hasn't been reviewed in 30 days, flag it as stale.

Validate that data structures stay in sync across system boundaries — front-end vs back-end, API responses vs expected schemas, config files vs code assumptions, migration output vs target shape.

## Contract types

| Mode | What it catches | When to use |
|------|----------------|-------------|
| **Schema** | API response shape mismatches | Before every deploy, after API changes |
| **Key-set** | Missing/unexpected keys across two data sources | Translation files, configs, enum definitions |
| **Shape** | Column type or format violations | After migrations, before consuming exports |

## Contract file convention

All contract files live in `specs/contracts/` as YAML. See [REFERENCE.md](REFERENCE.md) for extended examples.

### Key-set example

```yaml
# specs/contracts/i18n-keys.yaml
sources:
  reference: src/locales/en.json
  target: src/messages/en.json
mode: subset
```

## Process

### 1. Define contract

Create a YAML file in `specs/contracts/` following the schema for the mode.

### 2. Run validation

```bash
bash scripts/validate-contracts.sh specs/contracts/<contract>.yaml
```

The runner auto-detects key-set contracts (`sources:` block). Schema and shape modes are documented in REFERENCE.md for consumer projects.

### 3. Read the report

```
PASS: key-set contract
# or
FAIL: key-set — N keys in reference missing from target
```

JSON Lines output for CI is planned for schema/shape modes; key-set failures exit non-zero.

### 4. Fix divergence

- **Missing keys** → add to target source
- **Type mismatches** → update schema or fix producer
- **Shape violations** → fix migration or consumer

### 5. Re-validate

```bash
bash scripts/validate-contracts.sh specs/contracts/<contract>.yaml
```

## Verify arc

Part of **★ VERIFY ★**: `verify-work` → `validate-contracts` → `smoke-test` → `run-evals` → `audit-code`

## Verify

→ verify: `test -x scripts/validate-contracts.sh && bash scripts/validate-contracts.sh --self-test && grep -q 'validate-contracts.sh' skills/validate-contracts/SKILL.md && echo OK`
