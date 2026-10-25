#!/usr/bin/env bash
# story: BUG-2026-07-26-story-verify-never-executed
# Execute story-level verify: commands declared in specs/epics/*/epic.yaml.
# Tier 2 of the verify arc (GH #106). Tier 1 is run-skill-verify.sh.
#
# Only stories marked `status: done` are gated: a done story asserts its own
# acceptance criteria hold. Backlog/in-progress stories are reported as SKIP.
#
# Usage:
#   bash scripts/run-story-verify.sh              # gate all done stories
#   bash scripts/run-story-verify.sh e80s05       # one story
#   bash scripts/run-story-verify.sh --self-test  # prove the gate can fail

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# shellcheck source=lib/fail-open-detect.sh
source "$REPO_ROOT/scripts/lib/fail-open-detect.sh"
# shellcheck source=lib/python-env.sh
source "$REPO_ROOT/scripts/lib/python-env.sh"
resolve_python || exit 1

VERIFY_TIMEOUT_SECONDS=120

# Portable timeout: macOS lacks GNU timeout; use perl alarm as fallback.
# stdin is closed for every verify command: gate_all reads its record list on
# fd 0, and a child that reads stdin (any test-*.sh sourcing a read loop) would
# otherwise swallow the remaining records and silently shrink the gate.
if command -v timeout >/dev/null 2>&1; then
  run_with_timeout() { timeout "$VERIFY_TIMEOUT_SECONDS" bash -c "$1" </dev/null 2>&1; }
elif command -v perl >/dev/null 2>&1; then
  run_with_timeout() { perl -e "alarm $VERIFY_TIMEOUT_SECONDS; exec @ARGV" bash -c "$1" </dev/null 2>&1; }
else
  run_with_timeout() { bash -c "$1" </dev/null 2>&1; }
fi

GATED_STATUS="done"
PASS=0; FAIL=0; SKIP=0
TARGET="${1:-}"

extract_records() {
  "$PYTHON" "$REPO_ROOT/scripts/lib/extract-story-verify.py" "${EXTRACT_ROOT:-$REPO_ROOT}"
}

# Report a story whose directive can never fail. Kept separate from execution so
# a fail-open directive is a FAIL even when the command happens to exit 0.
reject_fail_open() {
  local sid="$1" src="$2" cmd="$3"
  echo "FAIL: $sid [$src] — fail-open directive (cannot exit non-zero): $cmd"
  FAIL=$((FAIL + 1))
}

reject_non_executable() {
  local sid="$1" src="$2" cmd="$3"
  echo "FAIL: $sid [$src] — verify is prose, not a runnable command: $cmd"
  FAIL=$((FAIL + 1))
}

# Many stories share one verify (e61s02…e76s02 all run the same installer
# test); same command at the same commit gives the same result, so run it once
# per gate_all and reuse the verdict for every story that declares it.
# Sets RUN_RC, RUN_OUT, and RUN_REUSED (1 when nothing new ran).
run_memoized() {
  local cmd="$1" key
  key=$(printf '%s' "$cmd" | cksum | tr -d ' ')
  if [ -n "${MEMO_DIR:-}" ] && [ -f "$MEMO_DIR/$key.rc" ]; then
    RUN_RC=$(cat "$MEMO_DIR/$key.rc")
    RUN_OUT=$(cat "$MEMO_DIR/$key.out")
    return 0
  fi
  RUN_REUSED=0
  RUN_OUT=$(run_with_timeout "$cmd") && RUN_RC=0 || RUN_RC=$?
  if [ -n "${MEMO_DIR:-}" ]; then
    printf '%s' "$RUN_RC" > "$MEMO_DIR/$key.rc"
    printf '%s' "$RUN_OUT" > "$MEMO_DIR/$key.out"
  fi
}

# A plain `a && b && c` chain shares no shell state between segments when it
# has no quoting, expansion, grouping, pipes, `;`, cd, export or assignment —
# so each segment can be cached on its own (test-adapter-render.sh prefixes ten
# different story verifies). Anything else is cached as one whole command.
is_plain_and_chain() {
  case "$1" in
    *\'*|*\"*|*\$*|*\`*|*\(*|*\)*|*\{*|*\}*|*\|*|*\;*|*=*|*\<*) return 1 ;;
  esac
  printf '%s' "$1" | grep -qE '(^|&&)[[:space:]]*(cd|export|source|\.)[[:space:]]' && return 1
  return 0
}

