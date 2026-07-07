#!/usr/bin/env bash
# story: e45s02
# OKF report and gate verdict for audit-compliance.sh

if [ -n "${AUDIT_COMPLIANCE_REPORT_LOADED:-}" ]; then return 0; fi
AUDIT_COMPLIANCE_REPORT_LOADED=1

audit_write_okf_report() {
  local OKF_DIR OKF_FILE TIMESTAMP GIT_COMMIT GATE TOTAL_GLOBAL_ALL

  TOTAL_GLOBAL_ALL=$((TOTAL_GLOBAL_PASS + TOTAL_GLOBAL_FAIL))
  if [[ $TOTAL_GLOBAL_ALL -gt 0 ]]; then
    SCORE=$(awk "BEGIN { printf \"%d\", $TOTAL_GLOBAL_PASS * 100 / $TOTAL_GLOBAL_ALL }")
  else
    SCORE=0
  fi

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
}

audit_print_summary_and_exit() {
  local TOTAL_GLOBAL_ALL=$((TOTAL_GLOBAL_PASS + TOTAL_GLOBAL_FAIL))

  echo "============================================================"
  echo "Global Audit Summary:"
  echo "  TOTAL PASS:   $TOTAL_GLOBAL_PASS"
  echo "  TOTAL FAIL:   $TOTAL_GLOBAL_FAIL"
  echo "  TOTAL WAIVED: $TOTAL_GLOBAL_WAIVED  (excluded from denominator)"
  [[ $TOTAL_GLOBAL_EXPIRED -gt 0 ]] && echo "  EXPIRED WAIVERS: $TOTAL_GLOBAL_EXPIRED (counted as FAIL)"

  audit_write_okf_report

  if [[ $TOTAL_GLOBAL_WAIVED -gt 0 ]]; then
    echo "  SCORE: ${SCORE}% (of ${TOTAL_GLOBAL_ALL} unwaived checks, threshold 94%)"
  else
    echo "  SCORE: ${SCORE}% (threshold 94%)"
  fi

  if [[ $SCORE -ge 94 ]]; then
    echo "  GATE: PASS"
    exit 0
  fi
  echo "  GATE: FAIL (below 94%)"
  exit 1
}
