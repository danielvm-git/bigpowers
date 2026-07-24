#!/usr/bin/env bash
# story: e47s04 e37s02 e37s04 e37s08
# story: e74s02
# story: e67s02
# story: e66s02
# story: e72s02
# story: e68s02
# story: e65s02
# verify-install.sh — manual assertion harness for install + seed wiring + Reach matrix
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root

MATRIX_MODE=0
FULL_MATRIX=0
for arg in "$@"; do
  case "$arg" in
    --matrix) MATRIX_MODE=1 ;;
    --full) FULL_MATRIX=1 ;;
  esac
done

if [[ "$MATRIX_MODE" -eq 1 ]]; then
  source "$(dirname "${BASH_SOURCE[0]}")/lib/target-contracts.sh"
  command -v yq >/dev/null || { echo "verify-install: yq required for --matrix" >&2; exit 1; }
  cd "$REPO_ROOT"
  PASS=0
  FAIL=0
  while IFS= read -r row; do
    id=$(echo "$row" | yq -r '.id')
    tier=$(echo "$row" | yq -r '.tier')
    [[ "$tier" == "optional" && "$FULL_MATRIX" -eq 0 ]] && continue
    if [[ "$tier" == "opt_in" ]]; then
      echo "${id}: SKIP (opt_in)"
      continue
    fi
    contracts=$(echo "$row" | yq -r '.contracts // [] | .[]' 2>/dev/null || true)
    target_pass=1
    while IFS= read -r contract; do
      [[ -z "$contract" ]] && continue
      result=$(run_contract "$id" "$contract" 2>&1 | head -1)
      echo "$result"
      [[ "$result" == FAIL* ]] && target_pass=0
    done <<< "$contracts"
    if [[ "$target_pass" -eq 1 ]]; then
      echo "${id}: PASS"
      PASS=$((PASS + 1))
    else
      echo "${id}: FAIL"
      FAIL=$((FAIL + 1))
    fi
  done < <(yq -o=json '.targets[]' "$REPO_ROOT/scripts/targets.yaml" | jq -c '.')
  echo "verify-install --matrix: $PASS passed, $FAIL failed"
  [[ "$FAIL" -eq 0 && "$PASS" -gt 0 ]] || exit 1
  exit 0
fi

PASS=0
FAIL=0
TMPDIR=""
TA_PASS=0
TA_FAIL=0
TA_TMPDIR=""

source "$(dirname "${BASH_SOURCE[0]}")/lib/test-assertions.sh"
trap ta_cleanup EXIT


echo "=== install.sh --dry-run ==="
DRY_OUT="$("$REPO_ROOT/scripts/install.sh" --dry-run 2>&1)"

grep -q 'pi →' <<< "$DRY_OUT" && ta_pass "install --dry-run includes pi" || ta_fail "install --dry-run missing pi"
DRY_UNINSTALL="$("$REPO_ROOT/scripts/install.sh" --dry-run --uninstall 2>&1)"
grep -q 'pi →' <<< "$DRY_UNINSTALL" && ta_pass "uninstall --dry-run includes pi" || ta_fail "uninstall --dry-run missing pi"
grep -qi 'opencode' <<< "$DRY_OUT" && ta_fail "install references opencode" || ta_pass "install has no opencode reference"
grep -q 'Claude Code →' <<< "$DRY_OUT" && ta_pass "install includes Claude Code" || ta_fail "install missing Claude Code"
grep -q 'Gemini CLI →' <<< "$DRY_OUT" && ta_pass "install includes Gemini CLI" || ta_fail "install missing Gemini CLI"
grep -q 'Cursor →' <<< "$DRY_OUT" && ta_pass "install includes Cursor" || ta_fail "install missing Cursor"
grep -q 'Hermes Agent →' <<< "$DRY_OUT" && ta_pass "install includes Hermes Agent" || ta_fail "install missing Hermes Agent"

for tool in "Claude Code" "pi"; do
  section=$(echo "$DRY_OUT" | sed -n "/${tool} →/,/^$/p")
  count=$(echo "$section" | grep -o '[0-9]\+ skills installed' | grep -o '[0-9]\+' || echo "0")
  [[ "$count" -gt 0 ]] && ta_pass "${tool}: $count skills" || ta_fail "${tool}: 0 skills"
done

