#!/usr/bin/env bash
# project-survey.sh — automated project status for session-start hooks

set -euo pipefail

# 1. Gather file existence info
has_conventions=$([[ -f "CONVENTIONS.md" ]] && echo "true" || echo "false")
has_claude=$([[ -f "CLAUDE.md" ]] && echo "true" || echo "false")
has_specs=$([[ -d "specs" ]] && echo "true" || echo "false")

# 2. Scan specs/
specs_files=""
if [[ "$has_specs" == "true" ]]; then
  specs_files=$(ls specs/*.md 2>/dev/null | xargs -n1 basename | tr '\n' ',' | sed 's/,$//')
fi

# 3. Git state
current_branch=$(git branch --show-current 2>/dev/null || echo "not-a-repo")
git_status=$(git status --short 2>/dev/null | head -n 5 | tr '\n' ' ' | sed 's/"/\\"/g')
recent_logs=$(git log --oneline -3 2>/dev/null | tr '\n' ' ' | sed 's/"/\\"/g')

# 4. Phase mapping logic (simplified for script)
phase="Discover"
if [[ -f "specs/PLAN.md" ]]; then
  phase="Execute"
elif [[ -f "specs/TASKS.md" ]]; then
  phase="Plan"
elif [[ -f "specs/SCOPE.md" ]]; then
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

if [[ -f "specs/PLAN.md" ]]; then
  echo "Current PLAN.md found. I am ready to implement the next step."
fi
