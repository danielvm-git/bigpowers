---
name: wire-ci
description: "CI pipeline setup with pre-built templates and local validation. Generates GitHub Actions workflows, validates YAML syntax and permissions, supports dry-run via act/gh. The CI equivalent of wire-observability."
model: sonnet
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
See [REFERENCE.md](REFERENCE.md)

**Node template (`package.json`):**
See [REFERENCE.md](REFERENCE.md)

**Python template (`setup.py` / `pyproject.toml`):**
See [REFERENCE.md](REFERENCE.md)

**Go template (`go.mod`):**
See [REFERENCE.md](REFERENCE.md)

**C/C++ template (`CMakeLists.txt`):**
See [REFERENCE.md](REFERENCE.md)

### 3. Generate release workflow (if semantic-release detected)

If the project has semantic-release configured (in `package.json`, `.releaserc`, or `release.config.js`), also generate `.github/workflows/release.yaml`:

See [REFERENCE.md](REFERENCE.md)

> **NPM_TOKEN is required** for publishing to npm. Without it, semantic-release will fail at the publish step. See `--validate` to check this.

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

## Verify

→ verify: `test -f wire-ci/SKILL.md && echo "OK: skill file exists" || echo "FAIL: no skill file"`
→ verify: `grep -q "name: wire-ci" wire-ci/SKILL.md && echo "OK: frontmatter" || echo "FAIL: frontmatter"`
→ verify: `grep -ci "template\|workflow\|validate\|dry.run" wire-ci/SKILL.md | awk '{if($1>=3) print "OK: semantics"; else print "FAIL: missing"}'`
→ verify: `grep -q "wire-ci" SKILL-INDEX.md && echo "OK: in SKILL-INDEX" || echo "FAIL: not indexed"`
