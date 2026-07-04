#!/usr/bin/env bash
# run-golden-suite.sh — Deterministic golden suite runner
#
# Runs compliance → G-04 self-test in order, captures results,
# writes timestamped YAML report. Supports --dry-run and --baseline.
#
# Usage:
#   bash scripts/run-golden-suite.sh              # run all gates
#   bash scripts/run-golden-suite.sh --dry-run    # print plan only
#   bash scripts/run-golden-suite.sh --baseline   # run + pin baseline

set -euo pipefail

REPORT_DIR="specs/benchmarks/reports"
BASELINE_FILE="$REPORT_DIR/BASELINE-GOLDEN.yaml"
DRY_RUN=false
BASELINE_MODE=false
CHECK_SIZE=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --baseline) BASELINE_MODE=true ;;
    --check-size) CHECK_SIZE=true ;;
    *) echo "Unknown flag: $arg"; echo "Usage: run-golden-suite.sh [--dry-run] [--baseline] [--check-size]"; exit 2 ;;
  esac
done

# ── Gate definitions ──────────────────────────────────────────────────
# Each gate: name, command, optional: true (won't fail suite if missing)
GATES=(
  "compliance:npm run compliance:false"
  "g04-selftest:bash scripts/golden-g04-selftest.sh:true"
  "g07-negative-path:bash scripts/golden-g07-negative-path.sh:false"
  "g08-anti-vacuity:bash scripts/golden-g08-anti-vacuity.sh:false"
  "g09-yaml-roundtrip:bash scripts/golden-g09-yaml-roundtrip.sh:false"
  "g10-trace-anti-vacuity:bash scripts/golden-g10-trace-anti-vacuity.sh:false"
  "g11-gitignore-venv:bash scripts/golden-g11-gitignore-venv.sh:false"
  "specs-parse:bash scripts/validate-specs-yaml.sh:false"
)

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

# ── Dry run ───────────────────────────────────────────────────────────

if $DRY_RUN; then
  echo "Golden Suite — DRY RUN"
  echo "Gates (in order):"
  for gate in "${GATES[@]}"; do
    IFS=':' read -r name cmd optional <<< "$gate"
    echo "  - $name: $cmd"
  done
  echo "Report: $REPORT_DIR/GOLDEN-YYYY-MM-DD.yaml"
  echo "OK (dry run)"
  exit 0
fi

# ── Setup ─────────────────────────────────────────────────────────────

mkdir -p "$REPORT_DIR"

TODAY=$(date +%Y-%m-%d)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

if $BASELINE_MODE; then
  REPORT_FILE="$BASELINE_FILE"
else
  REPORT_FILE="$REPORT_DIR/GOLDEN-${TODAY}.yaml"
fi

# ── Run gates ─────────────────────────────────────────────────────────

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
GATE_RESULTS=()

for gate in "${GATES[@]}"; do
  IFS=':' read -r name cmd is_optional <<< "$gate"

  echo -n "[$name] "

  # Check if command exists (for scripts)
  main_cmd=$(echo "$cmd" | awk '{print $1}')
  if [[ "$main_cmd" == "bash" ]]; then
    script_path=$(echo "$cmd" | awk '{print $2}')
    if [[ ! -f "$script_path" ]]; then
      if [[ "$is_optional" == "true" ]]; then
        echo -e "${YELLOW}SKIP${NC} (script not yet implemented)"
        GATE_RESULTS+=("  - name: $name")
        GATE_RESULTS+=("    exit_code: skipped")
        GATE_RESULTS+=("    duration_seconds: 0")
        GATE_RESULTS+=("    status: skipped")
        GATE_RESULTS+=("    note: script not found: $script_path")
        (( SKIP_COUNT += 1 ))
        continue
      else
        echo -e "${RED}FAIL${NC} (script not found: $script_path)"
        GATE_RESULTS+=("  - name: $name")
        GATE_RESULTS+=("    exit_code: 127")
        GATE_RESULTS+=("    duration_seconds: 0")
        GATE_RESULTS+=("    status: fail")
        GATE_RESULTS+=("    error: script not found: $script_path")
        (( FAIL_COUNT += 1 ))
        continue
      fi
    fi
  fi

  # Run the gate and capture output
  START_TIME=$(date +%s%N)
  GATE_OUTPUT=$(eval "$cmd" 2>&1) && GATE_EXIT=$? || GATE_EXIT=$?
  END_TIME=$(date +%s%N)
  DURATION_MS=$(( (END_TIME - START_TIME) / 1000000 ))
  DURATION_SEC=$(echo "scale=2; $DURATION_MS / 1000" | bc 2>/dev/null || echo "0")

  if [[ "$GATE_EXIT" -eq 0 ]]; then
    echo -e "${GREEN}PASS${NC} (${DURATION_SEC}s)"
    GATE_RESULTS+=("  - name: $name")
    GATE_RESULTS+=("    exit_code: 0")
    GATE_RESULTS+=("    duration_seconds: $DURATION_SEC")
    GATE_RESULTS+=("    status: pass")
    (( PASS_COUNT += 1 ))
  else
    echo -e "${RED}FAIL${NC} (${DURATION_SEC}s, exit $GATE_EXIT)"
    GATE_RESULTS+=("  - name: $name")
    GATE_RESULTS+=("    exit_code: $GATE_EXIT")
    GATE_RESULTS+=("    duration_seconds: $DURATION_SEC")
    GATE_RESULTS+=("    status: fail")
    (( FAIL_COUNT += 1 ))
  fi
