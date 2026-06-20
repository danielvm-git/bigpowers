---
name: publish-package
description: "\"Package registry publishing for npm, crates.io, PyPI, and Homebrew. Verifies prerequisites, runs the publish command, confirms success, and surfaces actionable error hints on failure.\""
---


# Publish Package

> **HARD GATE** — Do not attempt to publish without verifying prerequisites. Missing auth tokens, stale builds, or duplicate versions cause CI failures that are hard to debug post-push.
>
> **HARD GATE** — Always run `--dry-run` first. Package registries are append-only — a bad publish cannot be fully undone on most registries.

Publish packages to language-specific registries. Detects package type from manifest files, verifies publish prerequisites, runs the registry-specific publish command, and confirms the version appears on the registry.

## Process

### 1. Detect package type

Read the project root for manifest files to determine the package type:

| Manifest | Registry | Publish command |
|----------|----------|----------------|
| `package.json` | npm | `npm publish --access public` |
| `Cargo.toml` | crates.io | `cargo publish` |
| `setup.py` / `pyproject.toml` | PyPI | `twine upload dist/*` or `flit publish` |
| `Formula/<name>.rb` | Homebrew | `brew bump-formula-pr` |
| Multiple detected | Polyglot | Error: specify registry with `--registry <npm|crates.io|pypi|brew>` |

If no manifest is found, prompt the user to specify the type or pass `--type <npm|crates.io|pypi|brew>`.

### 2. Verify prerequisites

Before attempting any publish, run all applicable checks:

**npm (`package.json`):**
```bash
# Check auth token exists
if [ -z "${NPM_TOKEN:-}" ]; then
  if [ ! -f ~/.npmrc ] || ! grep -q "_authToken" ~/.npmrc; then
    echo "FAIL: NPM_TOKEN not set. Set via: export NPM_TOKEN=<token> or add //registry.npmjs.org/:_authToken=<token> to .npmrc"
    exit 1
  fi
fi

# Check version not already published
PACKAGE_NAME=$(node -p "require('./package.json').name")
CURRENT_VER=$(node -p "require('./package.json').version")
if npm view "$PACKAGE_NAME@$CURRENT_VER" version 2>/dev/null; then
  echo "FAIL: Version $CURRENT_VER already published for $PACKAGE_NAME. Bump version first."
  exit 1
fi

# Check build artifacts are fresh
if [ -d dist ] || [ -d lib ]; then
  LATEST_BUILD=$(find dist lib 2>/dev/null -name "*.js" -o -name "*.cjs" -o -name "*.mjs" | xargs ls -t 2>/dev/null | head -1)
  PACKAGE_MODIFIED=$(stat -f %m package.json 2>/dev/null || stat -c %Y package.json 2>/dev/null)
  if [ -n "$LATEST_BUILD" ] && [ -n "$PACKAGE_MODIFIED" ]; then
    BUILD_TIME=$(stat -f %m "$LATEST_BUILD" 2>/dev/null || stat -c %Y "$LATEST_BUILD" 2>/dev/null)
    if [ "$BUILD_TIME" -lt "$PACKAGE_MODIFIED" ]; then
      echo "WARNING: Build artifacts may be stale (package.json modified after last build). Run npm run build first."
    fi
  fi
fi

# Check CHANGELOG is updated
if [ -f CHANGELOG.md ]; then
  if ! grep -q "$CURRENT_VER" CHANGELOG.md 2>/dev/null; then
    echo "WARNING: Version $CURRENT_VER not found in CHANGELOG.md. Update changelog before publish."
  fi
fi
```

**crates.io (`Cargo.toml`):**
```bash
# Check auth token exists
if [ -z "${CARGO_REGISTRY_TOKEN:-}" ]; then
  if [ ! -f ~/.cargo/config.toml ] || ! grep -q "token" ~/.cargo/config.toml; then
    echo "FAIL: CARGO_REGISTRY_TOKEN not set. Set via: export CARGO_REGISTRY_TOKEN=<token> or add to ~/.cargo/config.toml"
    exit 1
  fi
fi

# Check version not already published
CRATE_NAME=$(grep '^name' Cargo.toml | head -1 | sed 's/.*"\(.*\)"/\1/')
CURRENT_VER=$(grep '^version' Cargo.toml | head -1 | sed 's/.*"\(.*\)"/\1/')
if cargo search "$CRATE_NAME" 2>/dev/null | grep -q "^${CRATE_NAME}.*\"$CURRENT_VER\""; then
  echo "FAIL: Version $CURRENT_VER already published for $CRATE_NAME. Bump version in Cargo.toml first."
  exit 1
fi
```

**PyPI (`setup.py` / `pyproject.toml`):**
```bash
# Check auth token exists
if [ -z "${TWINE_PASSWORD:-}" ] && [ -z "${POETRY_PYPI_TOKEN_PYPI:-}" ]; then
  if [ ! -f ~/.pypirc ]; then
    echo "FAIL: PyPI token not configured. Set TWINE_PASSWORD or create ~/.pypirc"
    exit 1
  fi
fi

# Check for build artifacts
if [ ! -d dist ] || [ -z "$(ls dist/*.whl 2>/dev/null)" ]; then
  echo "WARNING: No .whl files found in dist/. Run: python -m build"
fi
```

