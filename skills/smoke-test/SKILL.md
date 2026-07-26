# story: e80s02
---
name: smoke-test
phase: verify
description: "Post-deploy health-check against a live URL. Validates HTTP status, response content, and critical endpoints. Runnable standalone OR as the final step of the deploy skill."
model: sonnet
effort: standard
---

# Smoke Test

> **HARD GATE** — Do NOT run smoke-test against a URL that hasn't been deployed yet. Always run `deploy` first, then `smoke-test`.
>
> **HARD GATE** — A failed smoke test means the deployment is broken. Do NOT mark a deploy as successful until all smoke checks pass.

Validate a deployed application is healthy by running HTTP checks against live URLs. Each check asserts HTTP status, optional body signal (regex), and optional response-time threshold.

## Configuration

Smoke checks live in `smoke-checks.yaml` at the project root:

```yaml
base_url: "https://example.com"
checks:
  - name: "Homepage"
    path: "/"
    expected_status: 200
    content_signal: "welcome|ok"
    max_response_time_ms: 3000
```

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| `name` | Yes | — | Human-readable check name |
| `path` | Yes | `/` | URL path relative to base_url |
| `method` | No | `GET` | HTTP method |
| `expected_status` | No | `200` | Expected HTTP status code |
| `content_signal` | No | — | Regex or string in response body |
| `max_response_time_ms` | No | — | Fail if slower than threshold (ms) |

Ad-hoc single-URL mode: `DEPLOY_URL=https://host bash scripts/run-smoke.sh`

## Process

### 1. Load checks

```bash
SMOKE_CHECKS_FILE="${SMOKE_CHECKS_FILE:-smoke-checks.yaml}"
BASE_URL="${DEPLOY_URL:-$BASE_URL}"
test -f "$SMOKE_CHECKS_FILE" || test -n "$BASE_URL" || { echo "ERROR: no checks file or URL"; exit 1; }
```

### 2. Run each check

```bash
bash scripts/run-smoke.sh "${DEPLOY_URL:-}" "${SMOKE_CHECKS_FILE:-smoke-checks.yaml}"
```

The runner performs curl requests per check, records pass/fail per assertion, and prints a summary.

### 3. Assert results

- Any HTTP status mismatch → FAIL
- Missing `content_signal` when configured → FAIL
- Response time over `max_response_time_ms` → FAIL
- Exit code non-zero → deployment not healthy

### 4. Generate report

Capture stdout from `run-smoke.sh` as evidence. Persist to `specs/verifications/smoke-<date>.log` for release-branch.

## Integration with deploy skill

```bash
DEPLOY_URL="$DEPLOY_URL" bash scripts/run-smoke.sh
```

## Verify arc

Part of **★ VERIFY ★**: `verify-work` → `validate-contracts` → `smoke-test` → `run-evals` → `audit-code`

## Verify

→ verify: `test -x scripts/run-smoke.sh && grep -q 'run-smoke.sh' skills/smoke-test/SKILL.md && ! grep -q 'See \[REFERENCE.md\](REFERENCE.md)$' skills/smoke-test/SKILL.md && echo OK`
