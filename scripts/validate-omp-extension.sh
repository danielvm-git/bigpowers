#!/usr/bin/env bash
# story: e82s03
# OMP extension integrity guard — validates the extension entry is wired,
# leaves slash commands to Pi prompt templates, and discovers all source skills.
# Run before merging any branch that touches extensions/.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

ERRORS=0

source "$REPO_ROOT/scripts/lib/test-assertions.sh"

# ── 1. Package has exactly one pi.extensions entry ─────────────────────────
# pi reads extension paths from the `pi` manifest key (readPiManifest). The
# legacy `omp.extensions` key was never consumed by pi — see BUG-2026-09-05.
echo "--- [OMP] manifest: single extension entry ---"
EXT_COUNT=$(node -e "const p = require('./package.json'); const exts = p.pi?.extensions; if (!exts) { console.log(0); } else { console.log(exts.length); }")
if [[ "$EXT_COUNT" -eq 1 ]]; then
  ta_ok "pi.extensions has exactly 1 entry"
else
  ta_err "pi.extensions has $EXT_COUNT entries (expected 1)"
fi

# ── 2. Extension file exists ───────────────────────────────────────────────
echo "--- [OMP] extension file exists ---"
EXT_PATH=$(node -e "const p = require('./package.json'); console.log(p.pi?.extensions?.[0] || '')")
if [[ -z "$EXT_PATH" ]]; then
  ta_err "No pi.extensions entry found"
else
  if [[ -f "$EXT_PATH" ]]; then
    ta_ok "extension file '$EXT_PATH' exists"
  else
    ta_err "extension file '$EXT_PATH' does not exist"
  fi
fi

# ── 3. Extension owns tools/hooks; prompt templates own slash commands ─────
echo "--- [OMP] separated runtime responsibilities ---"
if [[ -n "$EXT_PATH" && -f "$EXT_PATH" ]]; then
  for sym in "registerTool" "tool_call"; do
    if grep -q "$sym" "$EXT_PATH" 2>/dev/null; then
      ta_ok "symbol '$sym' found in extension source"
    else
      ta_err "symbol '$sym' NOT found in extension source"
    fi
  done
  if grep -q 'pi\.registerCommand' "$EXT_PATH" 2>/dev/null; then
    ta_err "extension registers commands already supplied by Pi prompt templates"
  else
    ta_ok "extension leaves slash-command registration to Pi prompt templates"
  fi
else
  ta_err "Cannot scan extension symbols — file not resolved"
fi

PROMPT_COUNT=$(node -e "const p = require('./package.json'); console.log(p.pi?.prompts?.length || 0)")
if [[ "$PROMPT_COUNT" -eq 1 ]]; then
  ta_ok "pi.prompts has exactly 1 canonical prompt-template entry"
else
  ta_err "pi.prompts has $PROMPT_COUNT entries (expected 1)"
fi

# ── 4. Skill discovery root is skills/ ────────────────────────────────────
echo "--- [OMP] source skill discoverability (skills/<name>/SKILL.md) ---"
SKILLS_ROOT="$REPO_ROOT/skills"
if [[ ! -d "$SKILLS_ROOT" ]]; then
  ta_err "skills/ directory not found at $SKILLS_ROOT"
else
  TOTAL=0
  MISSING=0
  while IFS= read -r skill_md; do
    rel="${skill_md#"$SKILLS_ROOT"/}"
    # Each should be exactly <name>/SKILL.md (one level of nesting).
    if [[ "$rel" != */SKILL.md || "${rel%%/*}" == "" ]]; then
      ta_err "unexpected SKILL.md path: $rel"
      MISSING=$((MISSING + 1))
      continue
    fi
    TOTAL=$((TOTAL + 1))
  done < <(find "$SKILLS_ROOT" -maxdepth 2 -name SKILL.md 2>/dev/null | sort)

  if [[ "$TOTAL" -eq 0 ]]; then
    ta_err "no skills found under skills/"
  elif [[ "$MISSING" -eq 0 ]]; then
    ta_ok "$TOTAL source skills all at skills/<name>/SKILL.md"
  else
    ta_err "$MISSING/$TOTAL skills at unexpected paths"
  fi
fi

# ── 5. Extension scans skills/ not the repo root ──────────────────────────
echo "--- [OMP] extension targets skills/ root ---"
if [[ -n "$EXT_PATH" && -f "$EXT_PATH" ]]; then
  if grep -q 'join(pluginRoot(), "skills")' "$EXT_PATH" 2>/dev/null; then
    ta_ok "extension calls discoverSkills with skills/ subdirectory"
  else
    ta_err "extension does not target skills/ — check discoverSkills call in $EXT_PATH"
  fi
fi

# ── 6. Runtime load smoke (load-phase contract, BUG-2026-09-05) ────────────
# Loads the extension through a fake ExtensionAPI that models pi's load-phase
# guard: action methods (setLabel, sendUserMessage, …) throw during the factory
# body, exactly as real pi does. Catches load-time action calls that abort pi
# startup (#119). Requires a Node with TypeScript type-stripping (>=22.6).
echo "--- [OMP] runtime load smoke (scripts/omp-smoke.ts) ---"
SMOKE="$REPO_ROOT/scripts/omp-smoke.ts"
if [[ ! -f "$SMOKE" ]]; then
  ta_err "omp-smoke.ts not found at $SMOKE"
elif ! command -v node >/dev/null 2>&1; then
  echo "warn: node unavailable — skipping runtime load smoke"
else
  SMOKE_ERR=$(mktemp)
  if node "$SMOKE" >/dev/null 2>"$SMOKE_ERR"; then
    ta_ok "extension loads without calling action methods during load"
  else
    ta_err "runtime load smoke failed — $(head -3 "$SMOKE_ERR" 2>/dev/null | tr '\n' ' ')"
  fi
  rm -f "$SMOKE_ERR"
fi

# ── Summary ────────────────────────────────────────────────────────────────
echo "---"
if [[ "$ERRORS" -eq 0 ]]; then
  echo "OMP extension validation passed"
else
  echo "OMP extension validation FAILED ($ERRORS error(s))"
  exit 1
fi
