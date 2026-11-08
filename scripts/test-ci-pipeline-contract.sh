#!/usr/bin/env bash
# story: BUG-2026-10-25-release-not-gated BUG-2026-10-25-pages-not-gated
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
#   6. the Pages deploy lives either in the pipeline (needing every gate job) or
#      in deploy.yml, where a workflow_run trigger on "Test Build Release" plus
#      a conclusion == 'success' / head_branch == 'main' condition is the gate.
#      Either way a red gate cannot publish (BUG-2026-10-25-pages-not-gated).
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

def needs_of(job):
    needs = job.get("needs", [])
    return {needs} if isinstance(needs, str) else set(needs)

def ancestors(jobs, name):
    seen, todo = set(), list(needs_of(jobs.get(name, {})))
    while todo:
        n = todo.pop()
        if n not in seen:
            seen.add(n)
            todo.extend(needs_of(jobs.get(n, {})))
    return seen

def deploys_pages(job):
    return any(str(st.get("uses", "")).startswith("actions/deploy-pages@")
               for st in job.get("steps") or [])

def main_only(cond):
    return ("refs/heads/main" in cond and
            ("github.event_name == 'push'" in cond or "workflow_dispatch" in cond))

def on_block(doc):
    # PyYAML parses the bare key `on` as boolean True.
    return doc.get("on", doc.get(True)) or {}

def run_gated_by_pipeline(doc, job_name):
    """A deploy outside the pipeline is legal only when the pipeline gates it:
    workflow_run on Test Build Release + completed, and a job on the deploy's own
    needs: chain requires a successful run on main. Gating propagates through
    needs:, so the condition may sit on build rather than deploy. This keeps
    BUG-2026-10-25-pages-not-gated fixed."""
    onb = on_block(doc)
    if not isinstance(onb, dict):
        return False
    wr = onb.get("workflow_run") or {}
    if not isinstance(wr, dict):
        return False
    wfs = wr.get("workflows") or []
    wfs = [wfs] if isinstance(wfs, str) else list(wfs)
    if "Test Build Release" not in wfs:
        return False
    types = wr.get("types") or []
    types = [types] if isinstance(types, str) else list(types)
    if "completed" not in types:
        return False
    jobs = doc.get("jobs") or {}
    for name in {job_name} | ancestors(jobs, job_name):
        cond = str((jobs.get(name) or {}).get("if", ""))
        if "conclusion == 'success'" in cond and "head_branch == 'main'" in cond:
            return True
    return False

pipe_path = os.path.join(d, "test-build-release.yml")
if not os.path.isfile(pipe_path):
    bad.append("test-build-release.yml missing")
else:
    pipe = load(pipe_path)
    jobs = pipe.get("jobs", {})
    missing = GATES - set(jobs)
    if missing:
        bad.append(f"pipeline lacks gate jobs: {sorted(missing)}")
    # Gate jobs: the four named ones plus any other job that needs nothing —
    # a new root job is a gate until it says otherwise with a needs: edge.
    gate_jobs = (GATES | {n for n, j in jobs.items() if not needs_of(j)}) - {"release"}
    rel = jobs.get("release")
    if not rel:
        bad.append("pipeline has no release job")
    pages = [n for n, j in jobs.items() if deploys_pages(j)]
    for name in pages:
        job, up = jobs[name], ancestors(jobs, name)
        if not gate_jobs <= up:
            bad.append(f"{name}: Pages deploy does not need: {sorted(gate_jobs - up)}")
        conds = [str(jobs[n].get("if", "")) for n in up | {name} if n in jobs]
        if any("always()" in c or "cancelled()" in c for c in conds):
            bad.append(f"{name}: Pages deploy runs even when a gate fails (always()/cancelled())")
        if not any(main_only(c) for c in conds):
            bad.append(f"{name}: Pages deploy is not limited to main")
        if cancels(pipe.get("concurrency")) or cancels(job.get("concurrency")):
            bad.append(f"{name}: Pages deploy can be cancelled in progress")
        if not isinstance(job.get("concurrency"), dict) or not job["concurrency"].get("group"):
            bad.append(f"{name}: Pages deploy has no concurrency group")
    if rel:
        needs = needs_of(rel)
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

# Rule 6, v3 pair: exactly one Pages deploy, either inside the pipeline (gated by
# needs: on every gate job) or in deploy.yml (gated by a successful pipeline run).
# Anywhere else is an ungated deploy path.
deploy_sites = []
for path in sorted(glob.glob(os.path.join(d, "*.yml"))):
    fname = os.path.basename(path)
    doc = load(path)
    for job_name, job in (doc.get("jobs") or {}).items():
        if not deploys_pages(job):
            continue
        where = f"{fname}:{job_name}"
        if fname == "test-build-release.yml":
            deploy_sites.append(where)  # needs: edge already asserted above
        elif fname == "deploy.yml":
            if not run_gated_by_pipeline(doc, job_name):
                bad.append(f"{where}: deploy.yml is not gated by a successful "
                           "Test Build Release run on main (workflow_run + conclusion/head_branch)")
            else:
                deploy_sites.append(where)
        else:
            bad.append(f"{where}: Pages deploy outside the v3 pair "
                       "(move it to deploy.yml, gated by workflow_run)")
