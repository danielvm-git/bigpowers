#!/usr/bin/env bash
# story: BUG-2026-11-03-guard-git-flag-normalize
# test-guard-git-normalize.sh — the guard must judge git ARGV, not substrings (#184).
#
# Literal patterns miss `git -C repo <destructive>` and `reset -q --hard`: the
# destructive tokens survive, only their position changes. One fixture table
# pins four things:
#
#   (a) the shell hook (hooks/pre-tool-use.sh) reaches the expected verdict
#   (b) the TS extension reaches the same verdict — through evaluateBashCall(),
#       the function the tool_call handler calls, so protected-branch and commit
#       rules are compared too, not only the destructive-argv table
#   (c) the two agree with each other on every row — that is what "consistent
#       across Claude Code, Cursor and Gemini CLI modes" means
#   (d) the rules that share the hook (commits, protected branch, JSON
#       envelopes, the pi/OMP fallback) still behave
#
# Both sides run with GIT_BIGPOWERS_LAND stripped: land mode disables the
# protected-branch block, so an inherited value would let a developer's shell
# turn a red gate green (BUG-2026-11-03-guard-normalize-parity-vacuous).
#
# The row loop runs inside one Python process: every row x (hook + probe) with a
# Python start per row cost ~70s on a pyenv host, which is too much for a gate.
#
# Usage: bash scripts/test-guard-git-normalize.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
cd "$REPO_ROOT"
source scripts/lib/python-env.sh
source scripts/lib/test-assertions.sh
resolve_python
TA_PASS=0
TA_FAIL=0
FIXTURE="specs/verifications/fixtures/guard-git-normalize.yaml"

echo "=== test-guard-git-normalize.sh ==="

if [[ ! -f "$FIXTURE" ]]; then
  ta_fail "fixture missing: $FIXTURE"
  echo "$TA_PASS passed, $TA_FAIL failed"
  exit 1
fi

REPORT=$($PYTHON - "$FIXTURE" <<'PY'
import json, os, subprocess, sys, yaml

fixture = sys.argv[1]
# Ambient LAND mode disables the protected-branch block. A gate that depends on
# the developer's shell is not a gate (this masked a CI failure once).
ENV = {k: v for k, v in os.environ.items() if k != "GIT_BIGPOWERS_LAND"}
cases = yaml.safe_load(open(fixture, encoding="utf-8"))["cases"]
commands = [c["command"] for c in cases]

# (b) one node start for every row.
probe = subprocess.run(
    ["node", "scripts/omp-guard-probe.ts"],
    input=json.dumps(commands), capture_output=True, text=True,
)
if probe.returncode != 0:
    print(f"PROBE_ERROR {probe.stderr.strip().splitlines()[-1][:300] if probe.stderr.strip() else 'no stderr'}")
    sys.exit(0)
ts = json.loads(probe.stdout.strip().splitlines()[-1])

shell_fails = ts_fails = disagree = 0
for case, ts_verdict in zip(cases, ts):
    payload = json.dumps({"command": case["command"]})
    run = subprocess.run(
        ["bash", "hooks/pre-tool-use.sh"], input=payload, capture_output=True, text=True, env=ENV,
    )
    shell_verdict = "block" if run.returncode == 2 else "allow"
    expected = case["verdict"]
    if shell_verdict != expected:
        shell_fails += 1
        print(f"SHELL_FAIL expected={expected} got={shell_verdict} :: {case['command']}")
    if ts_verdict != expected:
        ts_fails += 1
        print(f"TS_FAIL expected={expected} got={ts_verdict} :: {case['command']}")
    if shell_verdict != ts_verdict:
        disagree += 1
        print(f"PARITY_FAIL shell={shell_verdict} ts={ts_verdict} :: {case['command']}")

print(f"RESULT rows={len(cases)} shell_fails={shell_fails} ts_fails={ts_fails} disagree={disagree}")
PY
)

