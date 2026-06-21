
# Verify Work

> **HARD GATE** — No story is "done" until manual UAT for the active story is confirmed with evidence.
>
> **HARD GATE** — Do NOT run on `main` or `master`. Use the feature branch from `kickoff-branch`.

Review answers "is the code good?"; Verify answers "does the built thing do what was promised?"

## Modes

- Default: full UAT plus gaps loop
- --smoke: Cold-start only plus one happy-path flow. Use for hotfixes.

## Process

> **Timing:** `bash scripts/bp-timing.sh start verify-work` at invocation; `bash scripts/bp-timing.sh end verify-work` before handoff.

0. **Branch check** — must not be `main`/`master`.

1. Read active story tasks from `specs/epics/<capsule>/eNNsYY-tasks.yaml` and story spec from `specs/epics/<capsule>/eNNsYY-<slug>.md` (countable-story-format, Gherkin in §17).
2. **Cold-start smoke** (if app): stop server, clear caches, boot from scratch.
3. Mechanical gates: build → typecheck → lint → tests (from `CLAUDE.md`).
4. **Step-by-step UAT** — one user-observable action at a time.
5. **Gaps loop** — failures → log → `plan-work` → re-verify.

## Verify sub-operations

### Cold-Start Smoke (absorbed)

For applications, verify correctness from a clean state:

- Stop the running server (if any)
- Clear any caches (browser, application caches, compiled artifacts)
- Boot the application from scratch
- Verify that no stale artifacts or configuration are affecting the behavior

This catches environment-specific bugs and ensures the build is reproducible.

### Gaps Loop (absorbed)

After UAT, identify and close any gaps between promised behavior and actual behavior:

- Capture what was promised in the epic task description
- Document what actually happened (expected vs actual)
- If behavior doesn't match the promises, log the gap
- Loop back to `plan-work` or `develop-tdd` to fix the gap
- Re-verify until all gaps are closed (gaps count = 0)

## UAT dialogue

- Pass: user confirms per step.
- Fail: capture expected vs actual; do not mark done in `execution-status.yaml`.

## Persist verification evidence

After UAT passes, write structured evidence to `specs/verifications/eNNsYY-verify.yaml`:

```yaml
story_id: e01s01
verified_at: "2026-06-11T14:30:00Z"
verifier: verify-work
phases:
  smoke:
    passed: true
  build:
    passed: true
    command: "npm run build"
  typecheck:
    passed: true
  lint:
    passed: true
  tests:
    passed: true
    coverage: "94.2%"
  manual:
    steps:
      - step: "Open /login"
        expected: "Login form renders"
        actual: "Login form rendered correctly"
        passed: true
  gaps:
    closed: true
```

> **HARD GATE** — Verification evidence MUST be persisted before marking the story done. No evidence = not verified.

## Verify

→ verify: `test -f specs/verifications/<story_id>-verify.yaml && echo "Evidence persisted"`

See [REFERENCE.md](REFERENCE.md) for cold-start and gaps template.

## Handoff

Gate: READY -> next: audit-code
Writes: state.yaml handoff.next_skill = audit-code

---

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
