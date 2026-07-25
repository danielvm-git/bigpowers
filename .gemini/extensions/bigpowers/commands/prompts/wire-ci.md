---
name: wire-ci
description: "CI pipeline setup with pre-built templates and local validation. Generates GitHub Actions workflows, validates YAML syntax and permissions, supports dry-run via act/gh. The CI equivalent of wire-observability."
---

# Wire CI

> **HARD GATE** — Do not ship a project without CI. Run this skill before first merge to main or when adding CI to an existing project.
>
> **HARD GATE** — CI that is untestable locally will break every cycle. Always run `--validate` after generating workflows and `--dry-run` before pushing.

Generate, validate, and test CI workflows. Detects your project type, copies org templates from `danielvm-git/.github/workflow-templates/`, and provides local verification to catch auth, permissions, and syntax issues before they reach CI.

## What this sets up

1. **Test Build Release workflow** — `.github/workflows/test-build-release.yml` with lint → test → build → release (single pipeline, `needs:` chain)
2. **Deploy workflow** — `.github/workflows/deploy.yml` triggered via `workflow_run` (BigBase/Pages stacks only; CLI/library repos omit this)
3. **`--validate` mode** — checks YAML syntax, workflow permissions, required secrets, and common pitfalls
4. **`--dry-run` mode** — runs workflows locally via `act` or `gh workflow run` to prove correctness before push
5. **Failure pattern documentation** — common CI failure categories and their fixes

## Process

### 1. Detect project type

Read the project root for manifest files to determine which template pair to copy:

| Manifest | Type | Template pair (from `.github` repo) |
|----------|------|-------------------------------------|
| `Cargo.toml` | Rust | `test-build-release-monorepo.yml` + `deploy-monorepo.yml` (or monorepo subset) |
| `package.json` | Node | `test-build-release-node.yml` + `deploy-node.yml` |
| `setup.py` / `pyproject.toml` | Python | `test-build-release-python.yml` + `deploy-python.yml` |
| `go.mod` | Go | `test-build-release-go.yml` + `deploy-go.yml` |
| Static site (no server) | Static | `test-build-release-static.yml` + `deploy-static.yml` |
| `Package.swift` | Swift | `test-build-release-swift.yml` only (no deploy yet) |
| Multiple detected | Polyglot | `test-build-release-monorepo.yml` + `deploy-monorepo.yml` |

**CLI/library repos** (no hosted target): copy only `test-build-release-<stack>.yml` → `test-build-release.yml`. The `release` job is terminal; skip `deploy.yml`. See `docs/how-to/migrate-ci-cd/migration-plan.md` § CLI and library repos.

If no manifest is found, prompt the user to specify the type or pass `--type <rust|node|python|go|static|swift>`.

### 2. Copy test-build-release template

Copy the matching template from `~/Developer/.github/workflow-templates/` to `.github/workflows/test-build-release.yml`. **Do not rename the workflow `name:` field** — deploy listens for `"Test Build Release"`.

Edit placeholders: `APP_TYPE`, `SITE_URL`, language versions.

See [REFERENCE.md](REFERENCE.md) for stack-specific job shapes.

### 3. Copy deploy template (hosted stacks only)

If the project deploys to BigBase or GitHub Pages:

```bash
cp ~/Developer/.github/workflow-templates/deploy-${STACK}.yml .github/workflows/deploy.yml
```

Configure `BIGBASE_SITE_ID`, `BIGBASE_DEPLOY_TOKEN`, and matching `SITE_URL`. Deploy runs via `workflow_run` after TBR succeeds on `main` with `cancel-in-progress: false`.

Skip this step for CLI/library repos.

### 4. Validate workflows (`--validate`)

Run `wire-ci --validate` to check all generated workflow files:

See [REFERENCE.md](REFERENCE.md)

**Exit codes:**
- `0` — all checks pass (no errors)
- `1` — YAML syntax errors found
- `2` — validation warnings only (missing permissions, secrets, etc.)

### 5. Dry-run workflows (`--dry-run`)

Attempt to run the generated workflows locally to catch errors before push:

