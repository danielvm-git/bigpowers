# story: e37s12
# targets.yaml — Wave D: continue (rules adapter; re-opened active OSS)

## Acceptance Criteria

```bash
grep -q 'continue' scripts/targets.yaml &&
bash scripts/verify-install.sh --matrix 2>&1 | grep -q 'continue' &&
echo OK
```

## Out of scope
- Rules file format parsing (Continue.dev reads its own format)
- E2E test with actual Continue.dev binary
- Continue.dev plugin or extension setup

## Adapter guidance
- Continue.dev re-opened as active OSS — previously unmaintained, now active (e37s12)
- `context.mode: symlink` or `copy` depending on platform — Continue.dev reads `.continuerc.json` or rules files
- `tier: opt_in` — not default_on, requires user opt-in
- Registry row must reference the re-opened upstream (not the archived repo)
- Test gate: `bash scripts/test-adapters.sh continue` must pass before merge

