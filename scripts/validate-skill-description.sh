#!/usr/bin/env bash
# story: e45s02
# CSO description discipline — max 1024 chars, no workflow-summary leakage.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_ROOT="$REPO_ROOT/skills"
[[ -d "$SKILLS_ROOT" ]] || SKILLS_ROOT="$REPO_ROOT"

MAX_LEN=1024
ERRORS=0

audit_skill_description_cso() {
  local path="$1"
  local skill desc len

  skill="$(basename "$(dirname "$path")")"
  desc="$(
    awk 'BEGIN{n=0} /^---$/{n++; next} n==1{print; next} n>=2{exit}' "$path" \
      | grep -E '^description:' | head -1 | sed 's/^description:[[:space:]]*//' | sed 's/^"//;s/"$//'
  )"

  if [[ -z "$desc" ]]; then
    echo "FAIL: $skill — missing description frontmatter"
    ERRORS=$((ERRORS + 1))
    return
  fi

  len=${#desc}
  if (( len > MAX_LEN )); then
    echo "FAIL: $skill — description ${len} chars (max ${MAX_LEN})"
    ERRORS=$((ERRORS + 1))
  fi

  # Workflow-summary leakage: numbered steps, phase chains, verify prose in description
  local leak=0
  if echo "$desc" | grep -qE '(^|[[:space:]])([0-9]+\.|Step [0-9]+|First,|Then,|Finally,|→ verify:|HARD GATE|Process:|Workflow:)'; then
    leak=1
  fi
  if echo "$desc" | grep -qE '(discover →|scope-work →|plan-work →|develop-tdd →|verify-work →|→ .* → )'; then
    leak=1
  fi
  if (( leak )); then
    echo "FAIL: $skill — workflow-summary leakage in description (keep triggers only; move steps to body)"
    ERRORS=$((ERRORS + 1))
  fi

  if echo "$desc" | grep -qE 'model:[[:space:]]*(haiku|sonnet|opus)'; then
    echo "FAIL: $skill — model hint belongs in frontmatter, not description"
    ERRORS=$((ERRORS + 1))
  fi
}

if [[ $# -gt 0 ]]; then
  for f in "$@"; do
    [[ -f "$f" ]] || { echo "FAIL: not found: $f" >&2; exit 1; }
    audit_skill_description_cso "$f"
  done
else
  while IFS= read -r f; do
    audit_skill_description_cso "$f"
  done < <(find "$SKILLS_ROOT" -maxdepth 2 -name SKILL.md | sort)
fi

if (( ERRORS > 0 )); then
  echo "validate-skill-description: $ERRORS issue(s)" >&2
  exit 1
fi

echo "validate-skill-description: PASS"