echo ""
echo "=== AGENTS.md spine (e37s04) ==="
[[ -f "$REPO_ROOT/docs/templates/AGENTS.md" ]] && ta_pass "Reach template exists" || ta_fail "Reach template missing"
grep -q 'Preflight' "$REPO_ROOT/docs/templates/AGENTS.md" && ta_pass "template: Preflight" || ta_fail "template: missing Preflight"
grep -qi 'cline\|aider\|opencode' "$REPO_ROOT/docs/templates/AGENTS.md" && ta_pass "template: multi-agent preamble" || ta_fail "template: missing OSS targets"
grep -q '## Test' "$REPO_ROOT/docs/templates/AGENTS.md" && ta_pass "template: Test section" || ta_fail "template: missing Test"
grep -q '## Lint' "$REPO_ROOT/docs/templates/AGENTS.md" && ta_pass "template: Lint section" || ta_fail "template: missing Lint"
grep -q '## Build' "$REPO_ROOT/docs/templates/AGENTS.md" && ta_pass "template: Build section" || ta_fail "template: missing Build"

echo ""
echo "=== Cline native AGENTS.md (e37s02) ==="
[[ -f "$REPO_ROOT/AGENTS.md" || -f "$REPO_ROOT/docs/templates/AGENTS.md" ]] && ta_pass "Cline: AGENTS.md present (native reader)" || ta_fail "Cline: AGENTS.md missing"
grep -qi 'cline' "$REPO_ROOT/skills/using-bigpowers/SKILL.md" && ta_pass "using-bigpowers: Cline section" || ta_fail "using-bigpowers: missing Cline"

echo ""
echo "=== Aider bridge (e37s03) ==="
grep -qi 'aider' "$REPO_ROOT/skills/seed-conventions/SKILL.md" && ta_pass "seed-conventions: Aider wiring" || ta_fail "seed-conventions: missing Aider"
grep -qi 'Aider-AI' "$REPO_ROOT/skills/using-bigpowers/SKILL.md" && ta_pass "using-bigpowers: Aider-AI upstream" || ta_fail "using-bigpowers: missing Aider-AI"

echo ""
echo "=== Optional Codex wave (e37s04) ==="
if grep -qi 'codex' "$REPO_ROOT/skills/seed-conventions/SKILL.md" 2>/dev/null; then
  grep -qi 'config.toml' "$REPO_ROOT/skills/seed-conventions/REFERENCE.md" && ta_pass "Codex: REFERENCE config.toml" || ta_fail "Codex: missing config.toml"
  grep -qi 'codex' <<< "$DRY_OUT" && ta_pass "Codex: install --dry-run mentions codex" || ta_fail "Codex: install missing codex"
else
  ta_pass "Codex: wave absent — assertions skipped"
fi

echo ""
echo "=== seed-conventions local wiring ==="
grep -qi 'local tool wiring' "$REPO_ROOT/skills/seed-conventions/SKILL.md" && ta_pass "SKILL.md: local tool wiring" || ta_fail "SKILL.md: missing local tool wiring"
grep -qi 'opencode.json' "$REPO_ROOT/skills/seed-conventions/REFERENCE.md" && ta_pass "REFERENCE.md: opencode.json" || ta_fail "REFERENCE.md: missing opencode.json"
grep -qi 'AGENTS.md' "$REPO_ROOT/skills/seed-conventions/SKILL.md" && ta_pass "SKILL.md: AGENTS.md spine" || ta_fail "SKILL.md: missing AGENTS.md"
grep -qi 'symlink' "$REPO_ROOT/skills/seed-conventions/SKILL.md" && ta_pass "SKILL.md: CLAUDE.md symlink" || ta_fail "SKILL.md: missing symlink"
grep -qi 'cursor/rules' "$REPO_ROOT/skills/seed-conventions/REFERENCE.md" && ta_pass "REFERENCE.md: Cursor symlink" || ta_fail "REFERENCE.md: missing Cursor symlink"

OPENCODE_JSON=$(sed -n '/```json/,/```/p' "$REPO_ROOT/skills/seed-conventions/REFERENCE.md" | grep -v '```' || true)
if [[ -n "$OPENCODE_JSON" ]]; then
  TMPDIR=$(mktemp -d)
  TA_TMPDIR="$TMPDIR"
  echo "$OPENCODE_JSON" > "$TMPDIR/test-opencode.json"
  jq empty "$TMPDIR/test-opencode.json" 2>/dev/null && ta_pass "opencode.json valid JSON" || ta_fail "opencode.json NOT valid JSON"
else
  ta_fail "opencode.json template not found"
fi

