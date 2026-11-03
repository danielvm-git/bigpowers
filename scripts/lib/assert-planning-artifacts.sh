#!/usr/bin/env bash
# story: e86 / GH #183
# Mechanical artifact existence assertion for run-planning workflow steps.
set -euo pipefail

STEP="${1:-}"

if [[ -z "$STEP" ]]; then
  echo "Usage: bash scripts/lib/assert-planning-artifacts.sh <step_name>" >&2
  exit 1
fi

case "$STEP" in
  survey-context)
    if [[ ! -f specs/tech-architecture/tech-stack.md ]] && [[ ! -f specs/state.yaml ]]; then
      echo "ERROR [survey-context]: Neither specs/tech-architecture/tech-stack.md nor specs/state.yaml exists." >&2
      exit 1
    fi
    ;;

  scope-work)
    if [[ ! -f specs/product/SCOPE_LATEST.yaml ]] || [[ ! -s specs/product/SCOPE_LATEST.yaml ]]; then
      echo "ERROR [scope-work]: specs/product/SCOPE_LATEST.yaml is missing or empty." >&2
      exit 1
    fi
    ;;

  research-first)
    # Research can record in specs/product/PRIOR_ART.md or directly in specs/
    if [[ ! -f specs/product/PRIOR_ART.md ]] && [[ ! -f specs/product/SCOPE_LATEST.yaml ]]; then
      echo "ERROR [research-first]: Neither specs/product/PRIOR_ART.md nor specs/product/SCOPE_LATEST.yaml found." >&2
      exit 1
    fi
    ;;

  elaborate-spec)
    if [[ ! -f specs/planning-context.yaml ]] && [[ ! -f specs/product/SCOPE_LATEST.yaml ]]; then
      echo "ERROR [elaborate-spec]: specs/planning-context.yaml is missing." >&2
      exit 1
    fi
    ;;

  plan-release)
    if [[ ! -f specs/release-plan.yaml ]] || [[ ! -s specs/release-plan.yaml ]]; then
      echo "ERROR [plan-release]: specs/release-plan.yaml is missing or empty." >&2
      exit 1
    fi
    ;;

  slice-tasks)
    # Assert at least one task file exists in specs/epics/
    if ! find specs/epics -name "*-tasks.yaml" 2>/dev/null | grep -q .; then
      echo "ERROR [slice-tasks]: No tasks files (*-tasks.yaml) found in specs/epics/." >&2
      exit 1
    fi
    ;;

  *)
    echo "WARNING: Unknown step '$STEP' — skipping artifact assertion" >&2
    exit 0
    ;;
esac

echo "PASS: Planning artifacts asserted for step '$STEP'."
exit 0
