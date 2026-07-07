#!/usr/bin/env bash
# story: e31s04 e45s02
# Golden suite reporting — verdict, YAML/OKF output, size budget

if [ -n "${GOLDEN_REPORT_LOADED:-}" ]; then return 0; fi
GOLDEN_REPORT_LOADED=1

golden_compute_verdict() {
  TOTAL=$((PASS_COUNT + FAIL_COUNT + SKIP_COUNT))
  AGENT_TOTAL=$((AGENT_PASS + AGENT_FAIL + AGENT_SKIP))
  if [[ "$FAIL_COUNT" -gt 0 || "$AGENT_FAIL" -gt 0 ]]; then OVERALL="fail"; else OVERALL="pass"; fi
}

golden_print_verdict() {
  golden_compute_verdict
  echo ""
  echo "══════════════════════════════════════════"
  echo "           GOLDEN SUITE VERDICT"
  echo "══════════════════════════════════════════"
  echo ""
  echo "Deterministic gates:"
  echo -e "  ${PASS_COUNT}/${TOTAL} passed"
  [[ "$SKIP_COUNT" -gt 0 ]] && echo -e "  ${SKIP_COUNT} skipped"
  [[ "$FAIL_COUNT" -gt 0 ]] && echo -e "  ${GOLDEN_RED}${FAIL_COUNT} failed${GOLDEN_NC}"

  if $AGENT_MODE; then
    echo ""
    echo "Agent-driven stories:"
    echo -e "  ${AGENT_PASS}/${AGENT_TOTAL} passed"
    [[ "$AGENT_FAIL" -gt 0 ]] && echo -e "  ${GOLDEN_RED}${AGENT_FAIL} failed${GOLDEN_NC}"
    [[ "$AGENT_SKIP" -gt 0 ]] && echo -e "  ${AGENT_SKIP} skipped"
    [[ "$AGENT_FLAKE" -gt 0 ]] && echo -e "  ${GOLDEN_YELLOW}${AGENT_FLAKE} flake(s) detected${GOLDEN_NC} (absorbed by pass@k 2-of-3)"
  fi

  echo ""
  echo -e "Combined verdict: $([[ "$OVERALL" == "pass" ]] && echo -e "${GOLDEN_GREEN}PASS${GOLDEN_NC}" || echo -e "${GOLDEN_RED}FAIL${GOLDEN_NC}")"
  echo "Report: $REPORT_FILE"
  echo "══════════════════════════════════════════"
}