run_verify_cmd() {
  local cmd="$1" seg
  RUN_REUSED=1
  if ! is_plain_and_chain "$cmd"; then
    run_memoized "$cmd"
    return
  fi
  local rest="$cmd"
  while :; do
    seg=${rest%%&&*}
    run_memoized "$(printf '%s' "$seg" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ "$RUN_RC" -eq 0 ] || return
    [ "$seg" = "$rest" ] && return
    rest=${rest#*&&}
  done
}

run_story_verify() {
  local sid="$1" src="$2" cmd="$3"

  if ! is_executable_verify "$cmd"; then
    reject_non_executable "$sid" "$src" "$cmd"
    return 1
  fi
  if is_fail_open_directive "$cmd"; then
    reject_fail_open "$sid" "$src" "$cmd"
    return 1
  fi

  run_verify_cmd "$cmd"
  local note=""
  [ "$RUN_REUSED" -eq 1 ] && note=" (shared result)"
  if [ "$RUN_RC" -eq 0 ]; then
    echo "PASS: $sid$note"
    PASS=$((PASS + 1))
    return 0
  fi
  echo "FAIL: $sid [$src]$note — $cmd"
  echo "      output: $(echo "$RUN_OUT" | tail -3 | tr '\n' ' ')"
  FAIL=$((FAIL + 1))
  return 1
}

gate_all() {
  local sid src status cmd
  MEMO_DIR=$(mktemp -d)
  while IFS=$'\t' read -r sid src status cmd; do
    [ -z "${sid:-}" ] && continue
    if [ -n "$TARGET" ] && [ "$sid" != "$TARGET" ]; then
      continue
    fi
    if [ -z "$TARGET" ] && [ "$status" != "$GATED_STATUS" ]; then
      echo "SKIP: $sid (status: $status)"
      SKIP=$((SKIP + 1))
      continue
    fi
    run_story_verify "$sid" "$src" "$cmd" || true
  done < <(extract_records)
  rm -rf "$MEMO_DIR"
  MEMO_DIR=""
}

# Shared-command proof: stories that declare the same verify run it once, yet
# each story still gets its own verdict — a failing shared command fails every
# story that declares it, never just the first.
self_test_shared_commands() {
  local root="$1/shared" out runs
  mkdir -p "$root/specs/epics/e98-shared"
  cat > "$root/specs/epics/e98-shared/epic.yaml" <<YAML
id: e98
title: shared-command capsule
stories:
  - id: e98s01
    status: done
    verify: printf x >> $root/ok-runs && test -d $root/specs
  - id: e98s02
    status: done
    verify: printf x >> $root/ok-runs && test -d $root/specs
  - id: e98s03
    status: done
    verify: printf x >> $root/bad-runs && test -f $root/missing
  - id: e98s04
    status: done
    verify: printf x >> $root/bad-runs && test -f $root/missing
  - id: e98s05
    status: done
    verify: printf x >> $root/seg-runs && test -d $root/specs
  - id: e98s06
    status: done
    verify: printf x >> $root/seg-runs && test -d $root/specs/epics
  - id: e98s07
    status: done
    verify: printf x >> $root/seg-runs && test -f $root/missing
YAML
  out=$(EXTRACT_ROOT="$root" TARGET="" PASS=0 FAIL=0 SKIP=0 gate_all)
  local problems=0
  runs=$(wc -c < "$root/ok-runs" | tr -d ' ')
  [ "$runs" = "1" ] || { echo "FAIL: self-test — shared passing command ran $runs times, want 1"; problems=$((problems + 1)); }
  runs=$(wc -c < "$root/bad-runs" | tr -d ' ')
  [ "$runs" = "1" ] || { echo "FAIL: self-test — shared failing command ran $runs times, want 1"; problems=$((problems + 1)); }
  runs=$(wc -c < "$root/seg-runs" | tr -d ' ')
  [ "$runs" = "1" ] || { echo "FAIL: self-test — shared && segment ran $runs times, want 1"; problems=$((problems + 1)); }
  local sid
  for sid in e98s01 e98s02 e98s05 e98s06; do
    echo "$out" | grep -q "^PASS: $sid" || { echo "FAIL: self-test — $sid not reported PASS"; problems=$((problems + 1)); }
  done
  for sid in e98s03 e98s04 e98s07; do
    echo "$out" | grep -q "^FAIL: $sid" || { echo "FAIL: self-test — $sid not reported FAIL"; problems=$((problems + 1)); }
  done
  [ "$problems" -eq 0 ]
}

# Anti-vacuity proof: seed a capsule whose done story must fail, and one that
# must pass, then require the runner to agree. A gate that cannot fail is the
# defect this script exists to close (#96/#106) — so it must prove otherwise.
run_self_test() {
  echo "=== run-story-verify self-test ==="
  local tmp_root
  tmp_root=$(mktemp -d)
  trap 'rm -rf "$tmp_root"' EXIT

  mkdir -p "$tmp_root/specs/epics/e99-selftest"
  cat > "$tmp_root/specs/epics/e99-selftest/epic.yaml" <<'YAML'
id: e99
title: self-test capsule
stories:
  - id: e99s01
    title: passing story
    status: done
    verify: test -d specs
  - id: e99s02
    title: failing story
    status: done
    verify: test -f /nonexistent/path/for/story-verify-self-test
  - id: e99s03
    title: fail-open story
    status: done
    verify: test -f /nonexistent || true
  - id: e99s04
    title: prose story
    status: done
    verify: node bin/bigpowers.js setup (interactive in TTY)
  - id: e99s05
    title: backlog story is not gated
    status: backlog
    verify: test -f /nonexistent/should/not/run
YAML

  local records
  records=$("$PYTHON" "$REPO_ROOT/scripts/lib/extract-story-verify.py" "$tmp_root")

  local checked=0 problems=0
  local sid src status cmd
  while IFS=$'\t' read -r sid src status cmd; do
    [ -z "${sid:-}" ] && continue
    checked=$((checked + 1))
    case "$sid" in
      e99s01)
        if is_fail_open_directive "$cmd" || ! is_executable_verify "$cmd"; then
          echo "FAIL: self-test — genuine assertion rejected: $cmd"; problems=$((problems + 1))
        elif ! run_with_timeout "$cmd" >/dev/null; then
          echo "FAIL: self-test — passing fixture did not pass"; problems=$((problems + 1))
        fi
        ;;
      e99s02)
        if run_with_timeout "$cmd" >/dev/null; then
          echo "FAIL: self-test — failing fixture exited 0 (gate cannot fail)"; problems=$((problems + 1))
        fi
        ;;
      e99s03)
        if ! is_fail_open_directive "$cmd"; then
          echo "FAIL: self-test — fail-open directive not detected: $cmd"; problems=$((problems + 1))
        fi
        ;;
      e99s04)
        if is_executable_verify "$cmd"; then
          echo "FAIL: self-test — prose accepted as a command: $cmd"; problems=$((problems + 1))
        fi
        ;;
      e99s05)
        if [ "$status" = "$GATED_STATUS" ]; then
          echo "FAIL: self-test — backlog story reported as done"; problems=$((problems + 1))
        fi
        ;;
    esac
  done <<EOF
$records
EOF

  rm -rf "$tmp_root"
  trap - EXIT

  self_test_shared_commands "$tmp_root" || problems=$((problems + 1))

  if [ "$checked" -lt 5 ]; then
    echo "FAIL: self-test — extractor found $checked/5 fixture stories"
    return 1
  fi
  if [ "$problems" -gt 0 ]; then
    echo "FAIL: self-test — $problems assertion(s) failed"
    return 1
  fi
  echo "PASS: self-test — gate fails on broken stories, passes on sound ones"
  return 0
}

if [ "$TARGET" = "--self-test" ]; then
  run_self_test
  exit $?
fi

gate_all

echo ""
echo "Results: $PASS PASS, $FAIL FAIL, $SKIP SKIP"

if [ -n "$TARGET" ] && [ "$((PASS + FAIL))" -eq 0 ]; then
  echo "ERROR: no story matching '$TARGET' declares a verify: command" >&2
  exit 2
fi

[ "$FAIL" -eq 0 ]
