---
name: verify-work
model: haiku
description: "Multi-phase UAT gate — cold-start smoke, build, typecheck, lint, tests, step-by-step manual verification, gaps-closure loop. Use after execute-plan or develop-tdd, before audit-code."
---

<!-- story: e02s01 e46s03 -->
<!-- story: e38s05 -->
<!-- story: e45s05 -->
<!-- story: e45s09 -->
<!-- story: e45s13 -->
<!-- story: e45s40 -->
<!-- story: e51s03 -->
<!-- story: e20s04 -->
<!-- story: e20s06 -->


# Verify Work

> **HARD GATE** — No story is "done" until manual UAT for the active story is confirmed with evidence.
>
> **HARD GATE** — Do NOT run on `main` or `master`. Use the feature branch from `kickoff-branch`.

Review answers "is the code good?"; Verify answers "does the built thing do what was promised?"

## Modes

- Default: full UAT plus gaps loop
- --smoke: Cold-start only plus one happy-path flow. Use for hotfixes.
- --cli: CLI tool verification — replaces cold-start with binary smoke checklist. Use for CLI tools with no server process.

## Risk-Scaled Depth

`verify-work` reads the `risk:` field from the story template (defaults to `P1` if absent) to scale verification rigor:
- **P0**: Full verify-work multi-phase + `security-review` (step 5) + NFR evidence gate (step 5b).
- **P1**: Standard verify-work (build, test, lint, step-by-step manual).
- **P2**: Smoke, typecheck, lint only. Skip tests, security scan, and step-by-step manual UAT.
- **P3**: Typecheck and lint only. Skip smoke, tests, security scan, and step-by-step manual UAT.

## Process

> **Timing:** `bash scripts/bp-timing.sh start verify-work` at invocation; `bash scripts/bp-timing.sh end verify-work` before handoff.

0. **Branch check** — must not be `main`/`master`.

0a. **Preflight / CI green (HARD GATE — e51s03)** — Run Preflight from `CLAUDE.md` or `BP_PREFLIGHT` (`bp-read-agents.sh`). If PR open: `gh pr checks` (**CI green**). Failure blocks all phases → `quick-fix` or `fix-bug`.

1. Read active story tasks from `specs/epics/<capsule>/eNNsYY-tasks.yaml` and story spec from `specs/epics/<capsule>/eNNsYY-<slug>.md` (countable-story-format, Gherkin in §17). Note the `risk:` level (`P0`–`P3`).
1a. **Pre-UAT verify validation** — for each task's `verify:` command, run it and detect pattern mismatches before UAT begins. If a grep/awk/jq command fails, check whether the pattern is wrong vs. a genuine failure:
    ```bash
    # For a failing grep -q 'PATTERN' FILE, check what is actually in FILE
    grep 'PATTERN' FILE || grep -n '' FILE | head -20   # show nearest lines
    ```
    Report: `"Pattern 'X' not found. Nearest match: 'Y' at line N"` and ask `"Update verify command? [Y/n]"`. Fix before proceeding — a mismatched verify command produces false failures during UAT.
2. **Cold-start smoke** (if app; skip if P3): stop server, clear caches, boot from scratch.
3. **AGENTS.md preflight** — if 0a skipped BP_PREFLIGHT, run `bash scripts/bp-read-agents.sh` and use detected command.
4. Mechanical gates: build → typecheck → lint → tests (from `CLAUDE.md` or AGENTS.md). Skip tests if P2/P3.

> **HARD GATE — One-test-minimum terminal verdict (e45s13):** At least one mechanical gate MUST be a **real terminal-verdict command** (shell exits 0 or non-zero — not prose, not combined log excerpts). Record that command's stdout/stderr from a **single contiguous run** in `specs/verifications/eNNsYY-verify.yaml` under `terminal_verdict`. Bug reports and gap logs MUST NOT merge evidence from multiple runs into one verdict — each failing run gets its own evidence block.