done

# ── Summary ───────────────────────────────────────────────────────────

TOTAL=$((PASS_COUNT + FAIL_COUNT + SKIP_COUNT))
if [[ "$FAIL_COUNT" -gt 0 ]]; then
  OVERALL="fail"
else
  OVERALL="pass"
fi

echo ""
echo "──────────────────────────────────────────"
echo -e "Suite: ${PASS_COUNT}/${TOTAL} passed"
if [[ "$SKIP_COUNT" -gt 0 ]]; then
  echo -e "       ${SKIP_COUNT} skipped (scripts not yet implemented)"
fi
echo -e "Overall: ${OVERALL}"
echo "Report: $REPORT_FILE"
echo "──────────────────────────────────────────"

# ── Write report ──────────────────────────────────────────────────────

PASS_RATE=$(echo "scale=2; $PASS_COUNT / $TOTAL" | bc 2>/dev/null || echo "0")

cat > "$REPORT_FILE" << YAML_EOF
timestamp: "$TIMESTAMP"
git_commit: "$GIT_COMMIT"
suite: "golden-deterministic"
mode: "$([ "$BASELINE_MODE" = true ] && echo 'baseline' || echo 'daily')"
gates:
$(printf '%s\n' "${GATE_RESULTS[@]}")
summary:
  total: $TOTAL
  passed: $PASS_COUNT
  failed: $FAIL_COUNT
  skipped: $SKIP_COUNT
  pass_rate: $PASS_RATE
  overall: "$OVERALL"
YAML_EOF

# ── Size budget (placeholder for e31s04) ──────────────────────────────

if $BASELINE_MODE; then
  echo "" >> "$REPORT_FILE"
  echo "# Skill byte counts (baseline for e31s04 size budget)" >> "$REPORT_FILE"
  echo "skill_sizes:" >> "$REPORT_FILE"
  for skill_md in skills/*/SKILL.md; do
    skill_name=$(basename "$(dirname "$skill_md")")
    skill_bytes=$(wc -c < "$skill_md" | tr -d ' ')
    echo "  $skill_name: $skill_bytes" >> "$REPORT_FILE"
  done
  echo "Baseline pinned: $REPORT_FILE"
fi

# ── Size budget check (e31s04) ───────────────────────────────────────

if $CHECK_SIZE; then
  WARN_THRESHOLD=20
  FAIL_THRESHOLD=50

  if [[ ! -f "$BASELINE_FILE" ]]; then
    echo "No baseline found. Run --baseline first."
    exit 1
  fi

  echo ""
  echo "Size Budget Check (+${WARN_THRESHOLD}% warn, +${FAIL_THRESHOLD}% fail):"
  SIZE_WARNINGS=0
  SIZE_FAILURES=0
  NEW_SKILLS=0

  for skill_md in skills/*/SKILL.md; do
    skill_name=$(basename "$(dirname "$skill_md")")
    current_bytes=$(wc -c < "$skill_md" | tr -d ' ')

    # Get baseline size (best-effort grep from YAML)
    baseline_bytes=$(grep "^  $skill_name:" "$BASELINE_FILE" 2>/dev/null | awk '{print $2}')

    if [[ -z "$baseline_bytes" ]]; then
      echo "  ${YELLOW}NEW${NC}  $skill_name: ${current_bytes}b (not in baseline)"
      (( NEW_SKILLS += 1 )) || true
      continue
    fi

    if [[ "$baseline_bytes" -eq 0 ]]; then
      baseline_bytes=1  # avoid division by zero
    fi

    pct=$(( (current_bytes - baseline_bytes) * 100 / baseline_bytes ))

    if [[ "$pct" -ge "$FAIL_THRESHOLD" ]]; then
      echo "  ${RED}FAIL${NC} $skill_name: ${current_bytes}b (+${pct}%)"
      (( SIZE_FAILURES += 1 )) || true
    elif [[ "$pct" -ge "$WARN_THRESHOLD" ]]; then
      echo "  ${YELLOW}WARN${NC} $skill_name: ${current_bytes}b (+${pct}%)"
      (( SIZE_WARNINGS += 1 )) || true
    else
      echo "  ${GREEN}OK${NC}   $skill_name: ${current_bytes}b"
    fi
  done

  echo ""
  echo "Size summary: $SIZE_WARNINGS warnings, $SIZE_FAILURES failures, $NEW_SKILLS new"

  if [[ "$SIZE_FAILURES" -gt 0 ]]; then
    exit 1
  fi
  exit 0
fi

if [[ "$OVERALL" == "fail" ]]; then
  exit 1
fi
exit 0
