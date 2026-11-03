---
bug_id: BUG-2026-11-03-adapter-stdin-hang
status: fixed
severity: high
scope: adapters / verification gates
title: "Adapters read stdin when sourced, so Preflight hangs and context wiring can skip targets"
files_changed: "scripts/adapters/{agy,cursor,gemini,mimo,pi,zcode}.sh, scripts/test-adapter-render.sh, scripts/generate-context-bundle.sh"
approach: "Guard each adapter's stdin branch with BASH_SOURCE == $0 (as the other 10 do) and source adapters with </dev/null"
risk_level: low
commit_message: "fix(adapters): stop reading stdin when an adapter is only sourced"
---

# BUG-2026-11-03: adapters read stdin when sourced, so Preflight hangs and context wiring skips targets

**Severity:** high (Preflight hangs forever under some callers; targets silently not wired)
**Status:** fixed
**Found in:** a background Preflight run during e58s10. It had written nothing for 18 minutes and
was stuck in `adapter-render`.

## Symptom

`bash scripts/run-verification-gates.sh` never finished. The `adapter-render` gate
(`scripts/test-adapter-render.sh`) had a child `cat` blocked on stdin. Earlier runs had passed,
because their stdin happened to be closed or `/dev/null`.

## Root cause

Six adapters (`agy`, `cursor`, `gemini`, `mimo`, `pi`, `zcode`) ran their stdin branch at top level:

```bash
if [[ ! -t 0 ]]; then JSON_INPUT=$(cat) ...
```

That branch also runs when the file is only **sourced**. With a stdin that is open and never
closes, such as a pipe from a background job, `cat` waits forever. The other 10 adapters already
guarded it with `[[ "${BASH_SOURCE[0]}" == "${0}" ]]`, so it runs only when executed.

There were two callers that source adapters without closing stdin:

- `scripts/test-adapter-render.sh`: the Preflight hang.
- `scripts/generate-context-bundle.sh`: sources adapters inside
  `while read … done < <(yq …)`. An unguarded adapter's `cat` swallows the rest of the target
  list, so every later target is silently not wired.

`scripts/lib/adapter-render-all.sh` and `scripts/test-adapters.sh` already used `</dev/null`.

## Fix

- The six adapters use the same `BASH_SOURCE == $0` guard as the rest. Executing an adapter with
  JSON piped in still renders.
- Both callers source with `</dev/null`.

## Evidence

- Before: `sleep 60 | bash scripts/test-adapter-render.sh` still hung after 20 s.
- After: the same command finishes with 63 passed, 0 failed. `test-adapters.sh` gives 111 passed,
  0 failed. `golden-g14-adapter-dispatch` passes. `echo '{…}' | bash scripts/adapters/pi.sh`
  writes the skill. Unguarded adapters: 0.

## Recurrence guard

`grep -ln '^if \[\[ ! -t 0 \]\]' scripts/adapters/*.sh` must print nothing. Any adapter's stdin
branch must check `BASH_SOURCE == $0` first.
