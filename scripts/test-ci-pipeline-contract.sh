#!/usr/bin/env bash
# story: BUG-2026-10-25-release-not-gated
# test-ci-pipeline-contract.sh — the CI shape the portfolio template requires
# (danielvm-git/.github, docs/concept/github-actions-best-practices.md):
#
#   1. one pipeline, .github/workflows/test-build-release.yml, holds every gate
#      job and the release job; the workflows it replaced are gone
#   2. release needs: every gate job and runs only on push to main — a release
#      that does not wait for the gates publishes unverified builds
#   3. no ubuntu-latest; every non-local action is pinned to a 40-char SHA
#   4. every job has timeout-minutes
#   5. release and Pages never cancel a run in progress
#
# Agent workflows (agent-locks.yml, generated agentics-maintenance.yml) are
# exempt from 3–4 per migration plan v2.
#
# Usage: bash scripts/test-ci-pipeline-contract.sh [--self-test] [workflows-dir]
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
cd "$REPO_ROOT"
source scripts/lib/python-env.sh
resolve_python >/dev/null || exit 1

check_dir() { # $1 = workflows dir; prints violations, exits non-zero on any
  "$PYTHON" - "$1" <<'PY'
import glob, os, re, sys, yaml

d = sys.argv[1]
GATES = {"sync", "verification-gates", "skill-verify", "story-verify"}
RETIRED = ["publish.yml", "sync-skills.yml", "golden-suite.yml"]
EXEMPT = {"agent-locks.yml", "agentics-maintenance.yml"}
bad = []

def load(path):
    with open(path) as f:
        return yaml.safe_load(f) or {}

def cancels(block):
    # Literal true cancels; an expression or false does not cancel a push run.
    return isinstance(block, dict) and block.get("cancel-in-progress") is True

pipe_path = os.path.join(d, "test-build-release.yml")
if not os.path.isfile(pipe_path):
    bad.append("test-build-release.yml missing")
else:
    pipe = load(pipe_path)
    jobs = pipe.get("jobs", {})
    missing = GATES - set(jobs)
    if missing:
        bad.append(f"pipeline lacks gate jobs: {sorted(missing)}")
    rel = jobs.get("release")
    if not rel:
        bad.append("pipeline has no release job")
    else:
        needs = rel.get("needs", [])
        needs = {needs} if isinstance(needs, str) else set(needs)
        gate_jobs = set(jobs) - {"release"}
        if not gate_jobs <= needs:
            bad.append(f"release does not need: {sorted(gate_jobs - needs)}")
        cond = str(rel.get("if", ""))
        if "github.event_name == 'push'" not in cond or "refs/heads/main" not in cond:
            bad.append("release is not limited to push on main")
        if cancels(pipe.get("concurrency")) or cancels(rel.get("concurrency")):
            bad.append("release can be cancelled in progress")

for name in RETIRED:
    if os.path.exists(os.path.join(d, name)):
        bad.append(f"retired workflow still present: {name}")

docs = os.path.join(d, "docs-site.yml")
if os.path.isfile(docs) and cancels(load(docs).get("concurrency")):
    bad.append("docs-site.yml: Pages deploy can be cancelled in progress")

for path in sorted(glob.glob(os.path.join(d, "*.yml"))):
    name = os.path.basename(path)
    if name in EXEMPT:
        continue
    for job_name, job in (load(path).get("jobs") or {}).items():
        where = f"{name}:{job_name}"
        if "uses" in job:  # reusable-workflow call: no runner of its own
            continue
        if "ubuntu-latest" in str(job.get("runs-on", "")):
            bad.append(f"{where}: runs-on ubuntu-latest")
        if "timeout-minutes" not in job:
            bad.append(f"{where}: no timeout-minutes")
        for step in job.get("steps", []):
            uses = step.get("uses")
            if uses and not uses.startswith("./") and not re.search(r"@[0-9a-f]{40}$", uses):
                bad.append(f"{where}: action not SHA-pinned: {uses}")

for b in bad:
    print(f"FAIL: {b}")
sys.exit(1 if bad else 0)
PY
}

# Anti-vacuity: a conforming fixture passes, and each rule fails on its own breach.
self_test() {
  local tmp ok=1
  tmp=$(mktemp -d)
  trap "rm -rf '$tmp'" EXIT
  local pin="actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0"
  write_fixture() { # $1 = dir
    mkdir -p "$1"
    cat > "$1/test-build-release.yml" <<YAML
on: push
jobs:
  sync: {runs-on: ubuntu-22.04, timeout-minutes: 10, steps: [{uses: $pin}]}
  verification-gates: {runs-on: ubuntu-22.04, timeout-minutes: 15, steps: [{run: "true"}]}
  skill-verify: {runs-on: ubuntu-22.04, timeout-minutes: 10, steps: [{run: "true"}]}
  story-verify: {runs-on: ubuntu-22.04, timeout-minutes: 10, steps: [{run: "true"}]}
  release:
    needs: [sync, verification-gates, skill-verify, story-verify]
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-22.04
    timeout-minutes: 15
    concurrency: {group: release, cancel-in-progress: false}
    steps: [{run: "true"}]
YAML
  }
  expect() { # $1 = label, $2 = want pass|fail, $3 = dir
    if check_dir "$3" >/dev/null; then got=pass; else got=fail; fi
    if [ "$got" = "$2" ]; then echo "PASS ($1)"; else echo "FAIL ($1): got $got, want $2"; ok=0; fi
  }

  write_fixture "$tmp/good"; expect "conforming pipeline passes" pass "$tmp/good"

  write_fixture "$tmp/no-needs"
  sed -i.bak 's/needs: \[sync, verification-gates, skill-verify, story-verify\]/needs: [sync]/' "$tmp/no-needs/test-build-release.yml"
  expect "release missing gate needs fails" fail "$tmp/no-needs"

  write_fixture "$tmp/latest"
  sed -i.bak 's/runs-on: ubuntu-22.04, timeout-minutes: 15/runs-on: ubuntu-latest, timeout-minutes: 15/' "$tmp/latest/test-build-release.yml"
  expect "ubuntu-latest fails" fail "$tmp/latest"

  write_fixture "$tmp/tag"
  sed -i.bak "s|$pin|actions/checkout@v7|" "$tmp/tag/test-build-release.yml"
  expect "tag-pinned action fails" fail "$tmp/tag"

  write_fixture "$tmp/cancel"
  sed -i.bak 's/cancel-in-progress: false/cancel-in-progress: true/' "$tmp/cancel/test-build-release.yml"
  expect "cancellable release fails" fail "$tmp/cancel"

  write_fixture "$tmp/retired"; : > "$tmp/retired/publish.yml"
  expect "retired workflow present fails" fail "$tmp/retired"

  [ "$ok" -eq 1 ] && echo "OK: pipeline contract self-test" || { echo "pipeline contract self-test FAILED"; exit 1; }
}

if [ "${1:-}" = "--self-test" ]; then
  self_test
  exit 0
fi

dir="${1:-.github/workflows}"
if check_dir "$dir"; then
  echo "OK: CI pipeline contract ($dir)"
else
  echo "CI pipeline contract violated — see danielvm-git/.github docs/concept/github-actions-best-practices.md"
  exit 1
fi
