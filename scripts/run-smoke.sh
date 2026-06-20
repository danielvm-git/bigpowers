#!/usr/bin/env bash
# run-smoke.sh — Post-deploy health-check runner for smoke-test skill
# Usage: bash scripts/run-smoke.sh [url] [smoke-checks-file]
#
# Reads from smoke-checks.yaml by default. Falls back to single-URL check.
# Env vars: DEPLOY_URL, SMOKE_CHECKS_FILE, SMOKE_TIMEOUT, SMOKE_RETRIES
set -euo pipefail

SMOKE_CHECKS_FILE="${2:-${SMOKE_CHECKS_FILE:-smoke-checks.yaml}}"
BASE_URL="${1:-${DEPLOY_URL:-}}"
SMOKE_TIMEOUT="${SMOKE_TIMEOUT:-30}"
SMOKE_RETRIES="${SMOKE_RETRIES:-0}"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

checks_passed=0
checks_failed=0
failures=""

# ── 1. Load checks ──────────────────────────────────────────────────────────

run_single_url_check() {
  local url="$1"
  local name="${2:-URL check}"
  local expected_status="${3:-200}"
  local content_signal="${4:-}"

  echo "[$name]"
  start_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  response=$(curl -s -o "$TMPDIR/body.txt" -w "%{http_code}" --max-time "$SMOKE_TIMEOUT" "$url")
  response_time=$(( $(python3 -c 'import time; print(int(time.time() * 1000))') - start_time ))
  status="$response"
  body=$(cat "$TMPDIR/body.txt" 2>/dev/null || echo "")

  # Assert status
  if [ "$status" -ne "$expected_status" ]; then
    echo "  FAIL: HTTP $status (expected $expected_status)"
    checks_failed=$((checks_failed + 1))
    failures="${failures}  - $name: HTTP $status (expected $expected_status)\n"
  else
    echo "  PASS: HTTP $status"
    checks_passed=$((checks_passed + 1))
  fi

  # Assert content signal
  if [ -n "$content_signal" ]; then
    if echo "$body" | grep -qiE "$content_signal"; then
      echo "  PASS: body matches \"$content_signal\""
    else
      echo "  FAIL: body does not match \"$content_signal\""
      checks_failed=$((checks_failed + 1))
      failures="${failures}  - $name: missing content signal \"$content_signal\"\n"
    fi
  fi

  # Assert response time
  if [ "$response_time" -gt 0 ]; then
    echo "  Time: ${response_time}ms"
  fi
  echo ""
}