echo ""
echo "=== install.sh source ==="
grep -q 'install_pi()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: install_pi()" || ta_fail "source: missing install_pi()"
grep -q 'uninstall_pi()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: uninstall_pi()" || ta_fail "source: missing uninstall_pi()"
grep -q 'PI_SKILLS_DIR="$PI_CONFIG_DIR/agent/skills"' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: targets ~/.pi/agent/skills/" || ta_fail "source: wrong pi target"
grep -q 'install_hermes()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: install_hermes()" || ta_fail "source: missing install_hermes()"
grep -q 'uninstall_hermes()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: uninstall_hermes()" || ta_fail "source: missing uninstall_hermes()"
grep -q 'HERMES_SKILLS_DIR=' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: targets ~/.hermes/skills/" || ta_fail "source: wrong hermes target"
grep -q "'hermes'" "$REPO_ROOT/bin/setup.js" && grep -q 'SUPPORTED_IDS' "$REPO_ROOT/bin/setup.js" && ta_pass "setup.js: hermes supported" || ta_fail "setup.js: hermes not in SUPPORTED_IDS"
grep -q "case 'hermes'" "$REPO_ROOT/scripts/lib/install-helpers.js" && ta_pass "install-helpers: hermes case" || ta_fail "install-helpers: missing hermes case"
grep -q 'install_zcode()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: install_zcode()" || ta_fail "source: missing install_zcode()"
grep -q 'uninstall_zcode()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: uninstall_zcode()" || ta_fail "source: missing uninstall_zcode()"
grep -q 'ZCODE_SKILLS_DIR=' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: targets ~/.zcode/skills/" || ta_fail "source: wrong zcode target"
grep -q "'zcode'" "$REPO_ROOT/bin/setup.js" && grep -q 'SUPPORTED_IDS' "$REPO_ROOT/bin/setup.js" && ta_pass "setup.js: zcode supported" || ta_fail "setup.js: zcode not in SUPPORTED_IDS"
grep -q "case 'zcode'" "$REPO_ROOT/scripts/lib/install-helpers.js" && ta_pass "install-helpers: zcode case" || ta_fail "install-helpers: missing zcode case"
grep -q 'install_mimo()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: install_mimo()" || ta_fail "source: missing install_mimo()"
grep -q 'uninstall_mimo()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: uninstall_mimo()" || ta_fail "source: missing uninstall_mimo()"
grep -q 'MIMO_SKILLS_DIR=' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: targets ~/.mimocode/skills/" || ta_fail "source: wrong mimo target"
grep -q "'mimo'" "$REPO_ROOT/bin/setup.js" && grep -q 'SUPPORTED_IDS' "$REPO_ROOT/bin/setup.js" && ta_pass "setup.js: mimo supported" || ta_fail "setup.js: mimo not in SUPPORTED_IDS"
grep -q "case 'mimo'" "$REPO_ROOT/scripts/lib/install-helpers.js" && ta_pass "install-helpers: mimo case" || ta_fail "install-helpers: missing mimo case"
grep -q 'install_gemini()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: install_gemini()" || ta_fail "source: missing install_gemini()"
grep -q 'uninstall_gemini()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: uninstall_gemini()" || ta_fail "source: missing uninstall_gemini()"
grep -q 'before-tool-git-guard.sh' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: gemini Wave A hook templates" || ta_fail "source: missing gemini hook templates"
grep -q "'gemini'" "$REPO_ROOT/bin/setup.js" && grep -q 'SUPPORTED_IDS' "$REPO_ROOT/bin/setup.js" && ta_pass "setup.js: gemini supported" || ta_fail "setup.js: gemini not in SUPPORTED_IDS"
grep -q "case 'gemini'" "$REPO_ROOT/scripts/lib/install-helpers.js" && ta_pass "install-helpers: gemini case" || ta_fail "install-helpers: missing gemini case"
grep -q 'gemini_hooks_manifest' "$REPO_ROOT/scripts/targets.yaml" && ta_pass "targets.yaml: gemini_hooks_manifest" || ta_fail "targets.yaml: missing gemini_hooks_manifest"
grep -q 'install_agy()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: install_agy()" || ta_fail "source: missing install_agy()"
grep -q 'uninstall_agy()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: uninstall_agy()" || ta_fail "source: missing uninstall_agy()"
grep -q 'AGY_SKILLS_DIR=' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: targets ~/.gemini/antigravity-cli/skills/" || ta_fail "source: wrong agy target"
grep -q "'antigravity'" "$REPO_ROOT/bin/setup.js" && grep -q 'SUPPORTED_IDS' "$REPO_ROOT/bin/setup.js" && ta_pass "setup.js: antigravity supported" || ta_fail "setup.js: antigravity not in SUPPORTED_IDS"
grep -q "'agy'" "$REPO_ROOT/bin/setup.js" && ta_pass "setup.js: agy supported" || ta_fail "setup.js: agy not in SUPPORTED_IDS"
grep -q "case 'antigravity'" "$REPO_ROOT/scripts/lib/install-helpers.js" && ta_pass "install-helpers: antigravity case" || ta_fail "install-helpers: missing antigravity case"
grep -q "case 'agy'" "$REPO_ROOT/scripts/lib/install-helpers.js" && ta_pass "install-helpers: agy case" || ta_fail "install-helpers: missing agy case"
! grep -q '\.gemini/extensions/bigpowers' <<< "$(sed -n '/install_agy/,/^}/p' "$REPO_ROOT/scripts/install.sh")" && ta_pass "source: agy avoids gemini extension path" || ta_fail "source: agy touches gemini extension path"
! grep -q 'install_opencode\|print_opencode_instructions' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: no opencode functions" || ta_fail "source: opencode functions remain"

