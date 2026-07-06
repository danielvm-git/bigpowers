# Integration Registry Reference

# story: e37s05

`scripts/targets.yaml` is the single Integration Registry for Reach portability.

## Top-level shape

```yaml
registry_version: "1"
generated_by: bigpowers
targets: []
```

## Target row fields

| Field | Type | Required | Rule |
|-------|------|----------|------|
| `id` | string | yes | Unique kebab-case; matches `scripts/adapters/<id>.sh` |
| `name` | string | yes | Display name |
| `tier` | enum | yes | `default_on` \| `opt_in` \| `optional` |
| `skill` | object \| null | no | Skill Adapter block |
| `context` | object \| null | no | Context Wiring block |
| `contracts` | list | no | Matrix assertion names |

At least one of `skill` or `context` must be non-null.

## context.mode

| Mode | Behavior |
|------|----------|
| `native` | Reads AGENTS.md directly; no derivative |
| `symlink` | `ln -sf AGENTS.md <file>` |
| `copy` | Content copy — Windows-safe fallback |
| `config-bridge` | Write bridge config pointing at AGENTS.md |

## Core P1 targets

cursor, gemini, pi, cline, aider — shipped in e37s05.

## Prior art

Spec-kit adapters, BMAD renderer pattern, GSD target lists — consolidated here.
