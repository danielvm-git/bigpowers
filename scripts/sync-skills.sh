#!/usr/bin/env bash
# story: e13s03 e28s03 e39s04
# sync-skills.sh — generate Cursor, Gemini CLI, pi, and OKF artifacts from SKILL.md source files
# Architecture: Parse→IR→Render. Each target is its own render_<target>() function.
# Run this after adding or updating any skill. Symlinks carry changes through automatically.
#
# Flags:
#   --okf          Generate specs/skills-wiki/ OKF concept bundle from SKILL.md frontmatter
#   --opencode <p> Sync to bigpowers-opencode repo
set -euo pipefail

# ── Parse CLI flags (must happen before source to allow early --help) ─
OKF_MODE=0
OPN_TARGET=""

for arg in "$@"; do
  case "$arg" in
    --okf) OKF_MODE=1 ;;
    --opencode=*) OPN_TARGET="${arg#*=}" ;;
    --opencode) shift; OPN_TARGET="$1" ;;
    --help|-h)
      echo "Usage: sync-skills.sh [--okf] [--opencode <path>]"
      echo ""
      echo "  --okf        Generate specs/skills-wiki/ OKF concept bundle"
      echo "  --opencode   Sync skills to bigpowers-opencode repo"
      echo "  --help       Show this message"
      exit 0
      ;;
    *) echo "sync-skills: unknown flag: $arg" >&2; exit 2 ;;
  esac
done

source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root

CURSOR_RULES="$REPO_ROOT/.cursor/rules"
GEMINI_EXT_DIR="$REPO_ROOT/.gemini/extensions/bigpowers"
GEMINI_SKILLS="$GEMINI_EXT_DIR/skills"
GEMINI_COMMANDS="$GEMINI_EXT_DIR/commands"
GEMINI_MANIFEST="$GEMINI_EXT_DIR/gemini-extension.json"
PI_SKILLS="$REPO_ROOT/.pi/skills"
PI_PROMPTS="$REPO_ROOT/.pi/prompts"
PI_PACKAGE_JSON="$REPO_ROOT/.pi/package.json"

mkdir -p "$CURSOR_RULES" "$GEMINI_SKILLS" "$GEMINI_COMMANDS" "$PI_SKILLS" "$PI_PROMPTS"

