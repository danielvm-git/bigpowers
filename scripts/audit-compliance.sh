#!/usr/bin/env bash
# audit-compliance.sh — Agentic Gherkin Compliance Harness (LLM-Judge Upgrade)
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
TOTAL_GLOBAL_WAIVED=0
TOTAL_GLOBAL_EXPIRED=0

# --- Waiver Subsystem ---
# Sourced from scripts/lib/waiver-utils.sh — provides has_waiver().
WAIVER_FILE="specs/verifications/waivers.yaml"
true && source "$(dirname "${BASH_SOURCE[0]}")/lib/waiver-utils.sh"

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
  local step_script="specs/verifications/steps/${sanitized_step}.sh"

  if [[ -f "$step_script" ]]; then
    echo "    [EXEC] Gathering evidence: $step_script"
    local evidence
    evidence=$(bash "$step_script" 2>&1)
    local exit_code=$?

    if [[ "$JUDGE" == "gemini" ]]; then
      judge_with_gemini "$step" "$feature_name" "$scenario_name" "$evidence" "$report_file"
      # Gemini path: rely on judge return code (no waiver check for LLM path)
    else
      # Binary path: check waivers before counting as FAIL
      if [[ $exit_code -eq 0 ]]; then
        echo "      Result: PASS"
        echo "- [x] $step (PASS)" >> "$report_file"
        return 0
      fi

      # Step failed — check if it has a valid waiver
      has_waiver "$sanitized_step"
      local waiver_code=$?

      if [[ $waiver_code -eq 0 ]]; then
        # Valid waiver — exclude from denominator
        echo "      Result: WAIVED (documented exception)"
        echo "- [~] $step (WAIVED)" >> "$report_file"
        ((TOTAL_GLOBAL_WAIVED++))
        return 3  # Special code: waived (not PASS, not FAIL)
      elif [[ $waiver_code -eq 2 ]]; then
        # Expired waiver — re-enter denominator as FAIL
        echo "      Result: FAIL (EXPIRED WAIVER)"
        echo "- [ ] $step (FAIL) - EXPIRED WAIVER: review_date has passed" >> "$report_file"
        ((TOTAL_GLOBAL_EXPIRED++))
        ((TOTAL_GLOBAL_FAIL++))
        return 1
      else
        # No waiver — genuine FAIL
        echo "      Result: FAIL"
        echo "- [ ] $step (FAIL) - $evidence" >> "$report_file"
        ((TOTAL_GLOBAL_FAIL++))
        return 1
      fi
    fi
  else
    echo "      Result: FAIL (Missing evidence: $step_script)"
    echo "- [ ] $step (FAIL) - No verification script found at $step_script" >> "$report_file"
    ((TOTAL_GLOBAL_FAIL++))
    return 1
  fi
}

run_audit_file() {
  local FEATURE_FILE="$1"
  echo "------------------------------------------------------------"
  echo "FEATURE: $FEATURE_FILE"
  
  local REPORT_FILE="specs/verifications/reports/audit-$(basename "$FEATURE_FILE" .feature)-$(date +%Y%m%d-%H%M%S).md"
  mkdir -p specs/verifications/reports

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
        local step_result
        process_step "$line" "$CURRENT_FEATURE" "$CURRENT_SCENARIO" "$REPORT_FILE"
        step_result=$?
        if [[ $step_result -eq 3 ]]; then
          # Waived — excluded from both pass and fail counts
          :
        elif [[ $step_result -eq 0 ]]; then
          ((TOTAL_PASS++))
          ((TOTAL_GLOBAL_PASS++))
        else
          ((TOTAL_FAIL++))
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
TOTAL_GLOBAL_ALL=$((TOTAL_GLOBAL_PASS + TOTAL_GLOBAL_FAIL))
echo "  TOTAL PASS:   $TOTAL_GLOBAL_PASS"
echo "  TOTAL FAIL:   $TOTAL_GLOBAL_FAIL"
echo "  TOTAL WAIVED: $TOTAL_GLOBAL_WAIVED  (excluded from denominator)"
if [[ $TOTAL_GLOBAL_EXPIRED -gt 0 ]]; then
  echo "  EXPIRED WAIVERS: $TOTAL_GLOBAL_EXPIRED (counted as FAIL)"
fi
if [[ $TOTAL_GLOBAL_ALL -gt 0 ]]; then
  SCORE=$(awk "BEGIN { printf \"%d\", $TOTAL_GLOBAL_PASS * 100 / $TOTAL_GLOBAL_ALL }")
else
  SCORE=0
fi

# ── OKF verification-report (e45s02) ────────────────────────────────────
OKF_DIR="specs/verifications/reports"
mkdir -p "$OKF_DIR"
OKF_FILE="$OKF_DIR/audit-$(date +%Y-%m-%d).okf.md"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
GATE=$(if [[ $SCORE -ge 94 ]]; then echo "pass"; else echo "fail"; fi)

cat > "$OKF_FILE" << OKF_EOF
---
okf_kind: verification-report
okf_version: "0.1"
score: ${SCORE}
gate_status: "${GATE}"
threshold: 94
total_pass: ${TOTAL_GLOBAL_PASS}
total_fail: ${TOTAL_GLOBAL_FAIL}
total_waived: ${TOTAL_GLOBAL_WAIVED}
generated_by: scripts/audit-compliance.sh
generated_at: "${TIMESTAMP}"
git_commit: "${GIT_COMMIT}"
---

# Compliance Audit — $(date +%Y-%m-%d)

**Score:** ${SCORE}% (${TOTAL_GLOBAL_PASS}/${TOTAL_GLOBAL_ALL} passed, ${TOTAL_GLOBAL_WAIVED} waived)
**Gate:** ${GATE} | **Threshold:** 94%

See \`specs/verifications/reports/audit-*.md\` for detailed step-by-step reports.
OKF_EOF

echo "OKF report: $OKF_FILE"

if [[ $TOTAL_GLOBAL_WAIVED -gt 0 ]]; then
  echo "  SCORE: ${SCORE}% (of ${TOTAL_GLOBAL_ALL} unwaived checks, threshold 94%)"
else
  echo "  SCORE: ${SCORE}% (threshold 94%)"
fi
if [[ $SCORE -ge 94 ]]; then
  echo "  GATE: PASS"
  exit 0
else
  echo "  GATE: FAIL (below 94%)"
  exit 1
fi
