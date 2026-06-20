---
name: wire-ci
description: "\"CI pipeline setup with pre-built templates and local validation. Generates GitHub Actions workflows, validates YAML syntax and permissions, supports dry-run via act/gh. The CI equivalent of wire-observability.\""
---


# Wire CI

> **HARD GATE** — Do not ship a project without CI. Run this skill before first merge to main or when adding CI to an existing project.
>
> **HARD GATE** — CI that is untestable locally will break every cycle. Always run `--validate` after generating workflows and `--dry-run` before pushing.

Generate, validate, and test CI workflows. Detects your project type, produces platform-appropriate GitHub Actions configurations, and provides local verification to catch auth, permissions, and syntax issues before they reach CI.

## What this sets up

1. **CI workflow** — `.github/workflows/ci.yaml` with test, lint, typecheck, build steps
2. **Release workflow** — `.github/workflows/release.yaml` with semantic-release (if applicable)
3. **`--validate` mode** — checks YAML syntax, workflow permissions, required secrets, and common pitfalls
4. **`--dry-run` mode** — runs workflows locally via `act` or `gh workflow run` to prove correctness before push
5. **Failure pattern documentation** — common CI failure categories and their fixes

## Process

### 1. Detect project type

Read the project root for manifest files to determine which template to use:

| Manifest | Type | Template |
|----------|------|----------|
| `Cargo.toml` | Rust | Rust CI: test, clippy, fmt, build |
| `package.json` | Node | Node CI: test, lint, typecheck, build |
| `setup.py` / `pyproject.toml` | Python | Python CI: pytest, ruff/mypy/flake8, build |
| `go.mod` | Go | Go CI: test, vet, staticcheck, build |
| `CMakeLists.txt` | C/C++ | C/C++ CI: cmake build, ctest |
| Multiple detected | Polyglot | Combined workflows or error if ambiguous |

If no manifest is found, prompt the user to specify the type or pass `--type <rust|node|python|go|cpp>`.

### 2. Generate CI workflow

Create `.github/workflows/ci.yaml` with standard steps derived from the project type and its manifest:

**Rust template (`Cargo.toml`):**
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions-rust/toolchain@v1
        with:
          toolchain: stable
          components: clippy, rustfmt
      - run: cargo fmt --all -- --check
      - run: cargo clippy -- -D warnings
      - run: cargo test
      - run: cargo build --release
```

**Node template (`package.json`):**
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - run: npm ci
      - run: npm test
      - run: npm run lint 2>/dev/null || true
      - run: npm run typecheck 2>/dev/null || true
      - run: npm run build 2>/dev/null || true
```

**Python template (`setup.py` / `pyproject.toml`):**
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
          cache: pip
      - run: pip install -e ".[dev]" || pip install -e .
      - run: pip install pytest ruff mypy
      - run: ruff check .
      - run: mypy . 2>/dev/null || true
      - run: pytest
```

**Go template (`go.mod`):**
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: stable
          cache: true
      - run: go vet ./...
      - run: go test ./...
      - run: go build ./...
```

**C/C++ template (`CMakeLists.txt`):**
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: cmake -B build
      - run: cmake --build build
      - run: ctest --test-dir build
```

### 3. Generate release workflow (if semantic-release detected)

If the project has semantic-release configured (in `package.json`, `.releaserc`, or `release.config.js`), also generate `.github/workflows/release.yaml`:

```yaml
name: Release
on:
  push:
    branches: [main]
jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      issues: write
      pull-requests: write
      id-token: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - run: npm ci
      - run: npm run build 2>/dev/null || true
      - run: npx semantic-release
        env:
          GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: \${{ secrets.NPM_TOKEN }}