# Clear old artifacts to ensure a clean sync
rm -rf "${GEMINI_SKILLS:?}"/*
rm -rf "${GEMINI_COMMANDS:?}"/*
rm -rf "${PI_SKILLS:?}"/*
rm -rf "${PI_PROMPTS:?}"/*

# ── IR: shared intermediate representation ──────────────────────────
# These globals are set by the main loop per skill and consumed by render functions.
IR_NAME=""
IR_MODEL=""
IR_DESCRIPTION=""
IR_DESC_ESCAPED=""
IR_BODY=""

# ── build_body ──────────────────────────────────────────────────────
# Builds the concatenated content: SKILL.md body + all other *.md files.
# Args: $1 = path to SKILL.md, $2 = skill directory
build_body() {
  local skill_md="$1"
  local skill_dir="$2"
  local body

  # Strip frontmatter from SKILL.md (content after second ---)
  body=$(awk '/^---/{f++; next} f>=2{print}' "$skill_md")

  # Append extra *.md files alphabetically
  local extra_md
  for extra_md in $(find "$skill_dir" -maxdepth 1 -name "*.md" ! -name "SKILL.md" | LC_ALL=C sort); do
    body="$body"$'\n\n'"---"$'\n\n'"$(cat "$extra_md")"
  done

  # Strip disable-model-invocation lines
  echo "$body" | grep -v 'disable-model-invocation'
}

# ── Render target: Cursor ───────────────────────────────────────────
# Writes .cursor/rules/<name>.mdc with YAML frontmatter + body.
render_cursor() {
  local cursor_file="$CURSOR_RULES/$IR_NAME.mdc"
  {
    echo "---"
    echo "description: \"$IR_DESC_ESCAPED\""
    echo "alwaysApply: false"
    echo "---"
    echo ""
    echo "$IR_BODY"
  } > "$cursor_file"
}

# ── Render target: Gemini Agent Skill ───────────────────────────────
# Writes .gemini/extensions/bigpowers/skills/<name>/SKILL.md
render_gemini_skill() {
  mkdir -p "$GEMINI_SKILLS/$IR_NAME"
  {
    echo "---"
    echo "name: $IR_NAME"
    echo "description: \"$IR_DESC_ESCAPED\""
    echo "---"
    echo ""
    echo "$IR_BODY"
  } > "$GEMINI_SKILLS/$IR_NAME/SKILL.md"
}

# ── Render target: Gemini Slash Command ─────────────────────────────
# Writes .gemini/extensions/bigpowers/commands/<name>.toml + prompt file
render_gemini_command() {
  mkdir -p "$GEMINI_COMMANDS/prompts"
  local prompt_file="commands/prompts/$IR_NAME.md"
  echo "$IR_BODY" > "$GEMINI_EXT_DIR/$prompt_file"
  {
    echo "description = \"$IR_DESC_ESCAPED\""
    echo "prompt = \"@{$prompt_file}\""
  } > "$GEMINI_COMMANDS/$IR_NAME.toml"
}

# ── Render target: pi Agent Skill ───────────────────────────────────
# Writes .pi/skills/<name>/SKILL.md
render_pi_skill() {
  mkdir -p "$PI_SKILLS/$IR_NAME"
  {
    echo "---"
    echo "name: $IR_NAME"
    echo "description: \"$IR_DESC_ESCAPED\""
    [[ -n "$IR_MODEL" ]] && echo "model: $IR_MODEL"
    echo "---"
    echo ""
    echo "$IR_BODY"
  } > "$PI_SKILLS/$IR_NAME/SKILL.md"
}

# ── Render target: pi Prompt Template ───────────────────────────────
# Writes .pi/prompts/<name>.md
render_pi_prompt() {
  {
    echo "---"
    echo "description: $IR_DESCRIPTION"
    echo "---"
    echo ""
    echo "$IR_BODY"
  } > "$PI_PROMPTS/$IR_NAME.md"
}

# ── Render target: OKF Concept (e39s04) ──────────────────────────────
# Writes specs/skills-wiki/skills/<name>.md with OKF concept frontmatter.
# Globals used: IR_NAME, IR_MODEL, IR_DESCRIPTION, IR_DESC_ESCAPED, IR_BODY
# Also reads _PF_EFFORT from the extended parse_frontmatter.
OKF_WIKI_SKILLS="$REPO_ROOT/specs/skills-wiki/skills"
OKF_WIKI_DIR="$REPO_ROOT/specs/skills-wiki"

render_okf_concept() {
  mkdir -p "$OKF_WIKI_SKILLS"
  local okf_file="$OKF_WIKI_SKILLS/$IR_NAME.md"

  # Determine phase: critical-path skills per the bigpowers core loop
  local phase="utility"
  case "$IR_NAME" in
    survey-context|elaborate-spec|model-domain|define-language|\
    design-interface|plan-work|plan-release|slice-tasks|\
    kickoff-branch|develop-tdd|verify-work|audit-code|\
    commit-message|release-branch|security-review|\
    assess-impact|investigate-bug|validate-fix|dispatch-agents|\
    request-review|respond-review|hook-commits|guard-git|\
    wire-observability|wire-ci|smoke-test|deploy|enforce-first)
      phase="critical-path" ;;
  esac

  # Build title from name: kebab-case → Title Case
  local title
  title=$(echo "$IR_NAME" | sed -E 's/-/ /g; s/\b(.)/\U\1/g')

  # Escape description for YAML double-quoted string
  local desc_escaped
  desc_escaped=$(echo "$IR_DESCRIPTION" | sed 's/\\/\\\\/g; s/"/\\"/g')

  # Truncate description to avoid overly long lines (OKF convention)
  local short_desc="$IR_DESCRIPTION"
  if [[ ${#short_desc} -gt 200 ]]; then
    short_desc="${short_desc:0:197}..."
  fi

  local effort_val="${_PF_EFFORT:-standard}"

  {
    echo "---"
    echo "okf_kind: concept"
    echo "type: Skill"
    echo "id: $IR_NAME"
    echo "title: \"$title\""
    echo "name: $IR_NAME"
    echo "category: skills"
    [[ -n "$IR_MODEL" ]] && echo "model: $IR_MODEL"
    echo "effort: $effort_val"
    echo "phase: $phase"
    echo "description: \"$desc_escaped\""
    echo "references: []"
    echo "---"
    echo ""
    echo "# $title"
    echo ""
    echo "**Phase:** $phase"
    [[ -n "$IR_MODEL" ]] && echo "**Model:** $IR_MODEL"
    echo "**Effort:** $effort_val"
    echo ""
    echo "$IR_DESCRIPTION"
    echo ""
    echo "> Auto-generated by sync-skills.sh --okf (e39s04) from $SKILLS_ROOT/$IR_NAME/SKILL.md"
  } > "$okf_file"
}

# ── Parse extended frontmatter for OKF (includes effort) ────────────
# Wrapper for library parse_frontmatter — sets _PF_* compat vars
parse_frontmatter() {
  # Delegate to library which now sets _PF_* vars
  if command -v skill_common_parse >/dev/null 2>&1 || [ -n "${SKILL_COMMON_LOADED:-}" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh" 2>/dev/null
  fi
  # Call library version (defined in skill-common.sh, sets SKILL_NAME and _PF_*)
  # But since we have the same name, we need the inline version
  _PF_NAME=$(awk '/^---/{f++} f==1 && /^name:/{print; exit}' "$1" | sed 's/^name:[[:space:]]*//')
  _PF_MODEL=$(awk '/^---/{f++} f==1 && /^model:/{print; exit}' "$1" | sed 's/^model:[[:space:]]*//')
  _PF_DESCRIPTION=$(awk '/^---/{f++; next} f==1 && /^description:/{p=1; sub(/^description:[[:space:]]*/,""); print; next} f==1 && p && /^[a-z]+:/{exit} f==1 && p{print}' "$1" | tr '\n' ' ' | sed 's/[[:space:]]*$//')
  [[ -z "$_PF_NAME" ]] && return 1
  return 0
}