### 3. Run publish

After all prerequisite checks pass, run the registry-specific command:

```bash
# npm
npm publish --access public

# crates.io
cargo publish

# PyPI
python -m twine upload dist/*  # or: poetry publish

# Homebrew (opens PR, does not publish directly)
brew bump-formula-pr --url=<tarball-url> <formula-name>
```

### 4. Verify publish success

After publish, confirm the version appears on the registry:

```bash
# npm
npm view "$PACKAGE_NAME" versions --json 2>/dev/null | grep -q "\"$CURRENT_VER\"" && echo "OK: npm publish confirmed"

# crates.io
cargo search "$CRATE_NAME" 2>/dev/null | grep -q "^${CRATE_NAME}.*\"$CURRENT_VER\"" && echo "OK: crates.io publish confirmed"

# PyPI
pip index versions "$PACKAGE_NAME" 2>/dev/null | grep -q "$CURRENT_VER" && echo "OK: PyPI publish confirmed"
```

### 5. Error handling

On failure, surface actionable hints:

```bash
# Generic failure handler
if [ $? -ne 0 ]; then
  case "$REGISTRY" in
    npm)
      echo "FAIL: npm publish failed."
      echo "  Common causes:"
      echo "  - NPM_TOKEN not set in secrets: add to GitHub repo secrets"
      echo "  - Version already published: bump version in package.json"
      echo "  - Two-factor auth required: use --otp=<code> flag"
      echo "  - Package scoped but not public: add --access public"
      ;;
    crates.io)
      echo "FAIL: cargo publish failed."
      echo "  Common causes:"
      echo "  - CARGO_REGISTRY_TOKEN not configured: see ~/.cargo/config.toml"
      echo "  - Version already published: bump version in Cargo.toml"
      echo "  - Local changes not committed: cargo publish requires clean working tree"
      ;;
    pypi)
      echo "FAIL: PyPI publish failed."
      echo "  Common causes:"
      echo "  - TWINE_PASSWORD not configured: set env var or ~/.pypirc"
      echo "  - Build artifacts missing: run python -m build first"
      echo "  - Version conflict: version already exists on PyPI"
      ;;
  esac
  exit 1
fi
```

### 6. Dry-run mode (`--dry-run`)

Run `--dry-run` to verify all prerequisites without actually publishing:

```bash
# Example output
$ publish-package --dry-run

[DRY-RUN] Detected package type: npm
[DRY-RUN] Package: my-package v0.4.0
[DRY-RUN] Checking NPM_TOKEN... OK
[DRY-RUN] Checking version 0.4.0 not already published... OK
[DRY-RUN] Checking build artifacts... WARNING: package.json modified after build
[DRY-RUN] Checking CHANGELOG... OK
[DRY-RUN] Would run: npm publish --access public
[DRY-RUN] Exiting without publishing.
```

### 7. Dry-run mode per registry

```bash
# npm dry-run
npm publish --access public --dry-run

# crates.io dry-run (cargo does not have a publish dry-run; use --dry-run flag for validation only)
cargo package --list 2>/dev/null

# PyPI dry-run
python -m twine upload --repository testpypi dist/*  # test.pypi.org
```

## Options

| Flag | Description |
|------|-------------|
| `--dry-run` | Verify prerequisites and show publish command without executing |
| `--registry <type>` | Force registry type (skip auto-detection) |
| `--otp <code>` | One-time password for npm 2FA |
| `--no-verify` | Skip prerequisite checks (use with caution) |

## Examples

### Publish an npm package

```bash
# Verify first
publish-package --dry-run

# Publish
publish-package

# Output:
#   [npm] Publishing my-package v0.4.0...
#   OK: npm publish confirmed (my-package@0.4.0 on registry)
```

### Publish a Rust crate

```bash
export CARGO_REGISTRY_TOKEN=<token>
publish-package --dry-run
publish-package
```

### Missing token scenario

```bash
$ publish-package
FAIL: NPM_TOKEN not set. Set via: export NPM_TOKEN=<token> or add to .npmrc
```

## Integration with release-branch

When wired into `release-branch`, add a step after git push:

```
6a. Run publish-package to publish to package registries
    → verify: publish-package --dry-run && publish-package
```

## Verify

→ verify: `test -f publish-package/SKILL.md && echo "OK: skill file exists" || echo "FAIL: no skill file"`
→ verify: `grep -q "name: publish-package" publish-package/SKILL.md && echo "OK: frontmatter" || echo "FAIL: frontmatter"`
→ verify: `grep -ci "npm\|crates.io\|pypi\|publish\|registry" publish-package/SKILL.md | awk '{if($1>=4) print "OK: semantics"; else print "FAIL: missing"}'`
→ verify: `grep -q "publish-package" SKILL-INDEX.md && echo "OK: in SKILL-INDEX" || echo "FAIL: not indexed"`
