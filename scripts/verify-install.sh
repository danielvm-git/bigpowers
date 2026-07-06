#!/usr/bin/env bash
# story: e47s04 e37s02 e37s04 e37s08
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

cleanup() { [[ -n "$TMPDIR" && -d "$TMPDIR" ]] && rm -rf "$TMPDIR"; }
trap cleanup EXIT

pass() { echo "  PASS $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL $1"; FAIL=$((FAIL + 1)); }

echo "=== install.sh --dry-run ==="
DRY_OUT="$("$REPO_ROOT/scripts/install.sh" --dry-run 2>&1)"

echo "$DRY_OUT" | grep -q 'pi →' && pass "install --dry-run includes pi" || fail "install --dry-run missing pi"
DRY_UNINSTALL="$("$REPO_ROOT/scripts/install.sh" --dry-run --uninstall 2>&1)"
echo "$DRY_UNINSTALL" | grep -q 'pi →' && pass "uninstall --dry-run includes pi" || fail "uninstall --dry-run missing pi"
echo "$DRY_OUT" | grep -qi 'opencode' && fail "install references opencode" || pass "install has no opencode reference"
echo "$DRY_OUT" | grep -q 'Claude Code →' && pass "install includes Claude Code" || fail "install missing Claude Code"
echo "$DRY_OUT" | grep -q 'Gemini CLI →' && pass "install includes Gemini CLI" || fail "install missing Gemini CLI"
echo "$DRY_OUT" | grep -q 'Cursor →' && pass "install includes Cursor" || fail "install missing Cursor"

for tool in "Claude Code" "pi"; do
  section=$(echo "$DRY_OUT" | sed -n "/${tool} →/,/^$/p")
  count=$(echo "$section" | grep -o '[0-9]\+ skills installed' | grep -o '[0-9]\+' || echo "0")
  [[ "$count" -gt 0 ]] && pass "${tool}: $count skills" || fail "${tool}: 0 skills"
done

echo ""
echo "=== AGENTS.md spine (e37s04) ==="
[[ -f "$REPO_ROOT/docs/templates/AGENTS.md" ]] && pass "Reach template exists" || fail "Reach template missing"
grep -q 'Preflight' "$REPO_ROOT/docs/templates/AGENTS.md" && pass "template: Preflight" || fail "template: missing Preflight"
grep -qi 'cline\|aider\|opencode' "$REPO_ROOT/docs/templates/AGENTS.md" && pass "template: multi-agent preamble" || fail "template: missing OSS targets"
grep -q '## Test' "$REPO_ROOT/docs/templates/AGENTS.md" && pass "template: Test section" || fail "template: missing Test"
grep -q '## Lint' "$REPO_ROOT/docs/templates/AGENTS.md" && pass "template: Lint section" || fail "template: missing Lint"
grep -q '## Build' "$REPO_ROOT/docs/templates/AGENTS.md" && pass "template: Build section" || fail "template: missing Build"

echo ""
echo "=== Cline native AGENTS.md (e37s02) ==="
[[ -f "$REPO_ROOT/AGENTS.md" || -f "$REPO_ROOT/docs/templates/AGENTS.md" ]] && pass "Cline: AGENTS.md present (native reader)" || fail "Cline: AGENTS.md missing"
grep -qi 'cline' "$REPO_ROOT/skills/using-bigpowers/SKILL.md" && pass "using-bigpowers: Cline section" || fail "using-bigpowers: missing Cline"

echo ""
echo "=== Aider bridge (e37s03) ==="
grep -qi 'aider' "$REPO_ROOT/skills/seed-conventions/SKILL.md" && pass "seed-conventions: Aider wiring" || fail "seed-conventions: missing Aider"
grep -qi 'Aider-AI' "$REPO_ROOT/skills/using-bigpowers/SKILL.md" && pass "using-bigpowers: Aider-AI upstream" || fail "using-bigpowers: missing Aider-AI"

echo ""
echo "=== Optional Codex wave (e37s04) ==="
if grep -qi 'codex' "$REPO_ROOT/skills/seed-conventions/SKILL.md" 2>/dev/null; then
  grep -qi 'config.toml' "$REPO_ROOT/skills/seed-conventions/REFERENCE.md" && pass "Codex: REFERENCE config.toml" || fail "Codex: missing config.toml"
  echo "$DRY_OUT" | grep -qi 'codex' && pass "Codex: install --dry-run mentions codex" || fail "Codex: install missing codex"
else
  pass "Codex: wave absent — assertions skipped"
fi

echo ""
echo "=== seed-conventions local wiring ==="
grep -qi 'local tool wiring' "$REPO_ROOT/skills/seed-conventions/SKILL.md" && pass "SKILL.md: local tool wiring" || fail "SKILL.md: missing local tool wiring"
grep -qi 'opencode.json' "$REPO_ROOT/skills/seed-conventions/REFERENCE.md" && pass "REFERENCE.md: opencode.json" || fail "REFERENCE.md: missing opencode.json"
grep -qi 'AGENTS.md' "$REPO_ROOT/skills/seed-conventions/SKILL.md" && pass "SKILL.md: AGENTS.md spine" || fail "SKILL.md: missing AGENTS.md"
grep -qi 'symlink' "$REPO_ROOT/skills/seed-conventions/SKILL.md" && pass "SKILL.md: CLAUDE.md symlink" || fail "SKILL.md: missing symlink"
grep -qi 'cursor/rules' "$REPO_ROOT/skills/seed-conventions/REFERENCE.md" && pass "REFERENCE.md: Cursor symlink" || fail "REFERENCE.md: missing Cursor symlink"

OPENCODE_JSON=$(sed -n '/```json/,/```/p' "$REPO_ROOT/skills/seed-conventions/REFERENCE.md" | grep -v '```' || true)
if [[ -n "$OPENCODE_JSON" ]]; then
  TMPDIR=$(mktemp -d)
  echo "$OPENCODE_JSON" > "$TMPDIR/test-opencode.json"
  jq empty "$TMPDIR/test-opencode.json" 2>/dev/null && pass "opencode.json valid JSON" || fail "opencode.json NOT valid JSON"
else
  fail "opencode.json template not found"
fi

echo ""
echo "=== install.sh source ==="
grep -q 'install_pi()' "$REPO_ROOT/scripts/install.sh" && pass "source: install_pi()" || fail "source: missing install_pi()"
grep -q 'uninstall_pi()' "$REPO_ROOT/scripts/install.sh" && pass "source: uninstall_pi()" || fail "source: missing uninstall_pi()"
grep -q 'PI_SKILLS_DIR="$PI_CONFIG_DIR/agent/skills"' "$REPO_ROOT/scripts/install.sh" && pass "source: targets ~/.pi/agent/skills/" || fail "source: wrong pi target"
! grep -q 'install_opencode\|print_opencode_instructions' "$REPO_ROOT/scripts/install.sh" && pass "source: no opencode functions" || fail "source: opencode functions remain"

echo ""
echo "──────────────────────────────────────────"
echo "verify-install: $PASS passed, $FAIL failed"
[[ "$FAIL" -gt 0 ]] && { echo "Overall: fail"; exit 1; } || echo "Overall: pass"
