# story: e37s11
# targets.yaml — Wave C: qwen, kilocode (markdown commands + rules)

## Acceptance Criteria

```bash
grep -q 'qwen' scripts/targets.yaml &&
grep -q 'kilocode' scripts/targets.yaml &&
echo OK
```

## Out of scope
- Adapter file creation beyond registry row + basic skeleton (uses existing shared libs)
- Platform-specific markdown rule rendering (tools read their own formats)
- E2E test with actual qwen or kilocode binary

## Adapter guidance
- qwen: markdown-commands target — `context.mode: symlink`, `file: QWEN.md`, `skill: null` (instruction-file-only)
- kilocode: rules-based target — `context.mode: copy`, `skill.adapter: kilocode`, verify via `test-adapters.sh`
- Both targets should be `tier: opt_in` initially (not default_on)
- Test gate: `bash scripts/test-adapters.sh qwen && bash scripts/test-adapters.sh kilocode` must pass

