# story: e37s05
# scripts/targets.yaml — declarative integration registry for all targets

BCP: 5 | story: e37s05

## Summary

Define the **Integration Registry** schema for Reach portability, ship
`scripts/targets.yaml` with core P1 targets, add a deterministic validator, and
establish adapter smoke-test harness + Windows `copy` fallback for Context
Derivatives.

Closes three prior-art gaps identified in the e37 domain review:

1. **Schema unspecified** — registry was a one-line task with no field contract.
2. **Windows symlink constraint** — `symlink` mode fails without Developer Mode;
   `copy` is the documented fallback.
3. **Bash adapter testability** — headless `scripts/test-adapters.sh` gates adapter
   files before wave stories (s09+) land.

Domain terms and invariants: `specs/tech-architecture/tech-stack.md` § Reach Domain.

---

## Deliverables

| Artifact | Purpose |
|----------|---------|
| `scripts/targets.yaml` | Single registry — all Integration Targets |
| `scripts/validate-targets-yaml.sh` | Schema + invariant checks (headless gate) |
| `scripts/test-adapters.sh` | Per-adapter smoke tests (`wire_context` / `render_skill`) |
| `scripts/lib/context-wire.sh` | Shared `wire_context` helpers (`symlink`, `copy`, `config-bridge`) |
| `docs/references/targets-registry.md` | Human-readable schema reference (BMAD-style) |

---

## Registry schema

Top-level shape:

```yaml
registry_version: "1"
generated_by: bigpowers
targets:
  - id: cursor
    # ...
```

### Target row — required fields

| Field | Type | Required | Rule |
|-------|------|----------|------|
| `id` | string | yes | Unique kebab-case identifier; matches `scripts/adapters/<id>.sh` basename |
| `name` | string | yes | Display name for matrix output |
| `tier` | enum | yes | `default_on` \| `opt_in` \| `optional` — controls verify-matrix scope |
| `skill` | object \| null | no | Skill Adapter block; `null` when target consumes no skill artifacts |
| `context` | object \| null | no | Context Wiring block; `null` when skill-only |
| `contracts` | list | no | Per-target assertion names for `verify-install.sh --matrix` |

**Row invariant:** at least one of `skill` or `context` MUST be non-null.

### `skill` block

```yaml
skill:
  adapter: cursor          # basename → scripts/adapters/cursor.sh
  output: .cursor/rules    # primary artifact dir (informational + matrix checks)
```

- `adapter` MUST resolve to `scripts/adapters/<adapter>.sh` on disk.
- Orchestrator (`sync-skills.sh`, e37s07) calls `render_skill` only when `skill` is non-null.

### `context` block

```yaml
context:
  adapter: cursor          # same adapter file may serve both hooks
  mode: symlink            # symlink | copy | native | config-bridge
  file: CLAUDE.md          # Context Derivative path (required for symlink/copy)
  # config-bridge only:
  bridge_file: .aider.conf.yml
  bridge_key: read
```

| `mode` | Behavior | When to use |
|--------|----------|---------------|
| `native` | Reads `AGENTS.md` directly; no derivative created | Cline, native AGENTS.md readers |
| `symlink` | `ln -sf AGENTS.md <file>` | macOS / Linux / Windows with symlink support |
| `copy` | Copy `AGENTS.md` → `<file>` (content-identical) | Windows without Developer Mode; CI sandboxes blocking symlinks |
| `config-bridge` | Write bridge config pointing at `AGENTS.md` | Aider `.aider.conf.yml`, similar |

**Platform rule (Windows gap):** `generate-context-bundle.sh` (e37s06) MUST try
`symlink` first when `mode: symlink`. On failure (exit non-zero or `readlink` /
`Test-Path` equivalent fails), fall back to `copy` and emit a single stderr
warning — not a hard failure. Registry rows MAY declare `mode: copy` explicitly
when the target is known to be Windows-primary.

**Invariant update:** Context Derivatives are symlinks **by default**; `copy` is an
allowed fallback that preserves content identity (drift detected by matrix hash
check, e37s08).

### `tier` — verify-matrix scope

| Tier | Matrix asserts when |
|------|---------------------|
| `default_on` | `AGENTS.md` exists (always in scope) |
| `opt_in` | Target wiring artifacts exist on disk |
| `optional` | `--full` flag AND wiring artifacts exist |

### `contracts` — matrix assertion names

Named checks referenced by `verify-install.sh --matrix` (e37s08). Examples:

