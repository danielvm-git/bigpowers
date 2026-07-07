# story: e37s09
# targets.yaml — Wave A: Goose (OSS) + Antigravity agy (proprietary beta)

## Acceptance Criteria

```bash
grep -q 'goose' scripts/targets.yaml &&
bash scripts/verify-install.sh --matrix 2>&1 | grep -q 'goose.*PASS' &&
echo OK
```

## Out of scope
- Adapter file creation for Goose/Agy (uses existing adapters or registry-row-only pattern)
- Skill symlinks — Goose reads AGENTS.md natively (instruction-file-only)
- Antigravity agy is proprietary beta — registry row documents tier, not runtime verification

## Adapter guidance
- Goose: AGENTS.md native reader — `context.mode: native`, no `skill` block needed
- Antigravity (agy): mark `tier: opt_in` with context wiring similar to pi adapter pattern
- Test gate: `bash scripts/test-adapters.sh goose` must pass before this story merges
- See scripts/targets.yaml schema in e37s05 for field documentation