if [[ "$REPORT" == PROBE_ERROR* ]]; then
  ta_fail "TS probe failed: ${REPORT#PROBE_ERROR }"
else
  # sed, not grep: grep exits 1 when there is nothing to show, and pipefail
  # would turn a perfectly green run into a failure.
  printf '%s\n' "$REPORT" | sed -n 's/^\(SHELL_FAIL\|TS_FAIL\|PARITY_FAIL\)/  \1/p'
  read -r _ ROWS SHELL_FAILS TS_FAILS DISAGREE <<< "$(grep '^RESULT' <<< "$REPORT")"
  ROWS=${ROWS#rows=}; SHELL_FAILS=${SHELL_FAILS#shell_fails=}
  TS_FAILS=${TS_FAILS#ts_fails=}; DISAGREE=${DISAGREE#disagree=}

  [ "${SHELL_FAILS:-1}" -eq 0 ] \
    && ta_pass "(a) shell hook matches all $ROWS fixture rows" \
    || ta_fail "(a) shell hook missed $SHELL_FAILS of $ROWS rows (see above)"
  [ "${TS_FAILS:-1}" -eq 0 ] \
    && ta_pass "(b) TS extension matches all $ROWS fixture rows" \
    || ta_fail "(b) TS extension missed $TS_FAILS of $ROWS rows (see above)"
  [ "${DISAGREE:-1}" -eq 0 ] \
    && ta_pass "(c) shell and TS agree on all $ROWS rows" \
    || ta_fail "(c) shell and TS disagree on $DISAGREE of $ROWS rows (see above)"
fi

# ── (d) the rules that share this hook must keep working ────────────────────
# The normalizer replaced the pattern loop in the same handler; a regression in
# the neighbouring checks (protected branches, Conventional Commits, the gemini
# JSON envelope, the pi/OMP fallback) would be invisible to the rows above.
json_cmd() { $PYTHON -c 'import json,sys;print(json.dumps({"command": sys.argv[1]}))' "$1"; }
adjacent() { # name want_rc command [hook]
  local name="$1" want="$2" command="$3" hook="${4:-hooks/pre-tool-use.sh}" rc
  json_cmd "$command" | env -u GIT_BIGPOWERS_LAND bash "$hook" >/dev/null 2>&1 && rc=0 || rc=$?
  [ "$rc" -eq "$want" ] || ta_fail "(d) $name: rc=$rc (want $want) — $command"
}
adjacent "plain status allowed" 0 "git status"
adjacent "conventional commit allowed" 0 'git commit -m "fix(scope): subject"'
adjacent "feature push allowed" 0 "git push origin feature/x"
adjacent "non-conventional commit blocked" 2 'git commit -m "bad message"'

DESTRUCTIVE="git reset --hard"
GEMINI_OUT=$(json_cmd "$DESTRUCTIVE" | env -u GIT_BIGPOWERS_LAND GIT_GUARDRAILS_MODE=gemini bash hooks/pre-tool-use.sh 2>&1)
echo "$GEMINI_OUT" | grep -q '"decision": *"deny"' \
  || ta_fail "(d) gemini mode must emit deny JSON, got: $(echo "$GEMINI_OUT" | head -c 120)"

PI_OUT=$(json_cmd "$DESTRUCTIVE" | env -u GIT_BIGPOWERS_LAND bash hooks/pre/bash.sh 2>&1)
echo "$PI_OUT" | grep -q '"decision":"block"' \
  || ta_fail "(d) pi/OMP fallback must emit block JSON, got: $(echo "$PI_OUT" | head -c 120)"

bash -n hooks/pre/bash.sh || ta_fail "(d) hooks/pre/bash.sh must parse"
grep -q "classify_git_argv" hooks/pre/bash.sh \
  || ta_fail "(d) pi/OMP fallback must use the normalized classifier"
ta_pass "(d) adjacent rules: commits, pushes, gemini JSON, pi fallback"

echo "$TA_PASS passed, $TA_FAIL failed"
[[ "$TA_FAIL" -eq 0 ]]
