#!/usr/bin/env bash
# story: e13s03 e28s03
# Post-sync pipeline for sync-skills.sh — manifests, lockfiles, guards, OKF wikis.
# Args: $1=skill_count  $2=opencode_count (optional, default 0)

if [ -n "${SYNC_POST_LOADED:-}" ]; then
  return 0
fi
SYNC_POST_LOADED=1

sync_post_gemini_version_mismatch() {
  local ext_ver="$1" pkg_ver="$2"
  [[ -n "$ext_ver" && -n "$pkg_ver" && "$ext_ver" != "$pkg_ver" ]]
}

sync_post_run() {
  local skill_count="${1:-0}"
  local opencode_count="${2:-0}"
  local pkg_version pkg_desc readme readme_tmp trace_mdc manifest ext_ver pkg_ver validate_script

  pkg_version=$(jq -r '.version' "$REPO_ROOT/package.json")
  pkg_desc=$(jq -r '.description' "$REPO_ROOT/package.json")

  jq -n --arg name "bigpowers" \
        --arg version "$pkg_version" \
        --arg desc "${skill_count} skills — ${pkg_desc}" \
        '{
          name: $name,
          version: $version,
          description: $desc,
          keywords: ["gemini-extension"],
          gemini: {
            skills: ["./skills"],
            commands: ["./commands"]
          }
        }' > "$GEMINI_MANIFEST"

  jq -n --arg version "$pkg_version" \
        --arg desc "${skill_count} skills — ${pkg_desc}" \
        '{
          "name": "bigpowers",
          "version": $version,
          "description": $desc,
          "keywords": ["pi-package"],
          "pi": {
            "skills": ["./skills"],
            "prompts": ["./prompts"]
          }
        }' > "$PI_PACKAGE_JSON"

  {
    echo "{"
    echo "  \"\$schema\": \"https://opencode.ai/config.json\","
    echo "  \"instructions\": [\"CLAUDE.md\", \"CONVENTIONS.md\"]"
    echo "}"
  } > "$REPO_ROOT/opencode.json"

  if [[ -x "$REPO_ROOT/scripts/regenerate-lockfile.sh" ]]; then
    bash "$REPO_ROOT/scripts/regenerate-lockfile.sh" || {
      echo "sync-skills: FAIL — lockfile regeneration failed" >&2
      exit 1
    }
  fi

  if [[ -x "$REPO_ROOT/scripts/generate-skill-index.sh" ]]; then
    bash "$REPO_ROOT/scripts/generate-skill-index.sh" || {
      echo "sync-skills: FAIL — SKILL-INDEX.md generation failed" >&2
      exit 1
    }
  fi

  if [[ -x "$REPO_ROOT/scripts/build-skill-index.sh" ]]; then
    bash "$REPO_ROOT/scripts/build-skill-index.sh" || true
  fi

  local CURSOR_KEEP="context7.mdc" mdc mdc_base
  for mdc in "$CURSOR_RULES"/*.mdc; do
    [[ -e "$mdc" ]] || continue
    mdc_base=$(basename "$mdc")
    case " $CURSOR_KEEP " in *" $mdc_base "*) continue ;; esac
    if [[ ! -f "$SKILLS_ROOT/${mdc_base%.mdc}/SKILL.md" ]]; then
      rm "$mdc"
      echo "  → pruned orphan cursor rule: $mdc_base"
    fi
  done

  readme="$REPO_ROOT/README.md"
  if [[ -f "$readme" ]] && grep -q 'badge/skills-' "$readme"; then
    readme_tmp=$(mktemp)
    sed -E "s|(badge/skills-)[0-9]+(-brightgreen)|\1${skill_count}\2|" "$readme" > "$readme_tmp"
    mv "$readme_tmp" "$readme"
  fi

  echo "sync-skills: $skill_count skills synced"
  echo "  → .cursor/rules/ ($skill_count .mdc files)"
  echo "  → .gemini/extensions/bigpowers/skills/ (Agent Skills)"
  echo "  → .gemini/extensions/bigpowers/commands/ (Slash Commands)"
  echo "  → .gemini/extensions/bigpowers/gemini-extension.json"
  echo "  → .pi/skills/ ($skill_count skill dirs — pi Agent Skills)"
  echo "  → .pi/prompts/ ($skill_count prompt templates — pi slash commands)"
  echo "  → .pi/package.json (pi package manifest)"
  echo "  → skills-lock.json (catalog with SHA-256 hashes)"
  echo "  → SKILL-INDEX.md (auto-generated skill reference)"
  echo "  → opencode.json (CLAUDE.md + CONVENTIONS.md instructions)"
  [[ -n "${OPN_TARGET:-}" ]] && echo "  → bigpowers-opencode: $opencode_count skills"

  sync_post_regression_guards

  if [[ -d "$REPO_ROOT/.git" ]]; then
    bash "$REPO_ROOT/scripts/generate-reference-tables.sh"
  fi

  echo ""
  echo "Generating OKF wikis..."
  bash "$REPO_ROOT/scripts/generate-epics-wiki.sh"
  bash "$REPO_ROOT/scripts/generate-adr-wiki.sh"
  echo "sync-skills: OKF wikis regenerated"
}

sync_post_regression_guards() {
  local trace_mdc manifest ext_ver pkg_ver validate_script

  trace_mdc="$REPO_ROOT/.cursor/rules/trace-requirement.mdc"
  if [[ -f "$trace_mdc" ]] && ! grep -q 'release-plan.yaml + epic' "$trace_mdc"; then
    echo "sync-skills: FAIL — '+' missing from trace-requirement; use sed -E for whitespace collapse" >&2
    exit 1
  fi

  manifest="$REPO_ROOT/.gemini/extensions/bigpowers/gemini-extension.json"
  if [[ -f "$manifest" ]]; then
    ext_ver=$(jq -r '.version // empty' "$manifest")
    pkg_ver=$(jq -r '.version // empty' "$REPO_ROOT/package.json")
    if sync_post_gemini_version_mismatch "$ext_ver" "$pkg_ver"; then
      echo "sync-skills: FAIL — gemini-extension.json version ($ext_ver) != package.json ($pkg_ver)" >&2
      exit 1
    fi
  fi

  validate_script="$REPO_ROOT/scripts/validate-skill-yaml.py"
  if [[ -f "$validate_script" ]] && command -v $PYTHON &>/dev/null; then
    if ! $PYTHON "$validate_script" > /dev/null 2>&1; then
      echo "sync-skills: FAIL — YAML frontmatter validation failed" >&2
      $PYTHON "$validate_script" >&2
      exit 1
    fi
  fi

  if grep -rn '^declare -A\|^[[:space:]]*declare -A' \
      scripts/sync-skills.sh scripts/generate-skill-index.sh \
      scripts/regenerate-lockfile.sh scripts/build-skill-index.sh 2>/dev/null; then
    echo "sync-skills: FAIL — bash 4+ features detected in install-chain scripts (not macOS-compatible)" >&2
    exit 1
  fi
}

sync_opencode_copy() {
  local opencode_count=0 skill_dir skill_md skill_name
  SYNC_OPENCODE_COUNT=0

  [[ -z "${OPN_TARGET:-}" || ! -d "$OPN_TARGET" ]] && return 0

  echo ""
  echo "Syncing skills to opencode repo: $OPN_TARGET"
  OPN_SKILLS="$OPN_TARGET/skills"
  mkdir -p "$OPN_SKILLS"
  for skill_dir in "$SKILLS_ROOT"/*/; do
    skill_md="$skill_dir/SKILL.md"
    [[ -f "$skill_md" ]] || continue
    skill_name=$(basename "$skill_dir")
    mkdir -p "$OPN_SKILLS/$skill_name"
    cp "$skill_md" "$OPN_SKILLS/$skill_name/SKILL.md"
    opencode_count=$((opencode_count + 1))
  done
  echo "  → $opencode_count skills copied to $OPN_SKILLS/"
  SYNC_OPENCODE_COUNT=$opencode_count
}