if not deploy_sites:
    bad.append("no Pages deploy job in test-build-release.yml or deploy.yml")

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
  local deploy="actions/deploy-pages@cd2ce8fcbc39b97be8ca5fce6e763baed58fa128"
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
  pages-build:
    needs: [sync, verification-gates, skill-verify, story-verify]
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-22.04
    timeout-minutes: 15
    steps: [{run: "true"}]
  pages-deploy:
    needs: pages-build
    runs-on: ubuntu-22.04
    timeout-minutes: 15
    concurrency: {group: pages, cancel-in-progress: false}
    steps: [{uses: "$deploy"}]
YAML
  }
  expect() { # $1 = label, $2 = want pass|fail, $3 = dir
    local out
    if out=$(check_dir "$3" 2>&1); then got=pass; else got=fail; fi
    # A crash is not a verdict: it would make every "expect fail" case pass
    # for the wrong reason and hide a broken checker.
    if grep -q 'Traceback (most recent call last)' <<<"$out"; then
      echo "FAIL ($1): checker crashed instead of returning a verdict"; ok=0; return
    fi
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

  write_fixture "$tmp/pages-needs"
  sed -i.bak '/pages-build:/{n;s/needs: \[.*\]/needs: [sync]/;}' "$tmp/pages-needs/test-build-release.yml"
  expect "Pages deploy missing gate needs fails" fail "$tmp/pages-needs"

  write_fixture "$tmp/pages-always"
  sed -i.bak '/pages-deploy:/{n;s/needs: pages-build/needs: pages-build\
    if: always()/;}' "$tmp/pages-always/test-build-release.yml"
  expect "Pages deploy with always() fails" fail "$tmp/pages-always"

  write_fixture "$tmp/pages-anyref"
  sed -i.bak '/pages-build:/{n;n;s/if: .*/if: github.event_name == '"'push'"'/;}' "$tmp/pages-anyref/test-build-release.yml"
  expect "Pages deploy not limited to main fails" fail "$tmp/pages-anyref"

  write_fixture "$tmp/pages-cancel"
  sed -i.bak 's/group: pages, cancel-in-progress: false/group: pages, cancel-in-progress: true/' "$tmp/pages-cancel/test-build-release.yml"
  expect "cancellable Pages deploy fails" fail "$tmp/pages-cancel"

  # v3 pair: the deploy may leave the pipeline, but only behind a workflow_run
  # gate on a successful run — the invariant behind BUG-2026-10-25-pages-not-gated.
  write_deploy_fixture() { # $1 = dir, $2 = job if-condition, $3 = on: block
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
    cat > "$1/deploy.yml" <<YAML
$3
jobs:
  deploy:
    if: $2
    runs-on: ubuntu-22.04
    timeout-minutes: 15
    steps: [{uses: "$deploy"}]
YAML
  }
  local wr_on="on:
  workflow_run:
    workflows: [\"Test Build Release\"]
    types: [completed]"
  local gated="github.event.workflow_run.conclusion == 'success' && github.event.workflow_run.head_branch == 'main'"

  write_deploy_fixture "$tmp/deploy-ok" "$gated" "$wr_on"
  expect "v3 pair: deploy.yml gated by workflow_run passes" pass "$tmp/deploy-ok"

  # Gating propagates through needs:, so the condition may sit on an ancestor —
  # this is the shape the real deploy.yml uses (gate on build, deploy needs build).
  write_deploy_fixture "$tmp/deploy-needs-ok" "true" "$wr_on"
  sed -i.bak 's|^jobs:|jobs:\n  build:\n    if: github.event.workflow_run.conclusion == '\''success'\'' \&\& github.event.workflow_run.head_branch == '\''main'\''\n    runs-on: ubuntu-22.04\n    timeout-minutes: 10\n    steps: [{run: "true"}]|' "$tmp/deploy-needs-ok/deploy.yml"
  sed -i.bak '/^  deploy:/a\
    needs: build' "$tmp/deploy-needs-ok/deploy.yml"
  expect "deploy gated via a needs: ancestor passes" pass "$tmp/deploy-needs-ok"

  write_deploy_fixture "$tmp/deploy-ungated" "github.event.workflow_run.head_branch == 'main'" "$wr_on"
  expect "deploy.yml without a success gate fails" fail "$tmp/deploy-ungated"

  write_deploy_fixture "$tmp/deploy-norun" "$gated" "on: push"
  expect "deploy.yml not triggered by workflow_run fails" fail "$tmp/deploy-norun"

  write_fixture "$tmp/pages-split"
  printf 'on: push\njobs:\n  deploy: {runs-on: ubuntu-22.04, timeout-minutes: 15, steps: [{uses: %s}]}\n' \
    "$deploy" > "$tmp/pages-split/docs-site.yml"
  expect "Pages deploy in an unrelated workflow fails" fail "$tmp/pages-split"

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
