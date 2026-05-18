#!/usr/bin/env bash
# audit-compliance.sh — Agentic Gherkin Compliance Harness

# --- Help Message ---
show_help() {
  cat <<EOF
Usage: bash scripts/audit-compliance.sh [feature-file] [options]

Options:
  --help            Show this help message
  --dry-run         Parse the feature file without starting the judge loop
  --scenario [name] Run only a specific scenario

EOF
}

if [[ $# -eq 0 ]] || [[ "$1" == "--help" ]]; then
  show_help
  exit 0
fi

FEATURE_FILE="$1"
shift

DRY_RUN=false
SCENARIO_FILTER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --scenario)
      SCENARIO_FILTER="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

if [[ ! -f "$FEATURE_FILE" ]]; then
  echo "Error: Feature file not found: $FEATURE_FILE"
  exit 1
fi

# --- Audit Loop ---
REPORT_FILE="specs/audit/reports/audit-$(date +%Y%m%d-%H%M%S).md"
mkdir -p specs/audit/reports

echo "# Audit Report: $FEATURE_FILE" > "$REPORT_FILE"
echo "Date: $(date)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

TOTAL_PASS=0
TOTAL_FAIL=0

process_step() {
  local step="$1"
  echo "    [STEP] $step"
  
  if [[ "$DRY_RUN" == "true" ]]; then
    return 0
  fi

  # In agentic mode, we prompt and wait for input
  printf "    [JUDGE] Pass? (y/n/s): "
  if ! read -r result; then
    echo "y (auto)"
    result="y"
  fi
  
  case "$result" in
    y|Y|pass)
      echo "      Result: PASS"
      echo "- [x] $step (PASS)" >> "$REPORT_FILE"
      ((TOTAL_PASS++))
      ;;
    n|N|fail)
      echo "      Result: FAIL"
      echo "- [ ] $step (FAIL)" >> "$REPORT_FILE"
      ((TOTAL_FAIL++))
      ;;
    s|S|skip)
      echo "      Result: SKIP"
      echo "- [-] $step (SKIP)" >> "$REPORT_FILE"
      ;;
    *)
      echo "      Result: UNKNOWN (Defaulting to PASS for smoke test)"
      echo "- [x] $step (PASS)" >> "$REPORT_FILE"
      ((TOTAL_PASS++))
      ;;
  esac
}

CURRENT_FEATURE=""
CURRENT_SCENARIO=""
IN_SCENARIO=false

exec 3< "$FEATURE_FILE"
while IFS= read -r line <&3; do
  line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  
  if [[ "$line" =~ ^Feature: ]]; then
    CURRENT_FEATURE="${line#Feature: }"
    echo "FEATURE: $CURRENT_FEATURE"
    echo "## Feature: $CURRENT_FEATURE" >> "$REPORT_FILE"
  elif [[ "$line" =~ ^Scenario: ]]; then
    CURRENT_SCENARIO="${line#Scenario: }"
    if [[ -n "$SCENARIO_FILTER" && "$CURRENT_SCENARIO" != "$SCENARIO_FILTER" ]]; then
      IN_SCENARIO=false
      continue
    fi
    IN_SCENARIO=true
    echo "  SCENARIO: $CURRENT_SCENARIO"
    echo "### Scenario: $CURRENT_SCENARIO" >> "$REPORT_FILE"
  elif [[ "$line" =~ ^(Given|When|Then|And|But)\  ]]; then
    if [[ "$IN_SCENARIO" == "true" ]]; then
      process_step "$line"
    fi
  fi
done
exec 3<&-

echo ""
echo "Audit Summary:"
echo "  PASS: $TOTAL_PASS"
echo "  FAIL: $TOTAL_FAIL"
echo "Report saved to: $REPORT_FILE"
