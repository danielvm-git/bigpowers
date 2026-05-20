#!/usr/bin/env bash
# audit-compliance.sh — Agentic Gherkin Compliance Harness (LLM-Judge Upgrade)

# --- Help Message ---
show_help() {
  cat <<EOF
Usage: bash scripts/audit-compliance.sh [feature-file|directory] [options]

Options:
  --help            Show this help message
  --dry-run         Parse the feature file without starting the judge loop
  --scenario [name] Run only a specific scenario
  --judge [type]    Judge type: 'binary' (exit code, default) or 'gemini' (LLM-judged)
  --model [name]    Model name to use for judging

If a directory is provided, all .feature files in that directory will be processed.
EOF
}

# --- Arguments Parsing ---
DRY_RUN=false
SCENARIO_FILTER=""
JUDGE="binary"
MODEL=""
INPUTS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help)
      show_help
      exit 0
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --scenario)
      SCENARIO_FILTER="$2"
      shift 2
      ;;
    --judge)
      JUDGE="$2"
      shift 2
      ;;
    --model)
      MODEL="$2"
      shift 2
      ;;
    -*)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
    *)
      INPUTS+=("$1")
      shift
      ;;
  esac
done

if [[ ${#INPUTS[@]} -eq 0 ]]; then
  echo "Error: No feature file or directory specified."
  show_help
  exit 1
fi

# --- Global Stats ---
TOTAL_GLOBAL_PASS=0
TOTAL_GLOBAL_FAIL=0

# --- Judging Logic ---

judge_with_gemini() {
  local step="$1"
  local feature_name="$2"
  local scenario_name="$3"
  local evidence="$4"
  local report_file="$5"

  echo "    [JUDGE] Sending evidence to Gemini CLI..."
  
  local prompt="You are the Master Test Architect judging a compliance audit.
Benchmark Feature: $feature_name
Scenario: $scenario_name
Compliance Step: $step

Evidence gathered from the codebase:
---
$evidence
---

Based on the benchmark principles, does this evidence demonstrate compliance?
Respond strictly in the following format:
VERDICT: [PASS/FAIL]
RATIONALE: [One sentence explanation]"

  local model_output
  local gemini_cmd="gemini --approval-mode plan"
  if [[ -n "$MODEL" ]]; then
    gemini_cmd="$gemini_cmd -m $MODEL"
  fi
  
  model_output=$($gemini_cmd -p "$prompt" 2>&1)
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    local verdict
    verdict=$(echo "$model_output" | grep "VERDICT:" | cut -d' ' -f2)
    local rationale
    rationale=$(echo "$model_output" | grep "RATIONALE:" | cut -d' ' -f2-)

    if [[ "$verdict" == "PASS" ]]; then
      echo "      Result: PASS"
      echo "- [x] $step (PASS) - $rationale" >> "$report_file"
      return 0
    else
      echo "      Result: FAIL"
      echo "- [ ] $step (FAIL) - $rationale" >> "$report_file"
      return 1
    fi
  else
    echo "      Result: ERROR (Gemini CLI failed)"
    echo "- [ ] $step (ERROR) - Gemini CLI exit code $exit_code. Output: $model_output" >> "$report_file"
    return 1
  fi
}

judge_binary() {
  local step="$1"
  local exit_code="$2"
  local evidence="$3"
  local report_file="$4"

  if [[ $exit_code -eq 0 ]]; then
    echo "      Result: PASS"
    echo "- [x] $step (PASS)" >> "$report_file"
    return 0
  else
    echo "      Result: FAIL"
    echo "- [ ] $step (FAIL) - $evidence" >> "$report_file"
    return 1
  fi
}

# --- Core Execution ---

process_step() {
  local step="$1"
  local feature_name="$2"
  local scenario_name="$3"
  local report_file="$4"
  echo "    [STEP] $step"
  
  if [[ "$DRY_RUN" == "true" ]]; then
    return 0
  fi

  local sanitized_step
  sanitized_step=$(echo "$step" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
  local step_script="specs/audit/steps/${sanitized_step}.sh"

  if [[ -f "$step_script" ]]; then
    echo "    [EXEC] Gathering evidence: $step_script"
    local evidence
    evidence=$(bash "$step_script" 2>&1)
    local exit_code=$?

    if [[ "$JUDGE" == "gemini" ]]; then
      judge_with_gemini "$step" "$feature_name" "$scenario_name" "$evidence" "$report_file"
    else
      judge_binary "$step" "$exit_code" "$evidence" "$report_file"
    fi
  else
    echo "      Result: FAIL (Missing evidence: $step_script)"
    echo "- [ ] $step (FAIL) - No verification script found at $step_script" >> "$report_file"
    return 1
  fi
}

run_audit_file() {
  local FEATURE_FILE="$1"
  echo "------------------------------------------------------------"
  echo "FEATURE: $FEATURE_FILE"
  
  local REPORT_FILE="specs/audit/reports/audit-$(basename "$FEATURE_FILE" .feature)-$(date +%Y%m%d-%H%M%S).md"
  mkdir -p specs/audit/reports

  echo "# Audit Report: $FEATURE_FILE" > "$REPORT_FILE"
  echo "Date: $(date)" >> "$REPORT_FILE"
  echo "Mode: Autonomous Verification (Judge: $JUDGE)" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"

  local TOTAL_PASS=0
  local TOTAL_FAIL=0
  local CURRENT_FEATURE=""
  local CURRENT_SCENARIO=""
  local IN_SCENARIO=false

  while IFS= read -r line; do
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
        if process_step "$line" "$CURRENT_FEATURE" "$CURRENT_SCENARIO" "$REPORT_FILE"; then
          ((TOTAL_PASS++))
          ((TOTAL_GLOBAL_PASS++))
        else
          ((TOTAL_FAIL++))
          ((TOTAL_GLOBAL_FAIL++))
        fi
      fi
    fi
  done < "$FEATURE_FILE"

  echo ""
  echo "File Summary: PASS: $TOTAL_PASS, FAIL: $TOTAL_FAIL"
  echo "Report saved to: $REPORT_FILE"
}

# --- Main Execution ---
for input in "${INPUTS[@]}"; do
  if [[ -d "$input" ]]; then
    for f in "$input"/*.feature; do
      if [[ -f "$f" ]]; then
        run_audit_file "$f"
      fi
    done
  elif [[ -f "$input" ]]; then
    run_audit_file "$input"
  else
    echo "Warning: Input not found: $input"
  fi
done

echo "============================================================"
echo "Global Audit Summary:"
echo "  TOTAL PASS: $TOTAL_GLOBAL_PASS"
echo "  TOTAL FAIL: $TOTAL_GLOBAL_FAIL"
echo "============================================================"

if [[ $TOTAL_GLOBAL_FAIL -gt 0 ]]; then
  exit 1
fi
