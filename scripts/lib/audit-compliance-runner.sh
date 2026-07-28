#!/usr/bin/env bash
# story: e45s02
# Feature-file runner for audit-compliance.sh

if [ -n "${AUDIT_COMPLIANCE_RUNNER_LOADED:-}" ]; then return 0; fi
AUDIT_COMPLIANCE_RUNNER_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/audit-compliance-judge.sh"
WAIVER_FILE="specs/verifications/waivers.yaml"
true && source "$(dirname "${BASH_SOURCE[0]}")/waiver-utils.sh"

audit_process_step() {
  local step="$1" feature_name="$2" scenario_name="$3" report_file="$4"
  local sanitized_step step_script evidence exit_code waiver_code

  echo "    [STEP] $step"
  [[ "$DRY_RUN" == "true" ]] && return 0

  sanitized_step=$(echo "$step" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
  step_script="specs/verifications/steps/${sanitized_step}.sh"

  if [[ ! -f "$step_script" ]]; then
    echo "      Result: FAIL (Missing evidence: $step_script)"
    echo "- [ ] $step (FAIL) - No verification script found at $step_script" >> "$report_file"
    ((TOTAL_GLOBAL_FAIL++))
    return 1
  fi

  echo "    [EXEC] Gathering evidence: $step_script"
  evidence=$(bash "$step_script" 2>&1)
  exit_code=$?

  if [[ "$JUDGE" == "gemini" ]]; then
    audit_judge_with_gemini "$step" "$feature_name" "$scenario_name" "$evidence" "$report_file"
    return $?
  fi

  if [[ $exit_code -eq 0 ]]; then
    echo "      Result: PASS"
    echo "- [x] $step (PASS)" >> "$report_file"
    return 0
  fi

  has_waiver "$sanitized_step"
  waiver_code=$?

  if [[ $waiver_code -eq 0 ]]; then
    echo "      Result: WAIVED (documented exception)"
    echo "- [~] $step (WAIVED)" >> "$report_file"
    ((TOTAL_GLOBAL_WAIVED++))
    return 3
  fi
  if [[ $waiver_code -eq 2 ]]; then
    echo "      Result: FAIL (EXPIRED WAIVER)"
    echo "- [ ] $step (FAIL) - EXPIRED WAIVER: review_date has passed" >> "$report_file"
    ((TOTAL_GLOBAL_EXPIRED++))
    ((TOTAL_GLOBAL_FAIL++))
    return 1
  fi

  echo "      Result: FAIL"
  echo "- [ ] $step (FAIL) - $evidence" >> "$report_file"
  ((TOTAL_GLOBAL_FAIL++))
  return 1
}

audit_run_file() {
  local FEATURE_FILE="$1" REPORT_FILE line TOTAL_PASS TOTAL_FAIL step_result
  local CURRENT_FEATURE="" CURRENT_SCENARIO="" IN_SCENARIO=false

  echo "------------------------------------------------------------"
  echo "FEATURE: $FEATURE_FILE"

  REPORT_FILE="specs/verifications/reports/audit-$(basename "$FEATURE_FILE" .feature)-$(date +%Y%m%d-%H%M%S).md"
  mkdir -p specs/verifications/reports

  {
    echo "# Audit Report: $FEATURE_FILE"
    echo "Date: $(date)"
    echo "Mode: Autonomous Verification (Judge: $JUDGE)"
    echo ""
  } > "$REPORT_FILE"

  TOTAL_PASS=0
  TOTAL_FAIL=0

  # `|| [[ -n "$line" ]]` is required: read returns non-zero on a final line
  # with no trailing newline, so without this a feature file not ending in \n
  # silently drops its last step — confirmed on karpathy.feature, whose last
  # line ("And I should push back on unnecessary complexity") never appeared
  # in [STEP] output at all.
  while IFS= read -r line || [[ -n "$line" ]]; do
    line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [[ "$line" =~ ^Feature: ]]; then
      CURRENT_FEATURE="${line#Feature: }"
      echo "FEATURE: $CURRENT_FEATURE"
      echo "## Feature: $CURRENT_FEATURE" >> "$REPORT_FILE"
    elif [[ "$line" =~ ^Background: ]]; then
      # A Background's Given/And lines must execute the same as a Scenario's —
      # without this branch IN_SCENARIO never goes true here, so every step
      # under Background is silently skipped (not FAILed, not counted at all).
      # Runs once per file, matching how every other line here executes once
      # as encountered — not true per-scenario Gherkin re-execution semantics.
      IN_SCENARIO=true
      CURRENT_SCENARIO="Background"
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
      [[ "$IN_SCENARIO" != "true" ]] && continue
      audit_process_step "$line" "$CURRENT_FEATURE" "$CURRENT_SCENARIO" "$REPORT_FILE"
      step_result=$?
      if [[ $step_result -eq 3 ]]; then
        :
      elif [[ $step_result -eq 0 ]]; then
        ((TOTAL_PASS++))
        ((TOTAL_GLOBAL_PASS++))
      else
        ((TOTAL_FAIL++))
      fi
    fi
  done < "$FEATURE_FILE"

  echo ""
  echo "File Summary: PASS: $TOTAL_PASS, FAIL: $TOTAL_FAIL"
  echo "Report saved to: $REPORT_FILE"
}
