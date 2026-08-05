---
bug_id: BUG-2026-08-05-cycle-time-toolchain
status: fixed
severity: medium
scope: record-cycle-time / git-hours
title: "record-cycle-time.sh append fails on macOS: BSD awk ignores -F '\\x1f'; agent token vars unbound"
discovered: e81s01 (docs story) — mandated cycle-time recording after land
created: 2026-08-05
---

## Summary

**Actual:** `bash scripts/record-cycle-time.sh append --story <id> --bcps <n>` fails on macOS (BSD awk). Two independent defects in the cycle-time toolchain:

1. **`scripts/lib/git-hours.sh` `partition()`** uses `awk -F '\x1f'`. BSD awk does not interpret `\x` hex escapes in field separators, so the whole record stays one field (`NF=1`) and **every story lands in the `unattributed` bucket** — silently. (Same portability class as the documented `grep \d` rule in CONVENTIONS.md.)
2. **`scripts/record-cycle-time.sh` `cmd_append()`** references `$bcp_plus` and `$agent_tokens_in/out/cache_read/cache_write` outside their initialization branches. Under `set -u`, a run without `--bcp-plus` or `--telemetry` dies with `unbound variable` at the OKF emit block. The null-default block initializes the other `agent_*` fields but not the four `agent_tokens_*` ones.

**Expected:** append works without `--bcp-plus`/`--telemetry`, attributes the story from its `Story: <id>` trailer, and writes the ledger row + OKF bundle.

## Reproduce

```bash
# Defect 1 — partition mis-attributes on BSD awk (macOS)
printf 'a\x1fb' | awk -F '\x1f' '{print NF}'          # → 1 (should be 2)
ROOT=. IDLE_SECONDS=7200 PAD_SECONDS=7200 bash -c \
  'source scripts/lib/git-hours.sh; partition "HEAD" "Story"'   # everything → unattributed

# Defect 2 — append dies without optional flags
bash scripts/record-cycle-time.sh append --story e81s01 --bcps 2 --range HEAD
# → line 184: bcp_plus: unbound variable  (then agent_tokens_in after first fix)
```

## Root Cause Analysis

1. `partition()` hardcodes `-F '\x1f'` — a GNU-awk-ism. The `\x1f` in the git `--pretty=format` side is interpreted by **git** (fine everywhere); the awk side needs a separator that BSD awk understands. Portable fix: pass the literal byte via the shell — `awk -v FS="$(printf '\037')"` (octal escape, supported by both BSD and GNU awk).
2. `cmd_append()` local declarations miss `bcp_plus` (only set by `--bcp-plus`) and the four `agent_tokens_*` vars (only set inside the `--telemetry` branch). The rest of the `agent_*` family gets explicit `null` defaults; these five never did. Append-without-telemetry was evidently never exercised on a shell with `set -u`.

## Fix Plan

1. `git-hours.sh`: `-F '\x1f'` → `-v FS="$(printf '\037')"`.
2. `record-cycle-time.sh`: add `bcp_plus=""` to the `local` declaration; add the four `agent_tokens_*="null"` defaults to the null-init block.
3. Verify: `partition` attributes the story trailer; `append` writes the row + OKF bundle without optional flags.

## Verification

```bash
ROOT=. IDLE_SECONDS=7200 PAD_SECONDS=7200 bash -c 'source scripts/lib/git-hours.sh; partition "<range>" "Story"' | grep -v unattributed
bash scripts/record-cycle-time.sh append --story e81s01 --bcps 2 --range <range>
```
