
# Fix Bug

Orchestrates **fix_bug** flow without mixing epic build state.

> **HARD GATE** — Set `specs/state.yaml` `active_flow: fix_bug`.

## Process

1. If no `specs/bugs/BUG-*.md`, run `investigate-bug` first (YAML frontmatter + fix plan in file).
2. `develop-tdd` against the bug file's verify steps.
3. `validate-fix` — re-run failing test, full suite, lint.
4. `bash scripts/sync-bugs-registry.sh` — refresh `specs/bugs/registry.yaml`.
5. Clear `active_flow` or return to `build_epic` when done.

## Bug file SoT

One markdown file per bug with frontmatter:

```yaml
bug_id: BUG-001
status: open
severity: high
scope: api
title: Short title
```

## Verify

→ verify: `test -d specs/bugs && bash scripts/sync-bugs-registry.sh`