5. **Security scan** (skip if P2/P3) — run `security-review` against the git diff (working tree vs merge-base). Parse findings report. If any HIGH findings with confidence ≥ 8 exist → **block the gate**. Write findings to `specs/security/REVIEW.md`. Allow documented exceptions via `specs/security/EXCEPTIONS.md`. MEDIUM/LOW findings warn but don't block.
5a. **Blind-spot check** — run `bash scripts/check-blind-spots.sh`. This detects structural quality gaps (verify-gap, test-gap, stale-tag, etc.) beyond percentage coverage. If any HIGH-severity findings exist → **block the verify-work PASS gate**. Findings are written to `specs/blind-spots.json`. MEDIUM/LOW findings warn but don't block.
5a2. **Completeness critic (e45s05)** — `bash scripts/lib/completeness-critic.sh`. **BLOCKER** aborts merge gate; WARNING → gaps loop; FILLED = evidence only.

5b. **NFR Evidence Gate** (P0 only) — Produces go/no-go output on three dimensions: Performance (response time, throughput), Reliability (error rate, recovery), and Operability (logging, health checks). Reads thresholds from `specs/tech-architecture/eNN-TEST_PLAN_LATEST.md` and writes evidence as OKF verification-report bundles to `specs/verifications/NFR-eNNsYY.json`. FAIL on any dimension blocks the gate.
6. **Step-by-step UAT** (skip if P2/P3) — one user-observable action at a time.
7. **Gaps loop** — failures → log → `plan-work` → re-verify. Unaddressed HIGH findings from step 5 feed into this loop alongside other quality gaps.

7a. **Validation gate (e45s09)** — All tasks `status: passing`; evidence in `specs/verifications/`; update `execution-status.yaml`.
7b. **Reopen-don't-refile (e45s09)** — Regressions reopen existing story/bug — no duplicate capsule entries.

## Verify sub-operations

### Cold-Start Smoke (absorbed)

Stop server, clear caches, boot from scratch; confirm no stale config affects behavior.

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
  terminal_verdict:
    command: "npm test"
    exit_code: 0
    captured_at: "2026-06-11T14:25:00Z"
    note: "Single run — do not merge output from other attempts"
  manual:
    steps:
      - step: "Open /login"
        expected: "Login form renders"
        actual: "Login form rendered correctly"
        passed: true
  gaps:
    closed: true
```

### 5b. OKF wiki LINT (e39s08)

```bash
for p in specs/skills-wiki/skills/*.md; do s="skills/$(basename "$p" .md)/SKILL.md"; [ -f "$s" ]&&[ "$p" -ot "$s" ]&&echo "STALE: $p"; done
for p in specs/conventions-wiki/*.md; do [ "$(basename "$p")" = "index.md" ]&&continue; grep -q "$(basename "$p" .md)" CONVENTIONS.md||echo "ORPHAN: $p"; done
```

> **HARD GATE** — Verification evidence MUST be persisted before marking the story done. No evidence = not verified.

## --cli mode

CLI tools: use `--cli` when no server process. Binary detect + checklist: [REFERENCE.md](../../../skills/verify-work/REFERENCE.md#cli-mode).

## Verify

→ verify: `find specs/verifications -maxdepth 1 -name '*-verify.yaml' 2>/dev/null | head -1 | grep -q . && echo "Evidence persisted" || echo "No evidence yet"`

## Handoff
READY -> next: audit-code
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

## CLI mode

For CLI tools where cold-start smoke does not apply. Auto-detected when no server process; or use `--cli`.

**Auto-detect binary name:**
```bash
BINARY=$(grep '^name' Cargo.toml | head -1 | awk -F'"' '{print $2}')  # Cargo
BINARY=$(node -e "console.log(require('./package.json').bin && Object.keys(require('./package.json').bin)[0] || '')" 2>/dev/null)
BINARY=$(grep '^BIN\s*=' Makefile 2>/dev/null | awk '{print $3}')
```

**Checklist (replaces cold-start smoke):**
1. `$BINARY --help` → output contains "Usage"
2. `$BINARY --version` → matches manifest
3. README example command → non-empty output
4. `$BINARY --invalid-flag` → exit ≠ 0 with error message
