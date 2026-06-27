# Smoke Test — Reference

## Runner script

A ready-to-use runner is provided for standalone operation:

```bash
bash scripts/run-smoke.sh [url] [smoke-checks-file]
```

The runner:
1. Uses `$DEPLOY_URL`, `$SMOKE_CHECKS_FILE`, or CLI arguments
2. Runs all defined checks
3. Prints a pass/fail summary
4. Exits 0 on all pass, non-zero on any failure


---

## Configuration reference

| Variable | Default | Description |
|----------|---------|-------------|
| `SMOKE_CHECKS_FILE` | `smoke-checks.yaml` | Path to smoke checks YAML |
| `DEPLOY_URL` / `BASE_URL` | *(required)* | Base URL for all checks |
| `SMOKE_TIMEOUT` | `30` | Per-check timeout (seconds) |
| `SMOKE_RETRIES` | `0` | Number of retries on failure |


---

## Verification

→ verify: `test -f smoke-test/SKILL.md && grep -q 'name: smoke-test' smoke-test/SKILL.md && echo OK`
→ verify: `grep -qi 'smoke.checks.yaml\|checklist\|expected_status\|content_signal' smoke-test/SKILL.md && echo OK`
→ verify: `grep -ci 'pass\|fail\|summary\|report' smoke-test/SKILL.md | awk '{if($1>=2) print "OK"; else print "FAIL"}'`
→ verify: `grep -q 'smoke-test' SKILL-INDEX.md && echo OK`

---

## Reference block 1

```yaml
# smoke-checks.yaml — auto-loaded if present at project root
base_url: "https://example.com"
checks:
  - name: "Homepage"
    path: "/"
    method: GET
    expected_status: 200
    content_signal: "bigpowers"
    max_response_time_ms: 3000

  - name: "API Health"
    path: "/api/health"
    method: GET
    expected_status: 200
    content_signal: "ok|healthy"

  - name: "API Jogos"
    path: "/api/jogos"
    method: GET
    expected_status: 200
    content_signal: "jogos|games"

  - name: "Not Found handling"
    path: "/nonexistent"
    method: GET
    expected_status: 404
    content_signal: "not found|404"
```

---

## Reference block 2

```bash
SMOKE_CHECKS_FILE="${SMOKE_CHECKS_FILE:-smoke-checks.yaml}"
BASE_URL="${DEPLOY_URL:-$BASE_URL}"

if [ -f "$SMOKE_CHECKS_FILE" ]; then
  echo "Loaded smoke checks from $SMOKE_CHECKS_FILE"
elif [ -n "$BASE_URL" ]; then
  echo "No smoke-checks.yaml found. Using single URL check against $BASE_URL"
else
  echo "ERROR: No smoke-checks.yaml found and no DEPLOY_URL/BASE_URL set."
  exit 1
fi
```

---

## Reference block 3

```bash
url="${BASE_URL}${path}"
start_time=$(python3 -c 'import time; print(int(time.time() * 1000))')

# Perform the HTTP request
response=$(curl -s -o /tmp/smoke_body.txt -w "%{http_code}" "$url")
response_time=$(( $(python3 -c 'import time; print(int(time.time() * 1000))') - start_time ))
status=$response
body=$(cat /tmp/smoke_body.txt)
```

---

## Reference block 4

```bash
checks_passed=0
checks_failed=0
failures=""

# Assert status code
if [ "$status" -ne "${expected_status:-200}" ]; then
  echo "  FAIL: expected status ${expected_status} but got $status"
  checks_failed=$((checks_failed + 1))
  failures="${failures}  - $name: HTTP $status (expected ${expected_status})\n"
else
  echo "  PASS: HTTP $status"
fi

# Assert content signal
if [ -n "$content_signal" ]; then
  if echo "$body" | grep -qiE "$content_signal"; then
    echo "  PASS: body contains \"$content_signal\""
  else
    echo "  FAIL: body does not contain \"$content_signal\""
    checks_failed=$((checks_failed + 1))
    failures="${failures}  - $name: missing content signal \"$content_signal\"\n"
  fi
fi

# Assert response time
if [ -n "$max_response_time_ms" ] && [ "$response_time" -gt "$max_response_time_ms" ]; then
  echo "  FAIL: response time ${response_time}ms exceeds ${max_response_time_ms}ms"
  checks_failed=$((checks_failed + 1))
  failures="${failures}  - $name: response time ${response_time}ms (max ${max_response_time_ms}ms)\n"
fi
```

---

## Reference block 5

```bash
total=$((checks_passed + checks_failed))
echo ""
echo "=== Smoke Test Summary ==="
echo "Total: $total | Passed: $checks_passed | Failed: $checks_failed"

if [ "$checks_failed" -gt 0 ]; then
  echo ""
  echo "Failures:"
  echo -e "$failures"
  exit 1
else
  echo "All checks passed."
  exit 0
fi
```