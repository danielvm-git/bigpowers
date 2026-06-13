#!/usr/bin/env bash
# project-survey.sh — automated project status for session-start hooks

set -euo pipefail

# 1. Gather file existence info
has_conventions=$([[ -f "CONVENTIONS.md" ]] && echo "true" || echo "false")
has_claude=$([[ -f "CLAUDE.md" ]] && echo "true" || echo "false")
has_specs=$([[ -d "specs" ]] && echo "true" || echo "false")

# 2. Scan specs/ (YAML-first)
specs_files=""
if [[ "$has_specs" == "true" ]]; then
  specs_files=$( {
    ls specs/*.yaml 2>/dev/null || true
    ls specs/product/*.yaml 2>/dev/null || true
    ls specs/*.md 2>/dev/null || true
  } | xargs -n1 basename 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//')
fi

# 3. Git state
current_branch=$(git branch --show-current 2>/dev/null || echo "not-a-repo")
git_status=$(git status --short 2>/dev/null | head -n 5 | tr '\n' ' ' | sed 's/"/\\"/g')
recent_logs=$(git log --oneline -3 2>/dev/null | tr '\n' ' ' | sed 's/"/\\"/g')

# 4. Phase mapping logic (YAML-first)
phase="Discover"
if [[ -f "specs/state.yaml" ]]; then
  flow=$(grep -E '^active_flow:' specs/state.yaml | sed 's/active_flow:[[:space:]]*//')
  case "$flow" in
    fix_bug) phase="Bug" ;;
    build_epic) phase="Execute" ;;
    planning) phase="Plan" ;;
  esac
elif [[ -f "specs/release-plan.yaml" ]]; then
  phase="Plan"
elif [[ -f "specs/product/SCOPE_LATEST.yaml" ]] || [[ -f "specs/SCOPE.md" ]]; then
  phase="Design"
elif [[ "$current_branch" != "main" && "$current_branch" != "master" ]]; then
  phase="Initiate"
fi

if [[ -f "specs/DIAGNOSIS.md" ]]; then
  phase="Bug"
fi

# 5. Output concise text for context injection
cat <<EOF
[PROJECT SURVEY]
Phase: $phase
Branch: $current_branch
Files: CONVENTIONS=$has_conventions, CLAUDE=$has_claude, SPECS=$has_specs
Specs Found: $specs_files
Git Status: $git_status
Recent Logs: $recent_logs

Welcome to Bigpowers. I have analyzed the project state. 
You are currently in the '$phase' phase on the '$current_branch' branch.
EOF

if [[ -f "specs/release-plan.yaml" ]]; then
  echo "release-plan.yaml found. Read specs/state.yaml for active epic/story."
fi
