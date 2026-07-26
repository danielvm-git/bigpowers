#!/usr/bin/env bash
# story: GH-104-forge-neutrality
# detect-forge.sh — resolve which git forge a project uses.
#
# bigpowers ships to solo devs generally, but its CI advice assumed GitHub
# everywhere (GH #104). This is the seam: skills ask which forge is in play and
# what it supports, instead of hardcoding `gh` and `.github/workflows/`.
#
# Resolution order (first match wins):
#   1. BIGPOWERS_FORGE environment variable  — explicit override
#   2. forge: key in specs/forge.yaml        — per-project setting
#   3. the `origin` remote URL               — inferred
#   4. "unknown"                             — no remote, or an unrecognized host
#
# Source this file, then call detect_forge / forge_is_supported / forge_ci_path.

if [[ -n "${DETECT_FORGE_LOADED:-}" ]]; then return 0; fi
DETECT_FORGE_LOADED=1

FORGE_UNKNOWN="unknown"

# Forges whose CI templates bigpowers actually ships. Anything else must be
# reported honestly and skipped — never silently handed GitHub Actions config.
FORGE_SUPPORTED_LIST="github"

_forge_from_remote_url() {
  local url="$1"
  case "$url" in
    "") echo "$FORGE_UNKNOWN" ;;
    *github.com[:/]*|*github.*.com[:/]*) echo "github" ;;
    *gitlab.com[:/]*|*gitlab.*[:/]*)     echo "gitlab" ;;
    *bitbucket.org[:/]*)                 echo "bitbucket" ;;
    *codeberg.org[:/]*)                  echo "codeberg" ;;
    *gitea.*[:/]*)                       echo "gitea" ;;
    *) echo "$FORGE_UNKNOWN" ;;
  esac
}

_forge_from_config() {
  local repo_root="$1"
  local config="$repo_root/specs/forge.yaml"
  [[ -f "$config" ]] || return 1
  local value
  value=$(grep -E '^forge:' "$config" 2>/dev/null | head -1 \
    | sed -E 's/^forge:[[:space:]]*//; s/^"(.*)"$/\1/; s/[[:space:]]*$//')
  [[ -n "$value" ]] || return 1
  printf '%s' "$value"
}

# Echo the forge id. Never fails — an undetectable forge is "unknown", which
# callers must treat as "skip honestly", not as "assume GitHub".
detect_forge() {
  local repo_root="${1:-.}"

  if [[ -n "${BIGPOWERS_FORGE:-}" ]]; then
    printf '%s\n' "$BIGPOWERS_FORGE"
    return 0
  fi

  local configured
  if configured=$(_forge_from_config "$repo_root"); then
    printf '%s\n' "$configured"
    return 0
  fi

  local url
  url=$(git -C "$repo_root" remote get-url origin 2>/dev/null || echo "")
  _forge_from_remote_url "$url"
}

forge_is_supported() {
  local forge="$1"
  case " $FORGE_SUPPORTED_LIST " in
    *" $forge "*) return 0 ;;
    *) return 1 ;;
  esac
}

# Where a forge expects its CI config. Empty for unsupported forges — callers
# must check forge_is_supported first rather than treating "" as a path.
forge_ci_path() {
  local forge="$1"
  case "$forge" in
    github) echo ".github/workflows" ;;
    gitlab) echo ".gitlab-ci.yml" ;;
    *) echo "" ;;
  esac
}

# Root of the bundled CI templates. Overridable so a user can point at their own
# org templates; the previous hardcoded `danielvm-git/.github` made every
# installation depend on one person's personal repository.
#
# Resolved against the bigpowers package — NOT the target project. Templates
# ship with bigpowers; deriving this from the project being wired would look for
# them inside the user's repo, where they do not exist.
forge_template_root() {
  if [[ -n "${BIGPOWERS_CI_TEMPLATES:-}" ]]; then
    printf '%s' "$BIGPOWERS_CI_TEMPLATES"
    return 0
  fi
  local package_root
  package_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  printf '%s' "$package_root/docs/templates/ci"
}
