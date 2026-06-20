---
description: "Build → verify artifact → deploy → wait → smoke deployment pipeline. Platform-agnostic (MCP or CLI), with configurable timeout, retry with exponential backoff, and integrated health-check. The deploy half of CI/CD: run after build to push to production."
---


# Deploy

> **HARD GATE** — Do not deploy without running tests first. Run `test` or your CI suite before this skill.
>
> **HARD GATE** — Use this skill from a CI/CD pipeline or post-merge on `main`/`master`. Never deploy from a feature branch.
>
> **HARD GATE** — The deploy skill orchestrates deployment; the `smoke-test` skill validates post-deploy health. Chain them: `deploy → smoke-test`.

Orchestrate a full build-to-deployment pipeline: build the artifact, verify it exists and is non-empty, invoke a platform deploy tool (MCP or CLI), poll until the deploy completes or times out, then run a baseline smoke test against the live URL.

## Pipeline Stages

```
build → verify artifact → deploy → wait/retry → smoke
```

| Stage | Description | Failure mode |
|-------|-------------|-------------|
| Build | Execute the project's build command | Non-zero exit: report build error |
| Verify | Check artifact exists and is non-empty | Missing/empty: report artifact path |
| Deploy | Invoke platform deploy tool (MCP, Vercel CLI, rsync, etc.) | Non-zero exit: report deploy error |
| Wait | Poll deploy status every 30s up to `DEPLOY_TIMEOUT` (default 5 min) | Timeout: report exceeded |
| Smoke | `curl -sSf $DEPLOY_URL` as baseline health check | Non-200: report failure |

## Process

### 1. Detect build command

Read project manifest files in order to determine the build command:

| Manifest | Build command |
|----------|--------------|
| `package.json` | `npm run build` (or `scripts.build` value) |
| `Cargo.toml` | `cargo build --release` |
| `pyproject.toml` / `setup.py` | Depends on build backend (`poetry build`, `pip install -e .`, etc.) |
| `Makefile` | `make build` or first target named `build` |
| `AGENTS.md` / `CLAUDE.md` | Look for `build:` in project commands section |

If no manifest is found, prompt the user with: "No detected build command. Pass `--build 'npm run build'` or specify the command."

### 2. Build the artifact

```bash
npm run build
```

Or the detected command from step 1. If the build fails, exit non-zero and report the build output.

### 3. Verify the artifact

```bash
ARTIFACT_DIR="${ARTIFACT_DIR:-dist}"
if [ ! -d "$ARTIFACT_DIR" ] || [ -z "$(ls -A "$ARTIFACT_DIR" 2>/dev/null)" ]; then
  echo "FAIL: build artifact not found at $ARTIFACT_DIR"
  exit 1
fi
```

Configurable via `$ARTIFACT_DIR` environment variable (default: `dist/`).

### 4. Deploy to platform

Platform-agnostic — supports multiple deployment targets via environment variables:

| Platform | Env var | Example |
|----------|---------|---------|
| Vercel | `VERCEL_TOKEN`, `VERCEL_PROJECT_ID` | `vercel deploy --prod --token $VERCEL_TOKEN` |
| Netlify | `NETLIFY_AUTH_TOKEN`, `NETLIFY_SITE_ID` | `netlify deploy --prod --auth $NETLIFY_AUTH_TOKEN --dir $ARTIFACT_DIR` |
| BigBase MCP | MCP tool call | `mcp deploy` via BigBase server |
| rsync/SSH | `DEPLOY_SSH_USER`, `DEPLOY_SSH_HOST`, `DEPLOY_SSH_PATH` | `rsync -avz $ARTIFACT_DIR/ $DEPLOY_SSH_USER@$DEPLOY_SSH_HOST:$DEPLOY_SSH_PATH` |
| Custom | `DEPLOY_COMMAND` | Run any deploy command string |

The deploy tool is selected by which environment variables are set. If none are configured:

```bash
echo "No deploy target configured. Set one of: VERCEL_TOKEN, NETLIFY_AUTH_TOKEN, DEPLOY_SSH_USER+DEPLOY_SSH_HOST, DEPLOY_COMMAND, or MCP deploy tool."
exit 1
```

### 5. Wait and poll status

After invoking the deploy command, poll for completion:

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

Use exponential backoff for retries on transient failures:

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

### 6. Baseline smoke test

```bash
DEPLOY_URL="${DEPLOY_URL:?DEPLOY_URL must be set}"
if curl -sSf "$DEPLOY_URL" > /dev/null 2>&1; then
  echo "OK: $DEPLOY_URL responds with HTTP 200"
else
  echo "FAIL: $DEPLOY_URL is not responding with HTTP 200"
  exit 1
fi
```

For comprehensive health-checking, chain to the `smoke-test` skill:

```bash
# After deploy success
bash scripts/run-smoke.sh "$DEPLOY_URL"
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `ARTIFACT_DIR` | `dist` | Build output directory |
| `DEPLOY_URL` | *(required)* | Live URL for smoke test |
| `DEPLOY_TIMEOUT` | `300` | Max wait for deploy completion (seconds) |
| `DEPLOY_POLL_INTERVAL` | `30` | Polling interval (seconds) |
| `RETRY_MAX` | `3` | Max deploy retry attempts |
| `BUILD_COMMAND` | *(auto-detect)* | Override build command |

## Verification

→ verify: `test -f deploy/SKILL.md && grep -q 'name: deploy' deploy/SKILL.md && echo OK`
→ verify: `grep -qi 'build\|artifact\|deploy\|smoke' deploy/SKILL.md && echo OK`
→ verify: `grep -ci 'package.json\|Cargo.toml\|Makefile\|manifest' deploy/SKILL.md | awk '{if($1>=1) print "OK"; else print "FAIL"}'`
→ verify: `grep -ci 'timeout\|poll\|status\|retry\|backoff' deploy/SKILL.md | awk '{if($1>=2) print "OK"; else print "FAIL"}'`
→ verify: `grep -q 'curl.*DEPLOY_URL\|smoke\|health' deploy/SKILL.md && echo OK`
