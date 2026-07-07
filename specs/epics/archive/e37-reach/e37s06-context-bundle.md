# story: e37s06
# scripts/generate-context-bundle.sh — AGENTS.md single source + all derivatives

## Acceptance Criteria

```bash
test -f scripts/generate-context-bundle.sh &&
bash scripts/generate-context-bundle.sh --dry-run 2>&1 | grep -qi 'AGENTS.md' &&
echo OK
```

## Out of scope
- Adapter dispatch logic (e37s07)
- Per-target contract verification (e37s08)
- Windows copy fallback implementation (e37s05 — context-wire.sh)
- symlink verification in CI

## Adapter guidance
- Must read `scripts/targets.yaml` (e37s05) to discover which targets need context derivatives
- Must call `wire_context` from `scripts/lib/context-wire.sh` for each target with a non-null `context` block
- `--dry-run` mode must print what it would do without writing files
- Must be idempotent: second run on a clean state produces same output