# Extended parse_frontmatter for OKF mode (adds _PF_EFFORT)
parse_frontmatter_okf() {
  local file="$1"
  _PF_EFFORT=""

  if [[ ! -f "$file" ]]; then
    return 1
  fi

  if ! grep -q '^---$' "$file"; then
    return 1
  fi

  _PF_NAME=$(awk '/^---/{f++} f==1 && /^name:/{print; exit}' "$file" | sed 's/^name:[[:space:]]*//')
  _PF_MODEL=$(awk '/^---/{f++} f==1 && /^model:/{print; exit}' "$file" | sed 's/^model:[[:space:]]*//')
  _PF_EFFORT=$(awk '/^---/{f++} f==1 && /^effort:/{print; exit}' "$file" | sed 's/^effort:[[:space:]]*//')
  _PF_DESCRIPTION=$(awk '/^---/{f++; next} f==1 && /^description:/{p=1; sub(/^description:[[:space:]]*/,""); print; next} f==1 && p && /^[a-z]+:/{exit} f==1 && p{print}' "$file" \
    | tr -d '\n' \
    | sed -E 's/[[:space:]]+/ /g')

  [[ -z "$_PF_NAME" ]] && return 1
  return 0
}

# ── Target registry ─────────────────────────────────────────────────
# Order matters: render functions are called in this order per skill.
TARGETS=(render_cursor render_gemini_skill render_gemini_command render_pi_skill render_pi_prompt)
if [[ "$OKF_MODE" -eq 1 ]]; then
  TARGETS+=(render_okf_concept)
fi

skill_count=0