```yaml
contracts:
  - agents_md_exists
  - symlink_claude_md
  - cursor_rules_nonempty
```

Contract catalog lives in `scripts/lib/target-contracts.sh` (e37s08); e37s05
defines the naming convention only.

---

## Initial core targets (P1)

Minimum five rows shipping in e37s05: **cursor**, **gemini**, **pi**, **cline**,
**aider**. Full row YAML lives in `docs/references/targets-registry.md` § Core P1
targets (single canonical copy — do not duplicate here).

Wave targets (s09–s13) add rows + adapter files only — no orchestrator edits
(invariant 15).

---

## Adapter interface (e37s07 dependency)

Each `scripts/adapters/<id>.sh` MAY implement:

```bash
wire_context() { ... }   # called by generate-context-bundle.sh
render_skill() { ... }   # called by sync-skills.sh
```

Adapters MUST be idempotent. Shared wiring logic MUST use `scripts/lib/context-wire.sh`:

```bash
source "$(dirname "$0")/../lib/context-wire.sh"
wire_symlink_or_copy "AGENTS.md" "CLAUDE.md"   # symlink with copy fallback
```

---

## Adapter testability (gap 3)

No BATS dependency — bigpowers uses headless bash gates per CONVENTIONS.

### `scripts/test-adapters.sh`

```bash
# Usage:
#   bash scripts/test-adapters.sh              # all adapters in registry
#   bash scripts/test-adapters.sh cursor       # single adapter
#   bash scripts/test-adapters.sh --dry-run    # list tests only
```

Per adapter, smoke tests:

1. **exists** — `scripts/adapters/<id>.sh` on disk
2. **sourceable** — `source` without syntax error
3. **hooks** — if registry row has `skill`, `render_skill` must be defined; if
   `context` and mode ≠ `native`, `wire_context` must be defined
4. **idempotent** — run `wire_context` in a temp dir twice; second run exits 0
5. **derivative** — after `wire_context`, expected artifact exists (symlink, copy,
   or bridge file per mode)

**Wave gate:** stories s09–s13 MUST NOT merge until
`bash scripts/test-adapters.sh <new-id>` passes. Added to each wave story verify
block in e37s05 follow-up (comment in epic.yaml source).

Integrate into preflight path after e37s07:

```bash
bash scripts/validate-targets-yaml.sh && bash scripts/test-adapters.sh
```

---

## `scripts/validate-targets-yaml.sh`

Headless schema gate (**`yq` + bash** — no new Python dependency; `yq` already used
in repo scripts per e38 threat model). Fail with actionable stderr if `yq` missing:
`brew install yq` / `go install github.com/mikefarah/yq/v4@latest`.

- `registry_version` present
- `targets` is a non-empty list
- Each row: required fields, unique `id`, valid `tier` enum
- At least one of `skill` / `context` non-null per row
- `skill.adapter` / `context.adapter` files exist when declared
- `context.mode` enum valid; `file` required for `symlink`/`copy`
- `bridge_file` + `bridge_key` required for `config-bridge`
- Minimum 5 targets (core P1 set)

Exit 0 = PASS, non-zero = FAIL with actionable stderr.

---

## Acceptance Criteria

```gherkin
Given the Reach domain model in specs/tech-architecture/tech-stack.md
When e37s05 is complete
Then scripts/targets.yaml exists with registry_version and >= 5 core targets
And docs/references/targets-registry.md documents every field and mode
And bash scripts/validate-targets-yaml.sh exits 0
And bash scripts/test-adapters.sh exits 0 for all default_on targets
And scripts/lib/context-wire.sh implements symlink with copy fallback
And context.mode copy is documented as Windows-safe alternative to symlink
And wave stories s09+ are gated on test-adapters.sh per new adapter id
```

## Verify

```bash
test -f scripts/targets.yaml &&
test -f docs/references/targets-registry.md &&
test -f scripts/validate-targets-yaml.sh &&
test -f scripts/test-adapters.sh &&
test -f scripts/lib/context-wire.sh &&
bash scripts/validate-targets-yaml.sh &&
bash scripts/test-adapters.sh &&
echo OK
```

## Prior art

See `docs/references/targets-registry.md` § Prior art (spec-kit, BMAD, GSD,
superpowers).

## Out of scope (e37s05)

- Adapter dispatch in `sync-skills.sh` → e37s07
- `generate-context-bundle.sh` orchestrator → e37s06
- `--matrix` contract implementations → e37s08
- Wave target rows → e37s09–s13
