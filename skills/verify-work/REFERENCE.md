# Verify Work — Reference

## Cold-start smoke

```bash
# Example — adapt to project CLAUDE.md
pkill -f "<dev-server>" 2>/dev/null || true
rm -rf .next/cache node_modules/.cache 2>/dev/null || true
<run command> &
sleep 3 && curl -sf http://localhost:<port>/health || echo "BOOT FAIL"
```

## Gaps template

```markdown
## Gaps (verify-work)

| Step | Expected | Actual | Status |
|------|----------|--------|--------|
| 1 | ... | ... | FAIL |
```

Feed gaps to `plan-work` as new steps with verify commands, then re-run verify-work.
