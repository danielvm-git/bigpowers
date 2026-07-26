#!/usr/bin/env bash
# story: e37s08
# scenario: SC-e37s08-P1-01

assert_agents_md() {
  local id="$1"
  if [[ -f AGENTS.md ]] || [[ -f docs/templates/AGENTS.md ]]; then
    echo "PASS $id:agents_md_exists"
    return 0
  fi
  echo "FAIL $id:agents_md_exists — AGENTS.md missing"
  return 1
}

assert_symlink_claude_md() {
  local id="$1"
  if [[ -L CLAUDE.md ]] || [[ -f CLAUDE.md ]]; then
    echo "PASS $id:symlink_claude_md"
    return 0
  fi
  echo "FAIL $id:symlink_claude_md — CLAUDE.md missing"
  return 1
}

assert_cursor_rules_nonempty() {
  local id="$1"
  if [[ -d .cursor/rules ]] && [[ -n "$(ls -A .cursor/rules 2>/dev/null)" ]]; then
    echo "PASS $id:cursor_rules_nonempty"
    return 0
  fi
  echo "FAIL $id:cursor_rules_nonempty — .cursor/rules empty"
  return 1
}

assert_gemini_ext_exists() {
  local id="$1"
  if [[ -d .gemini/extensions/bigpowers ]]; then
    echo "PASS $id:gemini_ext_exists"
    return 0
  fi
  echo "FAIL $id:gemini_ext_exists — gemini extension missing"
  return 1
}

assert_gemini_hooks_manifest() {
  local id="$1"
  if GEMINI_EXT_DIR=".gemini/extensions/bigpowers" bash scripts/adapters/gemini.sh --validate-hooks >/dev/null 2>&1; then
    echo "PASS $id:gemini_hooks_manifest"
    return 0
  fi
  echo "FAIL $id:gemini_hooks_manifest — hook templates invalid"
  return 1
}

assert_pi_skills_nonempty() {
  local id="$1"
  if [[ -d .pi/skills ]] && [[ -n "$(ls -A .pi/skills 2>/dev/null)" ]]; then
    echo "PASS $id:pi_skills_nonempty"
    return 0
  fi
  echo "FAIL $id:pi_skills_nonempty — .pi/skills empty"
  return 1
}

assert_aider_bridge() {
  local id="$1"
  if [[ -f .aider.conf.yml ]] && grep -q 'AGENTS.md' .aider.conf.yml 2>/dev/null; then
    echo "PASS $id:aider_bridge"
    return 0
  fi
  echo "SKIP $id:aider_bridge — opt_in not wired"
  return 0
}

assert_agy_skills_nonempty() {
  local id="$1"
  if [[ -d .agents/skills ]] && [[ -n "$(ls -A .agents/skills 2>/dev/null)" ]]; then
    echo "PASS $id:agy_skills_nonempty"
    return 0
  fi
  echo "FAIL $id:agy_skills_nonempty — .agents/skills empty"
  return 1
}

# Generic hooks-manifest assertion for every target that ships one under
# scripts/hooks/<target>/. Before this existed, cline/codebuddy/codex/kilocode/
# qwen/trae/windsurf all declared <target>_hooks_manifest in targets.yaml and
# every one of them fell through run_contract's default branch to SKIP + exit 0
# — seven declared contracts that could never fail.
assert_hooks_manifest() {
  local id="$1"
  local contract="$2"
  local target="${contract%_hooks_manifest}"
  local manifest="scripts/hooks/${target}/hooks-manifest.json"

  if [[ ! -f "$manifest" ]]; then
    echo "FAIL $id:$contract — $manifest missing"
    return 1
  fi
  # verify-install.sh sources this file without lib/python-env.sh, so resolve an
  # interpreter locally rather than relying on $PYTHON being set.
  local py="${PYTHON:-}"
  [[ -n "$py" ]] || py="$(command -v python3 || command -v python || true)"
  if [[ -n "$py" ]] && ! "$py" -c "import json; json.load(open('$manifest'))" 2>/dev/null; then
    echo "FAIL $id:$contract — $manifest is not valid JSON"
    return 1
  fi
  echo "PASS $id:$contract"
  return 0
}

run_contract() {
  local id="$1"
  local contract="$2"
  case "$contract" in
    agents_md_exists) assert_agents_md "$id" ;;
    symlink_claude_md) assert_symlink_claude_md "$id" ;;
    cursor_rules_nonempty) assert_cursor_rules_nonempty "$id" ;;
    gemini_ext_exists) assert_gemini_ext_exists "$id" ;;
    # gemini has its own adapter-level validator; keep it ahead of the generic
    # pattern below so the more specific check wins.
    gemini_hooks_manifest) assert_gemini_hooks_manifest "$id" ;;
    *_hooks_manifest) assert_hooks_manifest "$id" "$contract" ;;
    pi_skills_nonempty) assert_pi_skills_nonempty "$id" ;;
    agy_skills_nonempty) assert_agy_skills_nonempty "$id" ;;
    aider_bridge) assert_aider_bridge "$id" ;;
    # A contract declared in targets.yaml with no assertion behind it is a
    # broken contract, not a no-op. Failing here is what makes the registry an
    # enforced interface rather than documentation.
    *)
      echo "FAIL $id:$contract — unknown contract (no assertion implemented)"
      return 1
      ;;
  esac
}