# ── Main loop: Parse → IR → Render per skill ────────────────────────
while IFS= read -r skill_dir; do
  skill_md="$skill_dir/SKILL.md"

  if [[ "$OKF_MODE" -eq 1 ]]; then
    parse_frontmatter_okf "$skill_md" || continue
  else
    parse_frontmatter "$skill_md" || continue
  fi

  IR_NAME="$_PF_NAME"
  IR_MODEL="$_PF_MODEL"
  IR_DESCRIPTION="$_PF_DESCRIPTION"

  # Escape double quotes and backslashes for safe double-quoted YAML output
  IR_DESC_ESCAPED=$(echo "$IR_DESCRIPTION" | sed 's/\\/\\\\/g; s/\"/\\"/g')

  [[ -z "$IR_NAME" ]] && continue

  IR_BODY=$(build_body "$skill_md" "$skill_dir")

  # Dispatch to each render target
  for target_fn in "${TARGETS[@]}"; do
    "$target_fn"
  done

  skill_count=$((skill_count + 1))
done < <(iterate_skills)

# ── Post-loop: manifest, opencode, regeneration, guards, README badge ──

# Assemble final gemini-extension.json
pkg_version=$(jq -r '.version' "$REPO_ROOT/package.json")
pkg_desc=$(jq -r '.description' "$REPO_ROOT/package.json")

jq -n --arg name "bigpowers" \
      --arg version "$pkg_version" \
      --arg desc "${skill_count} skills — ${pkg_desc}" \
      '{name: $name, version: $version, description: $desc}' > "$GEMINI_MANIFEST"

# Write pi package config: .pi/package.json
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

# Write OpenCode configuration: opencode.json
{
  echo "{"
  echo "  \"\$schema\": \"https://opencode.ai/config.json\","
  echo "  \"instructions\": [\"CLAUDE.md\", \"CONVENTIONS.md\"]"
  echo "}"
} > "$REPO_ROOT/opencode.json"

