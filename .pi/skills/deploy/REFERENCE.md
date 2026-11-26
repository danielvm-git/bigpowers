# Deploy — Reference

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `ARTIFACT_DIR` | `dist` | Build output directory |
| `DEPLOY_URL` | *(required)* | Live URL for smoke test |
| `DEPLOY_TIMEOUT` | `300` | Max wait for deploy completion (seconds) |
| `DEPLOY_POLL_INTERVAL` | `30` | Polling interval (seconds) |
| `RETRY_MAX` | `3` | Max deploy retry attempts |
| `BUILD_COMMAND` | *(auto-detect)* | Override build command |


---

## Verification

→ verify: `test -f deploy/SKILL.md && grep -q 'name: deploy' deploy/SKILL.md && echo OK`
→ verify: `grep -qi 'build\|artifact\|deploy\|smoke' deploy/SKILL.md && echo OK`
→ verify: `grep -ci 'package.json\|Cargo.toml\|Makefile\|manifest' deploy/SKILL.md | awk '{if($1>=1) print "OK"; else print "FAIL"}'`
→ verify: `grep -ci 'timeout\|poll\|status\|retry\|backoff' deploy/SKILL.md | awk '{if($1>=2) print "OK"; else print "FAIL"}'`
→ verify: `grep -q 'curl.*DEPLOY_URL\|smoke\|health' deploy/SKILL.md && echo OK`

---

## Reference block 1

```bash
DEPLOY_TIMEOUT="${DEPLOY_TIMEOUT:-300}"   # seconds (default 5 minutes)
DEPLOY_POLL_INTERVAL="${DEPLOY_POLL_INTERVAL:-30}"  # seconds

start_time=$(date +%s)
while true; do
  elapsed=$(( $(date +%s) - start_time ))
  if [ "$elapsed" -ge "$DEPLOY_TIMEOUT" ]; then
    echo "FAIL: deploy status polling timed out after ${DEPLOY_TIMEOUT}s"
    exit 1
  fi
  
  status=$(get_deploy_status)  # platform-specific status check
  if [ "$status" = "ready" ] || [ "$status" = "done" ]; then
    echo "Deploy completed in ${elapsed}s"
    break
  fi
  
  sleep "$DEPLOY_POLL_INTERVAL"
done
```

---

## Reference block 2

```bash
RETRY_MAX="${RETRY_MAX:-3}"
base_delay=2
for attempt in $(seq 1 "$RETRY_MAX"); do
  if deploy_command; then
    break
  fi
  if [ "$attempt" -eq "$RETRY_MAX" ]; then
    echo "FAIL: deploy failed after ${RETRY_MAX} attempts"
    exit 1
  fi
  sleep $(( base_delay * 2 ** (attempt - 1) ))
done
```

---

## Reference block 3

```bash
DEPLOY_URL="${DEPLOY_URL:?DEPLOY_URL must be set}"
if curl -sSf "$DEPLOY_URL" > /dev/null 2>&1; then
  echo "OK: $DEPLOY_URL responds with HTTP 200"
else
  echo "FAIL: $DEPLOY_URL is not responding with HTTP 200"
  exit 1
fi
```