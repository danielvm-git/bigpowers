---
bug_id: BUG-2026-07-26-null-skill-adapters-install-nothing
status: fixed
severity: high
scope: install
title: "Qwen, Cline, OpenCode and Copilot install zero skills — skill: null means their adapters are never dispatched"
security_impact: NONE
risk_level: high
---

# BUG-2026-07-26: four advertised integrations install nothing

## Problem

`bigpowers setup` reports success for Qwen Code, Cline, OpenCode and Copilot CLI while
installing **zero skills** for all four. Reproduced directly:

```
$ bash scripts/install.sh --dry-run
Qwen Code → ~/.qwen/skills/
  WARNING: <repo>/.qwen/skills not found — run sync-skills.sh first
Cline → ~/.cline/skills/
  WARNING: <repo>/.cline/skills not found — run sync-skills.sh first
OpenCode → ~/.config/opencode/skills/
  WARNING: <repo>/.opencode/skills not found — run sync-skills.sh first
Copilot CLI → ~/.copilot/skills/
  WARNING: <repo>/.copilot/skills not found — run sync-skills.sh first
```

The remediation hint is also wrong: running `sync-skills.sh` does not create those
directories and never will.

## Root cause

`scripts/lib/srp-engine.py` is the live renderer. `get_active_adapters()` (line 100) builds
its dispatch list from `targets.yaml` entries that carry a `skill.adapter`:

```python
adapter = target['skill'].get('adapter')
```

`qwen`, `cline`, `opencode` and `copilot` all declare `skill: null` in `scripts/targets.yaml`,
so `srp-engine` never dispatches them — 15 of 24 adapters render, these four do not.

Their install functions nevertheless read a rendered directory that only that dispatch would
have produced:

| Target | install reads | declared in registry |
|---|---|---|
| qwen | `$REPO_ROOT/.qwen/skills` (`install-targets-b.sh:174`) | `skill: null` |
| cline | `$REPO_ROOT/.cline/skills` (`install-targets-c.sh:54`) | `skill: null` |
| opencode | `$REPO_ROOT/.opencode/skills` (`install-targets-d.sh:103`) | `skill: null` |
| copilot | `$REPO_ROOT/.copilot/skills` (`install-targets-d.sh:143`) | `skill: null` |

Each adapter defines a working `render_skill()` — `scripts/test-adapter-render.sh` proves all
four render correctly when driven directly. Only the registry wiring is missing.

This is distinct from the genuinely context-only bridges (`aider`, `goose`, `iflow`, `shai`,
`vibe`), which have no `render_skill` and correctly declare `skill: null`.

## Why nothing caught it

- The per-target hub tests asserted `install_<id>()` *exists*, never that it installed anything.
- `test-adapters.sh` was exercising 1 of 21 adapters until the stdin-leak fix in 9ac4a795.
- No gate compares "adapter defines render_skill" against "registry dispatches it".

## TDD plan (RED first)

1. **RED** — a check asserting that every adapter defining `render_skill()` either has a
   `skill.adapter` row in `targets.yaml` or is a declared context-only bridge must fail today,
   naming qwen, cline, opencode and copilot.
2. **GREEN** — give the four a `skill:` block pointing at the output directory their install
   function already reads.
3. Verify `sync-skills.sh` produces `.qwen/skills`, `.cline/skills`, `.opencode/skills` and
   `.copilot/skills`, and that `install.sh --dry-run` no longer warns for them.
4. Wire the check into `scripts/lib/golden-suite-gates.sh` so a future `skill: null` on a
   rendering adapter fails the build.

## Verify

```
verify: bash scripts/golden-g14-adapter-dispatch.sh
verify: bash scripts/golden-g14-adapter-dispatch.sh --self-test
verify: bash scripts/install.sh --dry-run 2>&1 | grep -c 'skills not found' | grep -qx 0
```

## Resolution

Repairing this uncovered a second, deeper defect in the same file. The `qwen` entry was
missing the `- id: kilocode` list marker for the block that followed it, so a duplicate
Kilocode block was absorbed into `qwen`. YAML lets later duplicate keys win, and **`qwen`
parsed as Kilocode** — name, adapter, output, context and contracts all silently replaced.
Qwen's real configuration was discarded on every parse, and no gate noticed because
`validate-targets-yaml.sh` and `test-target-contracts.sh` grep raw text rather than reading
the parsed document.

Applied:
- removed the orphaned duplicate Kilocode block, restoring `qwen` to its own identity
- gave `qwen` and `cline` a `skill:` block pointing at the directory their install already read
- registered `opencode` and `copilot`, which shipped an adapter and an install function but had
  no registry row at all
- added `scripts/golden-g14-adapter-dispatch.sh` (+ self-test), wired into the gate list

Verified: `sync-skills.sh` now renders 80 skills into each of `.qwen/skills`, `.cline/skills`,
`.opencode/skills` and `.copilot/skills`; `install.sh --dry-run` emits **0** "skills not found"
warnings, down from 4; registry grows 22 → 24 targets and 19 rendering adapters all dispatch.
