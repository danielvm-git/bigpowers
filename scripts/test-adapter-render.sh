#!/usr/bin/env bash
# story: e37s05
# test-adapter-render.sh — render, path-traversal and hook-guard checks for
# every adapter, replacing 11 hand-written test-<target>-adapter.sh scripts.
#
# The 11 originals were the same five assertions with the target name
# substituted, none of them reachable from any gate, and they covered 11 of the
# 18 adapters that define render_skill(). Their fifth assertion was pure
# delegation to test-adapters.sh, which is already registry-driven.
#
# Adapters are discovered from scripts/adapters/*.sh, and each adapter's output
# directory variable is read out of its own source (they vary: *_SKILLS,
# *_RULES, *_EXT_DIR), so adding an adapter needs no edit here.
#
# Usage: bash scripts/test-adapter-render.sh
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
cd "$REPO_ROOT"

TA_PASS=0
TA_FAIL=0
TA_TMPDIR=""

source "$(dirname "${BASH_SOURCE[0]}")/lib/test-assertions.sh"
trap ta_cleanup EXIT

TA_TMPDIR=$(mktemp -d)
TMP_ROOT="$TA_TMPDIR"
echo "=== test-adapter-render.sh ==="

for adapter in scripts/adapters/*.sh; do
  id="$(basename "$adapter" .sh)"

  grep -q "^render_skill()" "$adapter" || continue

  # Adapters are sourced, not executed: several (continue, omp, zed) are stubs
  # with no stdin entrypoint and would silently no-op — and exit 0 — if run as
  # scripts. Sourcing and calling render_skill directly is how test-adapters.sh
  # drives them, and it exercises every adapter the same way.
  #
  # An adapter may read more than one output variable (gemini uses GEMINI_SKILLS
  # and GEMINI_EXT_DIR), so point all of them at the sandbox rather than
  # guessing which one matters.
  mapfile -t outvars < <(grep -oE '\$\{?[A-Z][A-Z0-9_]*_(SKILLS|RULES|EXT_DIR|OUT|COMMANDS|PROMPTS|HOOKS_DIR)[:-]' "$adapter" \
    | tr -d '${:-' | sort -u)
  if [[ ${#outvars[@]} -eq 0 ]]; then
    echo "  skip: $id — no output directory variable found"
    continue
  fi

  render_into() { # $1 = destination dir, $2 = skill name
    local dir="$1" nm="$2" v
    local -a envs=()
    for v in "${outvars[@]}"; do envs+=("$v=$dir"); done
    ( set +e
      env "${envs[@]}" bash -c '
        source "$1" 2>/dev/null || exit 1
        IR_NAME="$2"; IR_DESCRIPTION="test desc"; IR_BODY="test body"
        IR_DESC_ESCAPED="test desc"; IR_MODEL=""
        declare -f render_skill >/dev/null || exit 1
        render_skill
      ' _ "$PWD/$adapter" "$nm" >/dev/null 2>&1 )
  }

  dest="$TMP_ROOT/$id"
  mkdir -p "$dest"
  if render_into "$dest" "test-skill" && [[ -n "$(find "$dest" -mindepth 1 2>/dev/null)" ]]; then
    ta_pass "$id: render_skill writes an artifact from a SkillIR"
  else
    ta_fail "$id: render_skill produced no artifact (${outvars[*]})"
  fi

  # Path traversal must be refused — this is the security assertion the
  # per-target scripts carried and nothing else covers.
  #
  # Each adapter gets its own sandbox parent so the escape probe is isolated:
  # ../escape from <sandbox>/out lands in <sandbox>, and a single shared parent
  # would make one adapter's artifact fail every later adapter.
  sandbox="$TMP_ROOT/sandbox-$id"
  mkdir -p "$sandbox/out"
  if render_into "$sandbox/out" "../escape"; then
    ta_fail "$id: accepted a path-traversal skill name"
  else
    ta_pass "$id: rejects path traversal in skill name"
  fi
  if [[ -e "$sandbox/escape" ]]; then
    ta_fail "$id: path traversal escaped into $sandbox"
  else
    ta_pass "$id: traversal wrote nothing outside the destination"
  fi

  # Hook bundle + guard behaviour, only where the target ships hooks.
  hookdir="scripts/hooks/$id"
  guard="$hookdir/pre-tool-git-guard.sh"
  if [[ -f "$guard" ]]; then
    out="$(echo '{"tool_input":{"command":"git push --force origin main"}}' \
      | bash "$guard" 2>/dev/null || true)"
    grep -q 'block' <<<"$out" \
      && ta_pass "$id: pre-tool guard blocks a dangerous git command" \
      || ta_fail "$id: pre-tool guard did not block git push --force"
  fi
done

# The generic adapter-contract runner stays the source of truth for
# render_skill/wire_context wiring; assert it is green rather than restating it.
if bash scripts/test-adapters.sh 2>&1 | grep -q '0 failed'; then
  ta_pass "test-adapters.sh reports 0 failed across the registry"
else
  ta_fail "test-adapters.sh reported failures"
fi

echo "test-adapter-render: $TA_PASS passed, $TA_FAIL failed"
[[ "$TA_FAIL" -eq 0 ]] || exit 1
