# story: e37s07
# sync-skills.sh — adapter dispatch from targets.yaml

## Acceptance Criteria

```bash
bash scripts/sync-skills.sh &&
bash scripts/run-verification-gates.sh &&
echo OK
```

## Out of scope
- Context derivative generation (e37s06)
- Per-target contract matrix (e37s08)
- Wave target adapter files (e37s09–s13 — registry rows only, no orchestrator edits)
- Target-specific render logic — dispatch must be registry-driven only

## Adapter guidance
- Must parse `scripts/targets.yaml` to determine which adapters to invoke
- For each target with non-null `skill`: call `render_skill` from `scripts/adapters/<id>.sh`
- Must run `scripts/validate-targets-yaml.sh` before dispatch (schema gate)
- Must NOT contain target-specific render logic — only shared IR, registry load, and hook dispatch (invariant 13)
- Preflight must pass: `bash scripts/run-verification-gates.sh && echo OK`