See [REFERENCE.md](REFERENCE.md)

> **act** runs workflows in a local Docker environment — the most accurate pre-push validation.
> **gh workflow run** sends the workflow to GitHub but doesn't execute locally — useful for checking YAML parsing but not for testing the actual steps.

### 6. Document common CI failure patterns

Add the following to the project's documentation or CLAUDE.md after setup:

| Failure | Cause | Fix |
|---------|-------|-----|
| `npm publish` fails | `NPM_TOKEN` not set as repo secret | Add `NPM_TOKEN` to GitHub repo secrets |
| `semantic-release` fails on push | Missing `permissions: contents: write` | Add `permissions: contents: write` to release job |
| `cargo publish` auth fail | `CARGO_REGISTRY_TOKEN` not set | Add token to `~/.cargo/config.toml` or env |
| `go vet` fails | Go version mismatch | Match `go.mod` `go` directive with setup-go version |
| `cargo clippy` errors | New lints in Rust nightly | `cargo clippy --fix` or allow specific lints |
| `act` not found | Docker not running or act not installed | `brew install act` / `docker ps` to verify Docker |
| Hardcoded Node version stale | `.nvmrc` exists but workflow uses hardcoded version | Use `node-version-file: .nvmrc` instead |
| Deploy never runs | TBR workflow renamed | Keep `name: Test Build Release` in test-build-release.yml |
| Release rebuilds binary | Artifact not downloaded | `release` job must `download-artifact` from `build` |

## Verify

→ verify: `grep -ci "template\|workflow\|validate\|dry.run" skills/wire-ci/SKILL.md | awk '{if($1>=3) print "OK: semantics"; else print "FAIL: missing"}'`
→ verify: `grep -q "wire-ci" SKILL-INDEX.md && echo "OK: in SKILL-INDEX" || echo "FAIL: not indexed"`

---

# Wire Ci — Reference

## Navigation

| Lines | Section |
|-------|---------|
| 1 | Title |
| 3–14 | Navigation |
| 16–38 | Examples |
| 40–52 | Options |
| 54–62 | Integration with build-epic |
| 64–270 | Reference blocks 1–8 |

## Examples

### Create CI for a Go project (TBR + optional deploy)

```bash
# Copy org templates
cp ~/Developer/.github/workflow-templates/test-build-release-go.yml .github/workflows/test-build-release.yml
cp ~/Developer/.github/workflow-templates/deploy-go.yml .github/workflows/deploy.yml

wire-ci --validate
wire-ci --dry-run
```

### Create CI for a CLI tool (TBR only, no deploy)

```bash
cp ~/Developer/.github/workflow-templates/test-build-release-go.yml .github/workflows/test-build-release.yml
# Edit release job to download build artifact — see big-release dogfood

wire-ci --validate
```

### Validate existing workflows (no generation)

```bash
wire-ci --validate --check-only
```

---

## Options

| Flag | Description |
|------|-------------|
| `--validate` | Check YAML syntax, permissions, secrets, common pitfalls |
| `--dry-run` | Run workflows locally via `act` or dispatch via `gh` |
| `--check-only` | Only validate, do not generate new files |
| `--type <type>` | Force project type (skip auto-detection) |
| `--force` | Overwrite existing workflow files |
| `--no-deploy` | Skip deploy.yml even for hosted stacks |

---

## Integration with build-epic

When `wire-ci` is used as part of `build-epic`:

1. **During develop-tdd**: If the task modifies `.github/workflows/`, run `wire-ci --validate` as a CI dry-run sub-step
2. **During release-branch**: After push, run `gh run list --limit 1 --branch main --json status,conclusion` to verify CI passes

---

## Reference block 1 — test-build-release.yml (Go, excerpt)

