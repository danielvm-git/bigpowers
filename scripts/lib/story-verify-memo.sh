#!/usr/bin/env bash
# story: BUG-2026-10-30-compliance-akita-masked
# Memoized verify execution for run-story-verify.sh. The caller defines
# run_with_timeout and may set MEMO_DIR (one per gate_all run).

if [ -n "${STORY_VERIFY_MEMO_LOADED:-}" ]; then return 0; fi
STORY_VERIFY_MEMO_LOADED=1

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

run_memoized_chain() {
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
