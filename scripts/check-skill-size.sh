#!/usr/bin/env bash
# Skill size guard — enforces tiered line caps on every */SKILL.md file.
# Run after any SKILL.md edits to validate size compliance.
# Critical-path skills: 150 lines max. All others: 120 lines max.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

ERRORS=0

report_oversize() {
  echo "FAIL: $*" >&2
  ERRORS=$((ERRORS + 1))
}

# Critical-path skills with 150-line cap
CRITICAL_PATH=(
  "survey-context"
  "run-planning"
  "scope-work"
  "slice-tasks"
  "plan-work"
  "plan-release"
  "define-success"
  "kickoff-branch"
  "develop-tdd"
  "execute-plan"
  "build-epic"
  "verify-work"
  "audit-code"
  "request-review"
  "release-branch"
  "orchestrate-project"
  "investigate-bug"
  "diagnose-root"
  "fix-bug"
  "session-state"
  "seed-conventions"
  "migrate-spec"
  "elaborate-spec"
  "grill-me"
  "grill-with-docs"
)

# Check all */SKILL.md files
for skill_file in */SKILL.md; do
  skill_name="${skill_file%/SKILL.md}"
  line_count=$(wc -l < "$skill_file")

  # Determine cap based on critical-path membership
  is_critical=0
  for critical in "${CRITICAL_PATH[@]}"; do
    if [[ "$skill_name" == "$critical" ]]; then
      is_critical=1
      break
    fi
  done

  if [[ $is_critical -eq 1 ]]; then
    CAP=150
  else
    CAP=120
  fi

  if [[ $line_count -gt $CAP ]]; then
    report_oversize "$skill_name/SKILL.md is $line_count lines (cap $CAP)"
  fi
done

# Summary
echo "---"
if [[ "$ERRORS" -eq 0 ]]; then
  echo "check-skill-size: ALL within cap"
  exit 0
else
  echo "check-skill-size: $ERRORS file(s) over cap" >&2
  exit 1
fi
