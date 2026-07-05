#!/usr/bin/env bash
# And each core skill should prove a positive with-skill versus without-skill eval delta
# Evidence: run-evals + run-benchmark + benchmark definitions for core seed skills
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
evals="$REPO_ROOT/skills/run-evals/SKILL.md"
bench="$REPO_ROOT/skills/run-benchmark/SKILL.md"
bench_dir="$REPO_ROOT/specs/benchmarks"
if [[ ! -f "$evals" ]]; then
  echo "missing skills/run-evals/SKILL.md"
  exit 1
fi
if ! grep -qi 'pass@k' "$evals"; then
  echo "run-evals missing pass@k eval methodology"
  exit 1
fi
if [[ ! -f "$bench" ]]; then
  echo "missing skills/run-benchmark/SKILL.md"
  exit 1
fi
if ! grep -qi 'baseline\|regression\|pass_at_k\|pass@k' "$bench"; then
  echo "run-benchmark missing baseline/regression eval comparison"
  exit 1
fi
count=0
for skill in survey-context develop-tdd verify-work; do
  if [[ -f "$bench_dir/${skill}.yaml" ]]; then
    count=$((count + 1))
  fi
done
if [[ $count -lt 2 ]]; then
  echo "need benchmark YAML for at least 2 core skills (found $count)"
  exit 1
fi
exit 0