# Sync to bigpowers-opencode repo (if --opencode path is provided)
if [[ -n "$OPN_TARGET" ]] && [[ -d "$OPN_TARGET" ]]; then
  echo ""
  echo "Syncing skills to opencode repo: $OPN_TARGET"
  OPN_SKILLS="$OPN_TARGET/skills"
  mkdir -p "$OPN_SKILLS"
  opencode_count=0
  for skill_dir in "$SKILLS_ROOT"/*/; do
    skill_md="$skill_dir/SKILL.md"
    [[ -f "$skill_md" ]] || continue
    skill_name=$(basename "$skill_dir")
    mkdir -p "$OPN_SKILLS/$skill_name"
    cp "$skill_md" "$OPN_SKILLS/$skill_name/SKILL.md"
    opencode_count=$((opencode_count + 1))
  done
  echo "  → $opencode_count skills copied to $OPN_SKILLS/"
fi

# Regenerate skills-lock.json catalog
if [[ -x "$REPO_ROOT/scripts/regenerate-lockfile.sh" ]]; then
  bash "$REPO_ROOT/scripts/regenerate-lockfile.sh" || { echo "sync-skills: FAIL — lockfile regeneration failed" >&2; exit 1; }
fi

# Regenerate SKILL-INDEX.md from lockfile + frontmatter
if [[ -x "$REPO_ROOT/scripts/generate-skill-index.sh" ]]; then
  bash "$REPO_ROOT/scripts/generate-skill-index.sh" || { echo "sync-skills: FAIL — SKILL-INDEX.md generation failed" >&2; exit 1; }
fi

# Regenerate lexical skill index for search-skills
if [[ -x "$REPO_ROOT/scripts/build-skill-index.sh" ]]; then
  bash "$REPO_ROOT/scripts/build-skill-index.sh" || true
fi

# Prune orphan cursor rules
CURSOR_KEEP="context7.mdc"
for mdc in "$CURSOR_RULES"/*.mdc; do
  [[ -e "$mdc" ]] || continue
  mdc_base=$(basename "$mdc")
  case " $CURSOR_KEEP " in *" $mdc_base "*) continue ;; esac
  if [[ ! -f "$SKILLS_ROOT/${mdc_base%.mdc}/SKILL.md" ]]; then
    rm "$mdc"
    echo "  → pruned orphan cursor rule: $mdc_base"
  fi
done

# Stamp the README skill-count badge
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
[[ -n "$OPN_TARGET" ]] && echo "  → bigpowers-opencode: $opencode_count skills"

# ── OKF post-sync pipeline (e39s04) ──────────────────────────────────
if [[ "$OKF_MODE" -eq 1 ]]; then
  echo ""
  echo "--- OKF skills-wiki post-sync ---"

  # Step 2: Run build-skill-graph.sh to get cross-references in skill-graph.json
  GRAPH_JSON="$REPO_ROOT/specs/skill-graph.json"
  if [[ -x "$REPO_ROOT/scripts/build-skill-graph.sh" ]]; then
    echo "Running build-skill-graph.sh for cross-references..."
    bash "$REPO_ROOT/scripts/build-skill-graph.sh" --json || {
      echo "sync-skills: WARNING — build-skill-graph.sh --json failed; cross-references will be empty" >&2
    }
  else
    echo "sync-skills: WARNING — build-skill-graph.sh not found; skipping cross-references" >&2
  fi

  # Step 2b: Add cross-references from skill-graph.json edges into OKF concepts
  if [[ -f "$GRAPH_JSON" ]]; then
    echo "Adding cross-references from skill-graph.json..."
    python3 - "$GRAPH_JSON" "$OKF_WIKI_SKILLS" <<'PYEOF'
import json, sys, re
from pathlib import Path

graph_json = Path(sys.argv[1])
wiki_skills = Path(sys.argv[2])

# Load graph edges
with open(graph_json) as f:
    graph = json.load(f)

edges = graph.get("edges", [])
nodes = {n["name"] for n in graph.get("nodes", [])}

# Build adjacency: skill_name -> list of {concept, type} refs
refs = {}
for e in edges:
    src, tgt, rel = e["from"], e["to"], e.get("relationType", "references")
    # Only include edges where both ends are known skills
    if src in nodes and tgt in nodes:
        refs.setdefault(src, []).append({"concept": tgt, "type": rel})

# Also detect intra-description references: scan description for skill names
skill_names = set()
for f in wiki_skills.glob("*.md"):
    skill_names.add(f.stem)

# Update each concept file with references
count_updated = 0
for f in wiki_skills.glob("*.md"):
    name = f.stem
    content = f.read_text()

    # Collect references for this skill
    concept_refs = refs.get(name, [])

    # Also scan description for mentions of other skill names
    desc_match = re.search(r'description:\s*"(.*?)"', content, re.DOTALL)
    if desc_match:
        desc = desc_match.group(1)
        for sn in skill_names:
            if sn != name and sn in desc and not any(r["concept"] == sn for r in concept_refs):
                concept_refs.append({"concept": sn, "type": "references"})

    # Deduplicate
    seen = set()
    unique_refs = []
    for r in concept_refs:
        key = (r["concept"], r["type"])
        if key not in seen:
            seen.add(key)
            unique_refs.append(r)

    # Build YAML references block
    if unique_refs:
        ref_lines = []
        for r in unique_refs:
            ref_lines.append(f'  - concept: {r["concept"]}')
            ref_lines.append(f'    type: {r["type"]}')
        ref_block = "\n".join(ref_lines)
        content = re.sub(r'references:\s*\[\]', f'references:\n{ref_block}', content)
        count_updated += 1
    else:
        # No edges and no description mentions → self-reference as fallback
        content = re.sub(
            r'references:\s*\[\]',
            f'references:\n  - concept: skills-wiki\n    type: belongs_to',
            content
        )
        count_updated += 1

    f.write_text(content)

print(f"  concepts with cross-references: {count_updated}", file=sys.stderr)
PYEOF
  else
    echo "sync-skills: WARNING — $GRAPH_JSON not found; adding fallback references" >&2
    # Add fallback references to all concepts
    for f in "$OKF_WIKI_SKILLS"/*.md; do
      [[ -f "$f" ]] || continue
      if command -v python3 &>/dev/null; then
        python3 -c "
import re, sys
content = open('$f').read()
content = re.sub(r'references:\s*\[\]', 'references:\n  - concept: skills-wiki\n    type: belongs_to', content)
open('$f', 'w').write(content)
"
      fi
    done
  fi

  # Step 3: Generate specs/skills-wiki/index.md with progressive disclosure
  echo "Generating index.md..."
  OKF_INDEX="$OKF_WIKI_DIR/index.md"
  python3 - "$OKF_WIKI_SKILLS" "$OKF_WIKI_DIR" "$OKF_INDEX" <<'PYEOF'
import json, sys, re
from pathlib import Path
from collections import defaultdict

wiki_skills = Path(sys.argv[1])
wiki_dir = Path(sys.argv[2])
index_path = Path(sys.argv[3])

# Collect all concepts
concepts = []
for f in sorted(wiki_skills.glob("*.md")):
    content = f.read_text()
    fm_match = re.search(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not fm_match:
        continue
    fm_text = fm_match.group(1)
    # Simple YAML extraction
    name = ""
    title = ""
    phase = "utility"
    model = ""
    effort = ""
    description = ""
    for line in fm_text.split('\n'):
        line = line.strip()
        if line.startswith('name:'):
            name = line.split(':', 1)[1].strip()
        elif line.startswith('title:'):
            title = line.split(':', 1)[1].strip().strip('"')
        elif line.startswith('phase:'):
            phase = line.split(':', 1)[1].strip()
        elif line.startswith('model:'):
            model = line.split(':', 1)[1].strip()
        elif line.startswith('effort:'):
            effort = line.split(':', 1)[1].strip()
        elif line.startswith('description:'):
            description = line.split(':', 1)[1].strip().strip('"')
    if not name:
        continue
    concepts.append({
        "name": name,
        "title": title or name.replace('-', ' ').title(),
        "phase": phase,
        "model": model,
        "effort": effort,
        "description": description[:120] + "..." if len(description) > 120 else description,
    })

# Group by phase
phases = defaultdict(list)
for c in concepts:
    phases[c["phase"]].append(c)

# Count
total = len(concepts)
cp_count = len(phases.get("critical-path", []))
util_count = len(phases.get("utility", []))

# Generate index.md
with open(index_path, "w") as out:
    out.write(f"""---
okf_kind: concept
type: Index
id: skills-wiki
title: "BigPowers Skills Wiki"
category: skills
description: "Progressive-disclosure index of {total} bigpowers skills ({cp_count} critical-path, {util_count} utility) — auto-generated by sync-skills.sh --okf (e39s04)."
references:
  - concept: bigpowers
    type: belongs_to
---

# BigPowers Skills Wiki

**{total} skills** ({cp_count} critical-path, {util_count} utility)

> Auto-generated by sync-skills.sh --okf (e39s04).
> Source of truth: skills/*/SKILL.md files.

