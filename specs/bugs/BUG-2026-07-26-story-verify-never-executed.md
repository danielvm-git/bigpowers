---
bug_id: BUG-2026-07-26-story-verify-never-executed
status: fixed
severity: critical
scope: verification-gates
title: Story-level verify: commands in epic.yaml are never executed
github_issue: 106
---

> **Resolved 2026-07-26.** `run-story-verify.sh` now executes every `done`
> story's verify and gates CI. Result went from 24/34 failing to
> **43 PASS, 0 FAIL**. Root causes 2–4 fixed in separate commits. Evidence
> below is the state at diagnosis, kept for the record.

# BUG: story-level `verify:` is presence-checked, never executed

## Summary

`specs/epics/*/epic.yaml` declares a `verify:` command per story. Nothing in the
repo ever runs it. The only check is that the *line exists*. As a result a story
can be marked `status: done` while its own declared gate fails.

Filed as [#106](https://github.com/danielvm-git/bigpowers/issues/106).

## Reproduction

Execute the `verify:` of every story marked `done` across all epic capsules:

```
executed=34  failed=24  done-stories-with-no-verify=4
```

**24 of 34 `done` stories fail their own declared verify command.** No gate ever
reported this because no gate ever ran them.

The issue's original exhibit (e80s05, `grep -q fail-open-verify
skills/security-review/SKILL.md`) now passes — #105 fixed that instance. The
structural defect it was evidence of is untouched, and is far wider than one story.

## Root cause 1 — presence-only check (the reported defect)

`scripts/lib/plan-consistency-check.sh:77-78`:

```bash
grep -qE '^[[:space:]]*verify:' "$tasks" \
  || report CRITICAL "Story $sid tasks.yaml missing runnable verify: commands"
```

This asserts a `verify:` key is present. It never executes it. The word
"runnable" in the failure message is aspirational, not enforced.

Two tiers with opposite guarantees:

| tier | declared in | executed? | by |
|---|---|---|---|
| skill | `SKILL.md` `→ verify:` | **yes** | `run-skill-verify.sh`, blocking in `publish.yml` + `golden-suite.yml` |
| story | `epic.yaml` `verify:` | **no** | presence-checked only |

#96 hardened tier 1. Tier 2 — the tier that decides whether a story, epic, and
issue are `done` — was never wired.

## Root cause 2 — `ta_cleanup` trap forces exit 1 (cascade, 22 of 24 failures)

`scripts/lib/test-assertions.sh:7`:

```bash
ta_cleanup() { [[ -n "${TA_TMPDIR:-}" && -d "$TA_TMPDIR" ]] && rm -rf "$TA_TMPDIR"; }
```

Registered as `trap ta_cleanup EXIT`. When `TA_TMPDIR` is unset — which is always,
because `scripts/test-adapters.sh:24` sets `TMPDIR`, not `TA_TMPDIR` — the `[[ ]]`
test is false, the `&&` chain returns 1, and that becomes the function's return
value. **The exit status of an EXIT trap's last command replaces the script's exit
status.** So `test-adapters.sh` exits 1 while printing `0 failed`.

Every integration-epic story verify chains `test-adapters.sh` or a `test-*-hub.sh`
that sources the same helper, so all 22 inherit the false failure.

Secondary defect in the same file: `ta_pass` calls inside the `( cd "$TMPDIR" … )`
subshell at `test-adapters.sh:61-67` increment `TA_PASS` in a child shell, so the
count is lost — the script reports `4 passed` after printing 5 `PASS` lines.

## Root cause 3 — `verify-install.sh:171` greps the wrong scope

```bash
! install_grep -q '\.gemini/extensions/bigpowers' <<< "$(sed -n '/install_agy/,/^}/p')"
```

Two independent errors:

1. `install_grep()` (`scripts/lib/install-grep.sh:16-18`) is
   `grep "$@" $(install_grep_paths)` — it always greps **files** and ignores stdin,
   so the herestring is discarded.
2. The `sed` has no file operand, so it reads its own stdin and emits nothing anyway.

Effective behaviour: grep for `.gemini/extensions/bigpowers` across `install.sh` +
all `install-targets-*.sh`. `install_agy()` lives in `install-targets-b.sh` and is
clean, but `install-targets-a.sh:21,22,70` legitimately reference that path for
`install_claude`/`install_gemini`. The grep matches, `!` inverts to false, and the
assertion fails permanently. It has never been able to pass.

## Root cause 4 — non-executable verify strings

`e60s01` declares `node bin/bigpowers.js setup (interactive in TTY)` — prose, not a
command. It exits 2 (shell syntax error). A story verify that cannot be executed is
the same failure class as one that is never executed.

## Fix approach (TDD)

1. **RED** — `scripts/run-story-verify.sh --self-test` seeds a temp capsule with a
   `done` story whose verify is `false`, requires a non-zero exit; and seeds one
   whose verify is `true`, requires zero.
2. **GREEN** — implement the runner: walk `specs/epics/*/epic.yaml`, execute
   `verify:` for every `status: done` story, exit non-zero on any failure. Reuse
   `run-skill-verify.sh` hardening: reject fail-open directives (`|| true`,
   `|| echo`, non-asserting pipeline tails).
3. Fix root causes 2, 3, 4 so the new gate is green before it is wired.
4. Wire into `golden-suite.yml` alongside `run-verification-gates.sh`.

## Verify steps

- `bash scripts/run-story-verify.sh --self-test` exits 0
- `bash scripts/run-story-verify.sh` exits 0 across all capsules
- `bash scripts/test-adapters.sh hermes` exits 0 and reports 5 passed
- `bash scripts/verify-install.sh` reports 0 failed
- `bash scripts/run-verification-gates.sh` PASS
