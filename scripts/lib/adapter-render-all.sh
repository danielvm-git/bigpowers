#!/usr/bin/env bash
# story: #138
# adapter-render-all.sh — render every skill through one adapter in a single
# bash process.
#
# srp-engine.py --all used to spawn one `bash` (plus three `jq`) per
# skill×adapter — ~1,539 bash and ~4,600 jq processes from one Python process.
# On constrained Windows sessions that exhausts process-creation resources: the
# run dies with STATUS_DLL_INIT_FAILED (0xC0000142) and then hangs on orphaned
# children. Sourcing the adapter once and calling render_skill() in a loop keeps
# the exact same rendering code while collapsing the process count to one per
# adapter and removing the per-render jq calls.
#
# Input is a NUL-delimited stream written by srp-engine.py, five fields per
# skill in order — name, description, model, body, pi body — each NUL-terminated
# so field content may contain newlines.
#
# Adapters without a stdin entrypoint (continue, omp, zed) define render_skill
# but were never driven by srp-engine; they are skipped so behaviour is
# unchanged.
#
# Usage: adapter-render-all.sh <path-to-adapter.sh> <ir-stream-file>
set -u

adapter="$1"
stream="$2"

if [[ ! -f "$adapter" ]]; then
  echo "adapter-render-all: adapter not found: $adapter" >&2
  exit 1
fi
if [[ ! -f "$stream" ]]; then
  echo "adapter-render-all: IR stream not found: $stream" >&2
  exit 1
fi

# A spawned adapter with no stdin entrypoint is a no-op; match that.
if ! grep -q '\[\[ ! -t 0 \]\]' "$adapter"; then
  exit 0
fi

adapter_id="$(basename "$adapter" .sh)"

# Sourcing the adapter runs its stdin entrypoint; point stdin at /dev/null so
# `[[ ! -t 0 ]]` is true but `cat` yields nothing and the entrypoint no-ops.
# shellcheck disable=SC1090
source "$adapter" < /dev/null

if ! declare -f render_skill >/dev/null 2>&1; then
  exit 0
fi

exec 3< "$stream"
status=0
while IFS= read -r -d '' IR_NAME <&3; do
  IFS= read -r -d '' IR_DESCRIPTION <&3
  IFS= read -r -d '' IR_MODEL <&3
  IFS= read -r -d '' IR_BODY <&3
  IFS= read -r -d '' IR_BODY_PI <&3

  IR_DESC_ESCAPED=$(echo "$IR_DESCRIPTION" | sed 's/\\/\\\\/g; s/"/\\"/g')
  if [[ "$adapter_id" == "pi" ]]; then
    IR_BODY_SKILL="$IR_BODY_PI"
  else
    IR_BODY_SKILL="$IR_BODY"
  fi

  if ! render_skill; then
    status=1
    break
  fi
done
exec 3<&-
exit "$status"
