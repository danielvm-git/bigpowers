# Wire Ci — Reference

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


---

## Options

| Flag | Description |
|------|-------------|
| `--validate` | Check YAML syntax, permissions, secrets, common pitfalls |
| `--dry-run` | Run workflows locally via `act` or dispatch via `gh` |
| `--check-only` | Only validate, do not generate new files |
| `--type <type>` | Force project type (skip auto-detection) |
| `--force` | Overwrite existing workflow files |
| `--no-release` | Skip release workflow generation even if semantic-release detected |


---

## Integration with build-epic

When `wire-ci` is used as part of `build-epic`:

1. **During develop-tdd**: If the task modifies `.github/workflows/`, run `wire-ci --validate` as a CI dry-run sub-step
2. **During release-branch**: After push, run `gh run list --limit 1 --branch main --json status,conclusion` to verify CI passes

---

## Reference block 1

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

---

## Reference block 2

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

---

## Reference block 3

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

---

## Reference block 4

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

---

## Reference block 5

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

---

## Reference block 6

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

---

## Reference block 7

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

---

## Reference block 8

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