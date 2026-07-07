#!/usr/bin/env bash
# story: e45s02
# Gemini LLM judge for audit-compliance.sh

if [ -n "${AUDIT_COMPLIANCE_JUDGE_LOADED:-}" ]; then return 0; fi
AUDIT_COMPLIANCE_JUDGE_LOADED=1

audit_judge_with_gemini() {
  local step="$1" feature_name="$2" scenario_name="$3" evidence="$4" report_file="$5"
  local prompt model_output gemini_cmd exit_code verdict rationale

  echo "    [JUDGE] Sending evidence to Gemini CLI..."

  prompt="You are the Master Test Architect judging a compliance audit.
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

  gemini_cmd="gemini --approval-mode plan"
  [[ -n "$MODEL" ]] && gemini_cmd="$gemini_cmd -m $MODEL"

  model_output=$($gemini_cmd -p "$prompt" 2>&1)
  exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    verdict=$(echo "$model_output" | grep "VERDICT:" | cut -d' ' -f2)
    rationale=$(echo "$model_output" | grep "RATIONALE:" | cut -d' ' -f2-)
    if [[ "$verdict" == "PASS" ]]; then
      echo "      Result: PASS"
      echo "- [x] $step (PASS) - $rationale" >> "$report_file"
      return 0
    fi
    echo "      Result: FAIL"
    echo "- [ ] $step (FAIL) - $rationale" >> "$report_file"
    return 1
  fi

  echo "      Result: ERROR (Gemini CLI failed)"
  echo "- [ ] $step (ERROR) - Gemini CLI exit code $exit_code. Output: $model_output" >> "$report_file"
  return 1
}