```

> **NPM_TOKEN is required** for publishing to npm. Without it, semantic-release will fail at the publish step. See `--validate` to check this.

### 4. Validate workflows (`--validate`)

Run `wire-ci --validate` to check all generated workflow files:

```bash
# Validate YAML syntax
for f in .github/workflows/*.yaml; do
  python3 -c "import yaml; yaml.safe_load(open('$f'))" || echo "FAIL: $f has YAML syntax errors"
done

# Check permissions block presence
for f in .github/workflows/*.yaml; do
  if grep -q "permissions:" "$f"; then
    echo "OK: $f has permissions block"
  else
    echo "WARNING: $f missing permissions block — add one for security"
  fi
done

# Check for npm publish without NPM_TOKEN
for f in .github/workflows/*.yaml; do
  if grep -q "npm publish\|npx semantic-release" "$f"; then
    if ! grep -q "NPM_TOKEN" "$f"; then
      echo "WARNING: $f has npm publish/semantic-release but no NPM_TOKEN secret"
    fi
  fi
done

# Check for hardcoded Node versions
for f in .github/workflows/*.yaml; do
  if grep -q "node-version: [0-9]" "$f" && grep -qv "node-version-file\|\.nvmrc" "$f"; then
    echo "NOTE: $f has hardcoded Node version — consider using .nvmrc instead"
  fi
done

# Check for common secrets reference errors
for f in .github/workflows/*.yaml; do
  # Secrets referencing something that doesn't exist in the workflow
  grep -oP 'secrets\.\w+' "$f" | sort -u | while read -r secret; do
    echo "REF: $f references $secret"
  done
done
```

**Exit codes:**
- `0` — all checks pass (no errors)
- `1` — YAML syntax errors found
- `2` — validation warnings only (missing permissions, secrets, etc.)

### 5. Dry-run workflows (`--dry-run`)

Attempt to run the generated workflows locally to catch errors before push:

```bash
# Option A: Use act (recommended)
if command -v act &>/dev/null; then
  act push --dry-run
  echo "OK: act dry-run completed"
elif command -v gh &>/dev/null; then
  # Option B: Use gh workflow run (remote test, no local docker)
  gh workflow run ci.yaml --ref "$(git branch --show-current)"
  echo "OK: CI workflow dispatched. Check status: gh run list"
else
  echo "NOTE: Install act (https://github.com/nektos/act) for full local dry-run"
  echo "      Install gh CLI for remote dry-run"
fi
```

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

## Examples

### Create CI for a Rust project

```bash
# Detect from Cargo.toml, generate workflows
wire-ci

# Validate generated workflows
wire-ci --validate

# Run locally with act
wire-ci --dry-run
```

### Create CI for a Node project with semantic-release

```bash
wire-ci
wire-ci --validate
# Expect warning: "npm publish step found but no NPM_TOKEN in secrets"
# Fix: add NPM_TOKEN to repo secrets
```

### Validate existing workflows (no generation)

```bash
wire-ci --validate --check-only
```

## Options

| Flag | Description |
|------|-------------|
| `--validate` | Check YAML syntax, permissions, secrets, common pitfalls |
| `--dry-run` | Run workflows locally via `act` or dispatch via `gh` |
| `--check-only` | Only validate, do not generate new files |
| `--type <type>` | Force project type (skip auto-detection) |
| `--force` | Overwrite existing workflow files |
| `--no-release` | Skip release workflow generation even if semantic-release detected |

## Integration with build-epic

When `wire-ci` is used as part of `build-epic`:

1. **During develop-tdd**: If the task modifies `.github/workflows/`, run `wire-ci --validate` as a CI dry-run sub-step
2. **During release-branch**: After push, run `gh run list --limit 1 --branch main --json status,conclusion` to verify CI passes

## Verify

→ verify: `test -f wire-ci/SKILL.md && echo "OK: skill file exists" || echo "FAIL: no skill file"`
→ verify: `grep -q "name: wire-ci" wire-ci/SKILL.md && echo "OK: frontmatter" || echo "FAIL: frontmatter"`
→ verify: `grep -ci "template\|workflow\|validate\|dry.run" wire-ci/SKILL.md | awk '{if($1>=3) print "OK: semantics"; else print "FAIL: missing"}'`
→ verify: `grep -q "wire-ci" SKILL-INDEX.md && echo "OK: in SKILL-INDEX" || echo "FAIL: not indexed"`