parse_and_run_checks() {
  local file="$1"
  local base_url=""
  local in_checks=false
  local check_name="" check_path="" check_method="" check_status="" check_signal="" check_time=""

  while IFS= read -r line; do
    # Strip inline comments
    line="${line%%#*}"
    # Trim whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [ -z "$line" ] && continue

    if [[ "$line" =~ ^base_url: ]]; then
      base_url="${line#base_url:}"
      base_url="${base_url#"${base_url%%[![:space:]]*}"}"
      base_url="${base_url%"${base_url##*[![:space:]]}"}"
      base_url="${base_url%\"}"
      base_url="${base_url#\"}"
      base_url="${base_url%\'}"
      base_url="${base_url#\'}"
      continue
    fi

    if [[ "$line" == "checks:" ]]; then
      in_checks=true
      check_name=""; check_path=""; check_method="GET"; check_status="200"
      check_signal=""; check_time=""
      continue
    fi

    if $in_checks; then
      # Detect new check entry (dash at start of list item)
      if [[ "$line" == "- name:"* ]]; then
        # Run previous check if accumulated
        if [ -n "$check_name" ] && [ -n "$base_url" ]; then
          run_parsed_check "$base_url" "$check_name" "$check_path" "$check_status" "$check_signal"
        fi
        check_name="${line#- name:}"
        check_name="${check_name#"${check_name%%[![:space:]]*}"}"
        check_name="${check_name%\"}"; check_name="${check_name#\"}"
        check_name="${check_name%\'}"; check_name="${check_name#\'}"
        check_path=""; check_method="GET"; check_status="200"; check_signal=""; check_time=""
      elif [[ "$line" == "name:"* ]]; then
        check_name="${line#name:}"
        check_name="${check_name#"${check_name%%[![:space:]]*}"}"
        check_name="${check_name%\"}"; check_name="${check_name#\"}"
        check_name="${check_name%\'}"; check_name="${check_name#\'}"
      elif [[ "$line" == "path:"* ]]; then
        check_path="${line#path:}"
        check_path="${check_path#"${check_path%%[![:space:]]*}"}"
        check_path="${check_path%\"}"; check_path="${check_path#\"}"
        check_path="${check_path%\'}"; check_path="${check_path#\'}"
      elif [[ "$line" == "method:"* ]]; then
        check_method="${line#method:}"
        check_method="${check_method#"${check_method%%[![:space:]]*}"}"
        check_method="${check_method%\"}"; check_method="${check_method#\"}"
        check_method="${check_method%\'}"; check_method="${check_method#\'}"
      elif [[ "$line" == "expected_status:"* ]]; then
        check_status="${line#expected_status:}"
        check_status="${check_status#"${check_status%%[![:space:]]*}"}"
      elif [[ "$line" == "content_signal:"* ]]; then
        check_signal="${line#content_signal:}"
        check_signal="${check_signal#"${check_signal%%[![:space:]]*}"}"
        check_signal="${check_signal%\"}"; check_signal="${check_signal#\"}"
        check_signal="${check_signal%\'}"; check_signal="${check_signal#\'}"
      elif [[ "$line" == "max_response_time_ms:"* ]]; then
        check_time="${line#max_response_time_ms:}"
        check_time="${check_time#"${check_time%%[![:space:]]*}"}"
      fi
    fi
  done < "$file"

  # Run last check
  if [ -n "$check_name" ] && [ -n "$base_url" ]; then
    run_parsed_check "$base_url" "$check_name" "$check_path" "$check_status" "$check_signal"
  fi
}

run_parsed_check() {
  local base_url="$1" name="$2" path="$3" expected_status="$4" content_signal="$5"
  local url="${base_url}${path}"

  echo "[$name]"
  echo "  URL: $url"
  start_time=$(python3 -c 'import time; print(int(time.time() * 1000))')
  response=$(curl -s -o "$TMPDIR/body.txt" -w "%{http_code}" --max-time "$SMOKE_TIMEOUT" "$url" 2>/dev/null || echo "000")
  response_time=$(( $(python3 -c 'import time; print(int(time.time() * 1000))') - start_time ))
  status="$response"
  body=$(cat "$TMPDIR/body.txt" 2>/dev/null || echo "")

  # Assert status code
  if [ "$status" -ne "$expected_status" ]; then
    echo "  FAIL: HTTP $status (expected $expected_status)"
    checks_failed=$((checks_failed + 1))
    failures="${failures}  - $name: HTTP $status (expected $expected_status)\n"
  else
    echo "  PASS: HTTP $status"
  fi

  # Assert content signal
  if [ -n "$content_signal" ]; then
    if echo "$body" | grep -qiE "$content_signal"; then
      echo "  PASS: body matches \"$content_signal\""
      checks_passed=$((checks_passed + 1))
    else
      echo "  FAIL: body does not match \"$content_signal\""
      checks_failed=$((checks_failed + 1))
      failures="${failures}  - $name: missing content signal \"$content_signal\"\n"
    fi
  fi

  # Assert response time
  if [ -n "${check_time:-}" ] && [ "$check_time" -gt 0 ] 2>/dev/null; then
    if [ "$response_time" -gt "$check_time" ]; then
      echo "  FAIL: ${response_time}ms exceeds ${check_time}ms max"
      checks_failed=$((checks_failed + 1))
      failures="${failures}  - $name: response time ${response_time}ms (max ${check_time}ms)\n"
    else
      echo "  PASS: ${response_time}ms within ${check_time}ms limit"
    fi
  fi

  if [ "$response_time" -gt 0 ]; then
    echo "  Time: ${response_time}ms"
  fi
  echo ""
}

# ── Main dispatch ───────────────────────────────────────────────────────────

echo "=== Smoke Test Runner ==="
echo "Started at: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo ""

if [ -f "$SMOKE_CHECKS_FILE" ]; then
  echo "Checks file: $SMOKE_CHECKS_FILE"
  parse_and_run_checks "$SMOKE_CHECKS_FILE"
elif [ -n "$BASE_URL" ]; then
  echo "Single URL mode: $BASE_URL"
  run_single_url_check "$BASE_URL" "Baseline"
else
  echo "ERROR: No smoke-checks.yaml found and no URL provided."
  echo "Usage: bash scripts/run-smoke.sh [url] [smoke-checks-file]"
  echo "       DEPLOY_URL=http://example.com bash scripts/run-smoke.sh"
  exit 2
fi

# ── Summary ──────────────────────────────────────────────────────────────────

total=$((checks_passed + checks_failed))
echo "=== Smoke Test Summary ==="
echo "Total: $total | Passed: $checks_passed | Failed: $checks_failed"
echo ""

if [ "$checks_failed" -gt 0 ]; then
  echo "Failures:"
  echo -e "$failures"
  echo "Smoke test FAILED."
  exit 1
fi

if [ "$total" -eq 0 ]; then
  echo "No checks were executed."
  exit 1
fi

echo "All checks passed."
exit 0