grep -q 'install_codex()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: install_codex()" || ta_fail "source: missing install_codex()"
grep -q 'uninstall_codex()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: uninstall_codex()" || ta_fail "source: missing uninstall_codex()"
grep -q 'CODEX_SKILLS_DIR=' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: codex skills dir" || ta_fail "source: missing codex skills dir"
grep -q "'codex'" "$REPO_ROOT/bin/setup.js" && grep -q 'SUPPORTED_IDS' "$REPO_ROOT/bin/setup.js" && ta_pass "setup.js: codex supported" || ta_fail "setup.js: codex not in SUPPORTED_IDS"
grep -q "case 'codex'" "$REPO_ROOT/scripts/lib/install-helpers.js" && ta_pass "install-helpers: codex case" || ta_fail "install-helpers: missing codex case"
grep -q 'install_qwen()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: install_qwen()" || ta_fail "source: missing install_qwen()"
grep -q 'uninstall_qwen()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: uninstall_qwen()" || ta_fail "source: missing uninstall_qwen()"
grep -q 'QWEN_SKILLS_DIR=' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: qwen skills dir" || ta_fail "source: missing qwen skills dir"
grep -q "'qwen'" "$REPO_ROOT/bin/setup.js" && grep -q 'SUPPORTED_IDS' "$REPO_ROOT/bin/setup.js" && ta_pass "setup.js: qwen supported" || ta_fail "setup.js: qwen not in SUPPORTED_IDS"
grep -q "case 'qwen'" "$REPO_ROOT/scripts/lib/install-helpers.js" && ta_pass "install-helpers: qwen case" || ta_fail "install-helpers: missing qwen case"
grep -q 'install_codebuddy()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: install_codebuddy()" || ta_fail "source: missing install_codebuddy()"
grep -q 'uninstall_codebuddy()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: uninstall_codebuddy()" || ta_fail "source: missing uninstall_codebuddy()"
grep -q 'CODEBUDDY_SKILLS_DIR=' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: codebuddy skills dir" || ta_fail "source: missing codebuddy skills dir"
grep -q "'codebuddy'" "$REPO_ROOT/bin/setup.js" && grep -q 'SUPPORTED_IDS' "$REPO_ROOT/bin/setup.js" && ta_pass "setup.js: codebuddy supported" || ta_fail "setup.js: codebuddy not in SUPPORTED_IDS"
grep -q "case 'codebuddy'" "$REPO_ROOT/scripts/lib/install-helpers.js" && ta_pass "install-helpers: codebuddy case" || ta_fail "install-helpers: missing codebuddy case"
grep -q 'install_cline()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: install_cline()" || ta_fail "source: missing install_cline()"
grep -q 'uninstall_cline()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: uninstall_cline()" || ta_fail "source: missing uninstall_cline()"
grep -q 'CLINE_SKILLS_DIR=' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: cline skills dir" || ta_fail "source: missing cline skills dir"
grep -q "'cline'" "$REPO_ROOT/bin/setup.js" && grep -q 'SUPPORTED_IDS' "$REPO_ROOT/bin/setup.js" && ta_pass "setup.js: cline supported" || ta_fail "setup.js: cline not in SUPPORTED_IDS"
grep -q "case 'cline'" "$REPO_ROOT/scripts/lib/install-helpers.js" && ta_pass "install-helpers: cline case" || ta_fail "install-helpers: missing cline case"
grep -q 'install_kilocode()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: install_kilocode()" || ta_fail "source: missing install_kilocode()"
grep -q 'uninstall_kilocode()' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: uninstall_kilocode()" || ta_fail "source: missing uninstall_kilocode()"
grep -q 'KILOCODE_SKILLS_DIR=' "$REPO_ROOT/scripts/install.sh" && ta_pass "source: kilocode skills dir" || ta_fail "source: missing kilocode skills dir"
grep -q "'kilo'" "$REPO_ROOT/bin/setup.js" && grep -q 'SUPPORTED_IDS' "$REPO_ROOT/bin/setup.js" && ta_pass "setup.js: kilo supported" || ta_fail "setup.js: kilo not in SUPPORTED_IDS"
grep -q "case 'kilo'" "$REPO_ROOT/scripts/lib/install-helpers.js" && ta_pass "install-helpers: kilo case" || ta_fail "install-helpers: missing kilo case"
echo ""
echo "──────────────────────────────────────────"
echo "verify-install: $TA_PASS passed, $TA_FAIL failed"
[[ "$TA_FAIL" -gt 0 ]] && { echo "Overall: fail"; exit 1; } || echo "Overall: pass"
