---
story_id: e22s01
title: "scripts/run-skill-verify.sh — machine-runnable catalog health check"
status: backlog
bcps: 1
type: feat
context: infra
---

# Story e22s01: run-skill-verify.sh

Every SKILL.md has a `## Verify` section with a `→ verify:` command. These
are never run automatically — they're documentation that can silently drift.

Add `scripts/run-skill-verify.sh` that extracts and runs each skill's verify
command, reporting pass/fail per skill. This closes the gap between
"documented verify" and "actually works."

## Acceptance Criteria

- [ ] `scripts/run-skill-verify.sh` exists and is executable
- [ ] Script extracts `→ verify:` lines from all `*/SKILL.md` files
- [ ] Reports PASS / FAIL / SKIP per skill with exit code 0 only if zero FAILs
- [ ] Skips skills with no `→ verify:` line (reports as SKIP, not FAIL)

## Gherkin Scenarios

```gherkin
Given 68 SKILL.md files exist in the repo
When scripts/run-skill-verify.sh runs
Then each skill with a "→ verify:" line has its command executed
And the output shows "PASS: <skill>" or "FAIL: <skill> — <error>"
And skills without "→ verify:" show "SKIP: <skill>"
And exit code is 0 only when zero skills FAIL

Given a skill whose verify command is "grep -q 'active_flow' specs/state.yaml"
When the script runs
Then the command executes in the repo root
And returns PASS if the file exists and matches
```

## Verification

```bash
bash scripts/run-skill-verify.sh 2>&1 | grep -c "^PASS\|^SKIP" | awk '{if($1>0) print "OK: "$1" skills checked"; else print "FAIL: no skills checked"}'
```

## Implementation Notes

- Extract verify command: `grep '→ verify:' <skill>/SKILL.md | sed 's/.*→ verify: //'`
- Run in repo root context (not inside skill dir) — most verify commands are relative to root
- Timeout per command: 10 seconds (guard against hanging greps)
- Output format: `PASS: kickoff-branch`, `FAIL: some-skill — exit 1`, `SKIP: craft-skill`
