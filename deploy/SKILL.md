---
name: deploy
description: "Build → verify artifact → deploy → wait → smoke deployment pipeline. Platform-agnostic (MCP or CLI), with configurable timeout, retry with exponential backoff, and integrated health-check. The deploy half of CI/CD: run after build to push to production."
model: sonnet
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

See [REFERENCE.md](REFERENCE.md)

Use exponential backoff for retries on transient failures:

See [REFERENCE.md](REFERENCE.md)

### 6. Baseline smoke test

See [REFERENCE.md](REFERENCE.md)

For comprehensive health-checking, chain to the `smoke-test` skill:

```bash
# After deploy success
bash scripts/run-smoke.sh "$DEPLOY_URL"
```