golden_write_reports() {
  local PASS_RATE AGENT_PASS_RATE OKF_DIR OKF_FILE THRESHOLD GATE_STATUS mode

  PASS_RATE=$(echo "scale=2; $PASS_COUNT / $TOTAL" | bc 2>/dev/null || echo "0")
  AGENT_PASS_RATE="n/a"
  [[ "$AGENT_TOTAL" -gt 0 ]] && AGENT_PASS_RATE=$(echo "scale=2; $AGENT_PASS / $AGENT_TOTAL" | bc 2>/dev/null || echo "0")
  mode=$([ "$BASELINE_MODE" = true ] && echo 'baseline' || echo 'daily')

  cat > "$REPORT_FILE" << YAML_EOF
timestamp: "$TIMESTAMP"
git_commit: "$GIT_COMMIT"
suite: "golden-combined"
mode: "$mode"
deterministic:
  total: $TOTAL
  passed: $PASS_COUNT
  failed: $FAIL_COUNT
  skipped: $SKIP_COUNT
  pass_rate: $PASS_RATE
gates:
$(printf '%s\n' "${GATE_RESULTS[@]}")
agent_stories:
  total: $AGENT_TOTAL
  passed: $AGENT_PASS
  failed: $AGENT_FAIL
  skipped: $AGENT_SKIP
  flake_count: $AGENT_FLAKE
  pass_rate: $AGENT_PASS_RATE
summary:
  combined_verdict: "$OVERALL"
YAML_EOF

  OKF_DIR="specs/verifications/reports"
  mkdir -p "$OKF_DIR"
  OKF_FILE="$OKF_DIR/GOLDEN-${TODAY}.okf.md"
  THRESHOLD=100
  GATE_STATUS="$OVERALL"

  cat > "$OKF_FILE" << OKF_EOF
---
okf_kind: verification-report
okf_version: "0.1"
type: VerificationReport
score: ${PASS_RATE}
gate_status: "${GATE_STATUS}"
threshold: ${THRESHOLD}
total_pass: ${PASS_COUNT}
total_fail: ${FAIL_COUNT}
total_skip: ${SKIP_COUNT}
generated_by: ${GOLDEN_GENERATED_BY}
generated_at: "${TIMESTAMP}"
git_commit: "${GIT_COMMIT}"
---

# Golden Suite — ${TODAY}

**Score:** ${PASS_RATE} (${PASS_COUNT}/${TOTAL} passed)
**Gate:** ${GATE_STATUS} | **Threshold:** ${THRESHOLD}%

See \`${REPORT_FILE}\` for the full YAML report.
OKF_EOF

  echo "OKF report: $OKF_FILE"
}

golden_write_baseline_sizes() {
  local skill_md skill_name skill_bytes
  echo "" >> "$REPORT_FILE"
  echo "# Skill byte counts (baseline for e31s04 size budget)" >> "$REPORT_FILE"
  echo "skill_sizes:" >> "$REPORT_FILE"
  for skill_md in skills/*/SKILL.md; do
    skill_name=$(basename "$(dirname "$skill_md")")
    skill_bytes=$(wc -c < "$skill_md" | tr -d ' ')
    echo "  $skill_name: $skill_bytes" >> "$REPORT_FILE"
  done
  echo "Baseline pinned: $REPORT_FILE"
}

golden_check_size_budget() {
  local WARN_THRESHOLD=20 FAIL_THRESHOLD=50 skill_md skill_name current_bytes baseline_bytes pct
  local SIZE_WARNINGS=0 SIZE_FAILURES=0 NEW_SKILLS=0

  if [[ ! -f "$BASELINE_FILE" ]]; then
    echo "No baseline found. Run --baseline first."
    return 1
  fi

  echo ""
  echo "Size Budget Check (+${WARN_THRESHOLD}% warn, +${FAIL_THRESHOLD}% fail):"
  for skill_md in skills/*/SKILL.md; do
    skill_name=$(basename "$(dirname "$skill_md")")
    current_bytes=$(wc -c < "$skill_md" | tr -d ' ')
    baseline_bytes=$(grep "^  $skill_name:" "$BASELINE_FILE" 2>/dev/null | awk '{print $2}')

    if [[ -z "$baseline_bytes" ]]; then
      echo -e "  ${GOLDEN_YELLOW}NEW${GOLDEN_NC}  $skill_name: ${current_bytes}b (not in baseline)"
      (( NEW_SKILLS += 1 )) || true
      continue
    fi
    [[ "$baseline_bytes" -eq 0 ]] && baseline_bytes=1
    pct=$(( (current_bytes - baseline_bytes) * 100 / baseline_bytes ))

    if [[ "$pct" -ge "$FAIL_THRESHOLD" ]]; then
      echo -e "  ${GOLDEN_RED}FAIL${GOLDEN_NC} $skill_name: ${current_bytes}b (+${pct}%)"
      (( SIZE_FAILURES += 1 )) || true
    elif [[ "$pct" -ge "$WARN_THRESHOLD" ]]; then
      echo -e "  ${GOLDEN_YELLOW}WARN${GOLDEN_NC} $skill_name: ${current_bytes}b (+${pct}%)"
      (( SIZE_WARNINGS += 1 )) || true
    else
      echo -e "  ${GOLDEN_GREEN}OK${GOLDEN_NC}   $skill_name: ${current_bytes}b"
    fi
  done

  echo ""
  echo "Size summary: $SIZE_WARNINGS warnings, $SIZE_FAILURES failures, $NEW_SKILLS new"
  [[ "$SIZE_FAILURES" -gt 0 ]] && return 1
  return 0
}
