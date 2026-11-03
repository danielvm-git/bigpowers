#!/usr/bin/env bash
# story: BUG-2026-11-03-atomic-yaml-writes
# test-atomic-writes.sh — regression guard for in-place YAML/JSON truncation (#181).
#
# `path.write_text(...)` truncates the destination, then streams the new bytes.
# A reader in that window sees a half file and dies with a YAML ScannerError.
# The fix writes a same-directory temp file, fsyncs it, and os.replace()s it.
#
#   (a) anti-vacuity: the truncating shape IS observable by a concurrent reader
#   (b) atomic_write_text is never observable half-written
#   (c) static guard: the runtime state writers use the helper, not bare writes
#
# Usage: bash scripts/test-atomic-writes.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
cd "$REPO_ROOT"
source scripts/lib/python-env.sh
source scripts/lib/test-assertions.sh
resolve_python
TA_PASS=0
TA_FAIL=0

echo "=== test-atomic-writes.sh ==="

# ── (a)+(b) race harness ────────────────────────────────────────────────────
# One PROCESS writes a large YAML document N times while this process parses the
# file in a tight loop and counts parse errors. Two processes, not two threads:
# the GIL makes a thread-based control flaky, and a flaky anti-vacuity check is
# worse than none. Plain write_text must be caught (otherwise the harness is
# blind); atomic_write_text must never be caught.
RACE=$($PYTHON - <<'PY'
import os, subprocess, sys, tempfile
from pathlib import Path

KEYS = 400_000
PAYLOAD = "".join(f"key_{i}: {'x' * 40}\n" for i in range(KEYS))  # ~19 MB
EXPECTED = len(PAYLOAD.encode())
ITERATIONS = 8
ATTEMPTS = 3

PRODUCER = """
import sys
from pathlib import Path
sys.path.insert(0, "scripts/lib")
from atomic_write import atomic_write_text

mode, target, keys, iterations = sys.argv[1], Path(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4])
payload = "".join(f"key_{i}: {'x' * 40}\\n" for i in range(keys))
for _ in range(iterations):
    if mode == "plain":
        target.write_text(payload, encoding="utf-8")
    else:
        atomic_write_text(target, payload)
"""

def run(mode):
    """Count samples where a reader saw a size that is neither empty nor final.

    Sampling the size instead of parsing it is what makes the control reliable:
    a 19 MB write keeps the truncate window open for milliseconds, so a poller
    always lands inside it, while os.replace() swaps the inode and never shows
    an intermediate size at all.
    """
    partial = 0
    for _attempt in range(ATTEMPTS):
        target = Path(tempfile.mkdtemp(prefix="atomic-race-")) / "state.yaml"
        target.write_text(PAYLOAD, encoding="utf-8")
        proc = subprocess.Popen([sys.executable, "-c", PRODUCER, mode, str(target), str(KEYS), str(ITERATIONS)])
        seen = 0
        while proc.poll() is None:
            try:
                size = os.path.getsize(target)
            except FileNotFoundError:
                size = -1
            if size not in (EXPECTED, -1):
                seen += 1
        proc.wait()
        partial += seen
        if partial:
            break
    return partial

print(f"{run('plain')} {run('atomic')}")
PY
)

TRUNCATING_PARTIALS=$(echo "$RACE" | awk '{print $1}')
ATOMIC_PARTIALS=$(echo "$RACE" | awk '{print $2}')

[[ "${TRUNCATING_PARTIALS:-0}" -gt 0 ]] \
  && ta_pass "(a) plain write_text exposes a partial file ($TRUNCATING_PARTIALS samples)" \
  || ta_fail "(a) plain write_text was never caught — the harness cannot see the race"

[[ "${ATOMIC_PARTIALS:-1}" -eq 0 ]] \
  && ta_pass "(b) atomic_write_text: 0 partial samples" \
  || ta_fail "(b) atomic_write_text exposed $ATOMIC_PARTIALS partial samples"

# ── (c) static guard: runtime state writers go through the helper ───────────
# Fixtures, one-off migration patchers and test harnesses may write freely; the
# files that hold live spec state may not.
WATCHED=(
  "scripts/yaml-tools.py"
  "scripts/sync-bugs-registry.sh"
  "scripts/lib/trace-stories.py"
  "scripts/lib/trace_renderer.py"
  "scripts/lib/blind-spots.py"
  "scripts/lib/blind-spot-checks.py"
  "scripts/lib/ab_report.py"
  "scripts/lib/run-benchmark.py"
  "scripts/okf-add-references.py"
  "scripts/lib/srp_engine_okf.py"
)
HITS=""
for f in "${WATCHED[@]}"; do
  [ -f "$f" ] || continue
  # bare truncating writes: .write_text(...) or open(..., "w"), minus tmp targets
  found=$(grep -nE '\.write_text\(|\.open\(["'"'"']w["'"'"']|open\([^)]*["'"'"']w["'"'"']' "$f" \
    | grep -vE 'atomic_write|\.tmp|tmp_name' || true)
  [ -n "$found" ] && HITS+="$f:"$'\n'"$found"$'\n'
done

[[ -z "$HITS" ]] \
  && ta_pass "(c) all ${#WATCHED[@]} watched state writers use atomic_write" \
  || ta_fail "(c) truncating writes still in state writers:"$'\n'"$HITS"

echo "$TA_PASS passed, $TA_FAIL failed"
[[ "$TA_FAIL" -eq 0 ]]