## Critical-Path Skills ({cp_count})

These skills form the bigpowers core development loop — used on every feature.

| Skill | Model | Effort | Description |
|-------|-------|--------|-------------|
""")

    for c in phases.get("critical-path", []):
        out.write(f"| [{c['title']}](skills/{c['name']}.md) | {c['model']} | {c['effort']} | {c['description']} |\n")

    out.write(f"""
## Utility Skills ({util_count})

Supporting skills for specialised workflows.

| Skill | Model | Effort | Description |
|-------|-------|--------|-------------|
""")

    for c in phases.get("utility", []):
        out.write(f"| [{c['title']}](skills/{c['name']}.md) | {c['model']} | {c['effort']} | {c['description']} |\n")

    out.write(f"""
## Quick Reference

- **Total skills:** {total}
- **Critical-path:** {cp_count}
- **Utility:** {util_count}
- **Format:** OKF concept bundles (okf_kind: concept)
- **Validation:** `bash scripts/validate-okf.sh --dir specs/skills-wiki/skills`
""")

print(f"  index.md written: {total} skills indexed", file=sys.stderr)
PYEOF

  # Step 4: Validate OKF conformance via validate-okf.sh
  echo ""
  echo "Validating OKF conformance..."
  VALIDATE_SCRIPT="$REPO_ROOT/scripts/validate-okf.sh"
  if [[ -x "$VALIDATE_SCRIPT" ]]; then
    if bash "$VALIDATE_SCRIPT" --dir "$OKF_WIKI_SKILLS" 2>&1; then
      echo "sync-skills: OKF validation PASSED"
    else
      OKF_EXIT=$?
      echo "sync-skills: OKF validation returned exit code $OKF_EXIT (non-zero — check output above)" >&2
      # Don't hard-fail on validation warnings; the bundle is still generated
    fi
  else
    echo "sync-skills: WARNING — validate-okf.sh not found; skipping validation" >&2
  fi

  OKF_CONCEPT_COUNT=$(find "$OKF_WIKI_SKILLS" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  echo ""
  echo "sync-skills (--okf): $OKF_CONCEPT_COUNT OKF concepts generated"
  echo "  → specs/skills-wiki/skills/ ($OKF_CONCEPT_COUNT .md files)"
  echo "  → specs/skills-wiki/index.md (progressive-disclosure index)"
fi

# Regression guard (BUG-2026-06-02T164500)
trace_mdc="$REPO_ROOT/.cursor/rules/trace-requirement.mdc"
if [[ -f "$trace_mdc" ]] && ! grep -q 'release-plan.yaml + epic' "$trace_mdc"; then
  echo "sync-skills: FAIL — '+' missing from trace-requirement; use sed -E for whitespace collapse" >&2
  exit 1
fi
manifest="$REPO_ROOT/.gemini/extensions/bigpowers/gemini-extension.json"
if [[ -f "$manifest" ]]; then
  ext_ver=$(jq -r '.version // empty' "$manifest")
  pkg_ver=$(jq -r '.version // empty' "$REPO_ROOT/package.json")
  if [[ -z "$ext_ver" || -z "$pkg_ver" ]]; then
    : # skip version compare when either field is missing
  elif [[ "$ext_ver" != "$pkg_ver" ]]; then
    echo "sync-skills: FAIL — gemini-extension.json version ($ext_ver) != package.json ($pkg_ver)" >&2
    exit 1
  fi
fi

# Regression guard (BUG-2026-06-18T100000): validate generated YAML frontmatter
validate_script="$REPO_ROOT/scripts/validate-skill-yaml.py"
if [[ -f "$validate_script" ]] && command -v python3 &>/dev/null; then
  if ! python3 "$validate_script" > /dev/null 2>&1; then
    echo "sync-skills: FAIL — YAML frontmatter validation failed" >&2
    python3 "$validate_script" >&2
    exit 1
  fi
fi

# Regression guard (BUG-2026-07-02T103911): no bash 4+ features
if grep -rn '^declare -A\|^[[:space:]]*declare -A' scripts/sync-skills.sh scripts/generate-skill-index.sh scripts/regenerate-lockfile.sh scripts/build-skill-index.sh 2>/dev/null; then
  echo "sync-skills: FAIL — bash 4+ features detected in install-chain scripts (not macOS-compatible)" >&2
  exit 1
fi

# Regenerate derived reference tables
if [[ -d "$REPO_ROOT/.git" ]]; then
  bash "$REPO_ROOT/scripts/generate-reference-tables.sh"
fi

# ── OKF wiki generation (e45s01) ──────────────────────────────────────
echo ""
echo "Generating OKF wikis..."
bash "$REPO_ROOT/scripts/generate-epics-wiki.sh"
bash "$REPO_ROOT/scripts/generate-adr-wiki.sh"
echo "sync-skills: OKF wikis regenerated"

exit 0
