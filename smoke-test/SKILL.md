---
name: smoke-test
description: "Post-deploy health-check against a live URL. Validates HTTP status, response content, and critical endpoints. Runnable standalone OR as the final step of the deploy skill."
model: sonnet
---

# Smoke Test

> **HARD GATE** — Do NOT run smoke-test against a URL that hasn't been deployed yet. Always run `deploy` first, then `smoke-test`.
>
> **HARD GATE** — A failed smoke test means the deployment is broken. Do NOT mark a deploy as successful until all smoke checks pass.

Validate a deployed application is healthy by running a configurable set of HTTP checks against live URLs. Each check asserts:
- HTTP status code (e.g., 200 for success, 404 for expected-not-found)
- Response body content signal (regex or jq expression)
- Response time threshold (optional)

Can be run standalone for quick health checks or chained as the final step of the `deploy` skill.

## Configuration

Smoke checks are defined in `smoke-checks.yaml` at the project root:

See [REFERENCE.md](REFERENCE.md)

Checks can also be specified inline via environment variables or CLI arguments for ad-hoc use.

### Check Schema

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| `name` | Yes | — | Human-readable check name (used in report) |
| `path` | Yes | `/` | URL path relative to base_url |
| `method` | No | `GET` | HTTP method |
| `expected_status` | No | `200` | Expected HTTP status code |
| `content_signal` | No | — | Regex or string to find in response body |
| `max_response_time_ms` | No | — | Fail if response slower than this threshold (ms) |

## Process

### 1. Load smoke checks

See [REFERENCE.md](REFERENCE.md)

### 2. Run each check

For each check in the configuration, perform an HTTP request:

See [REFERENCE.md](REFERENCE.md)

### 3. Assert results

See [REFERENCE.md](REFERENCE.md)

### 4. Generate report

See [REFERENCE.md](REFERENCE.md)

## Integration with deploy skill

The `deploy` skill references `smoke-test` as its final verification step:

```bash
# In deploy workflow — after successful deploy
DEPLOY_URL="$DEPLOY_URL" bash scripts/run-smoke.sh
```
