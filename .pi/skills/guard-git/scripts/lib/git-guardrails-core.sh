# Shared pattern list and matcher for git hook guardrails.
# Source from block-dangerous-git.sh only.

GIT_GUARDRAILS_PATTERNS=(
  "git reset --hard"
  "git clean -fd"
  "git clean -f"
  "git branch -D"
  "git checkout \\."
  "git restore \\."
  "push --force"
  "reset --hard"
)

# Print first matching pattern to stdout; exit 0 if dangerous, 1 if safe.
# Usage: if git_guardrails_first_match "$command"; then read pattern; fi
# Actually: pattern=$(git_guardrails_first_match "$c") && ...
git_guardrails_first_match() {
  local cmd="$1"
  local p
  for p in "${GIT_GUARDRAILS_PATTERNS[@]}"; do
    if echo "$cmd" | grep -qE "$p"; then
      printf '%s' "$p"
      return 0
    fi
  done
  return 1
}