```yaml
name: Test Build Release
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read

concurrency:
  group: pipeline-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    runs-on: ubuntu-22.04
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0  # v7.0.0
      - uses: actions/setup-go@924ae3a1cded613372ab5595356fb5720e22ba16  # v6.5.0
        with:
          go-version: '1.22'
          cache: true
      - uses: golangci/golangci-lint-action@55c2c1448f86e01eaae002a5a3a9624417608d84  # v6.5.2
        with:
          version: v1.64.8

  test:
    needs: [lint]
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0  # v7.0.0
      - uses: actions/setup-go@924ae3a1cded613372ab5595356fb5720e22ba16  # v6.5.0
        with:
          go-version: '1.22'
          cache: true
      - run: go vet ./...
      - run: go test ./... -count=1

  build:
    needs: [test]
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0  # v7.0.0
      - uses: actions/setup-go@924ae3a1cded613372ab5595356fb5720e22ba16  # v6.5.0
        with:
          go-version: '1.22'
          cache: true
      - run: go build ./...
      - run: jq -n --arg sha "${{ github.sha }}" '{sha: $sha}' > deploy-meta.json
      - uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a  # v7.0.1
        with:
          name: deploy-meta
          path: deploy-meta.json

  release:
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    needs: [build]
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0  # v7.0.0
        with:
          fetch-depth: 0
      - run: npx semantic-release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## Reference block 2 — deploy.yml (BigBase, excerpt)

```yaml
name: Deploy
on:
  workflow_run:
    workflows: ["Test Build Release"]
    types: [completed]

permissions:
  contents: read
  actions: read

concurrency:
  group: deploy-production
  cancel-in-progress: false

env:
  SITE_URL: "https://CHANGE-ME.bigbase.click"

jobs:
  deploy:
    if: >
      github.event.workflow_run.conclusion == 'success' &&
      github.event.workflow_run.head_branch == 'main'
    runs-on: ubuntu-22.04
    environment: production
    steps:
      - uses: actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c  # v8.0.1
        with:
          name: deploy-meta
          github-token: ${{ secrets.GITHUB_TOKEN }}
          run-id: ${{ github.event.workflow_run.id }}
          path: deploy-meta
      - uses: danielvm-git/.github/actions/bigbase-deploy@9c56ac10c629f3baa110ddb19136579e3c90d690  # v1
        with:
          site_id: ${{ secrets.BIGBASE_SITE_ID }}
          app_type: go
          site_url: ${{ env.SITE_URL }}
          deploy_token: ${{ secrets.BIGBASE_DEPLOY_TOKEN }}
          ref: ${{ steps.meta.outputs.ref }}
          skip_health_check: true
      - name: Health check
        run: |
          curl -sf "${{ env.SITE_URL }}" || exit 1
```

---

## Reference block 3 — CLI dogfood (big-release pattern)

```yaml
  build:
    needs: [test]
    steps:
      - run: make build
      - uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a  # v7.0.1
        with:
          name: big-release-${{ github.sha }}
          path: bin/big-release

  release:
    needs: [build]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    steps:
      - uses: actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c  # v8.0.1
        with:
          name: big-release-${{ github.sha }}
          path: bin
      - run: make release   # cross-compile assets only; host binary from artifact
      - run: big-release release --verbose
```

No `deploy.yml` — CLI publishes via the release job.

---

## Reference block 4 — validate script

```bash
for f in .github/workflows/*.yml .github/workflows/*.yaml; do
  [ -f "$f" ] || continue
  python3 -c "import yaml; yaml.safe_load(open('$f'))" || echo "FAIL: $f has YAML syntax errors"
done

for f in .github/workflows/test-build-release.yml; do
  if grep -q "permissions:" "$f"; then
    echo "OK: $f has permissions block"
  else
    echo "WARNING: $f missing permissions block"
  fi
done

if grep -q 'workflows: \["Test Build Release"\]' .github/workflows/deploy.yml 2>/dev/null; then
  if ! grep -q 'name: Test Build Release' .github/workflows/test-build-release.yml; then
    echo "WARNING: deploy.yml listens for Test Build Release but TBR name may differ"
  fi
fi
```

---

## Reference block 5 — dry-run

```bash
if command -v act &>/dev/null; then
  act push --dry-run -W .github/workflows/test-build-release.yml
elif command -v gh &>/dev/null; then
  gh workflow run test-build-release.yml --ref "$(git branch --show-current)"
else
  echo "Install act or gh for dry-run"
fi
```
