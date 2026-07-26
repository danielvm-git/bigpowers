---
name: wire-ci
description: "CI pipeline setup with bundled, forge-neutral templates and local validation. Detects the forge from the git remote, generates workflows for supported forges, and skips honestly for the rest. The CI equivalent of wire-observability."
model: sonnet
effort: standard
---

# Wire CI

> **HARD GATE (supported forges only)** — Do not ship a project without CI. Run this skill before first merge to main.
>
> On a forge bigpowers ships no templates for, this skill **is not a gate**: it reports the forge, explains what it cannot do, and exits 3. A gate that cannot run must not claim it did. See § Unsupported forges.
>
> **HARD GATE** — CI that is untestable locally will break every cycle. Always run `--validate` after generating workflows and `--dry-run` before pushing.

Generate, validate, and test CI workflows. Detects the forge and project type, copies a **bundled** template, and verifies locally before anything reaches CI.

## Forge resolution

`scripts/lib/detect-forge.sh` resolves the forge, first match wins: `BIGPOWERS_FORGE` env var → `forge:` in `specs/forge.yaml` → the `origin` remote URL → `unknown`.

```bash
bash scripts/wire-ci.sh --detect     # report forge + stack, write nothing
bash scripts/wire-ci.sh --plan       # show the template that would be used
bash scripts/wire-ci.sh --apply      # write the workflow
```

GitHub ships templates (`.github/workflows/`). GitLab, Bitbucket, Codeberg, and Gitea are detected but **unsupported** — `--apply` writes nothing and exits 3.

## Template source — configurable, bundled by default

Templates live in `docs/templates/ci/<forge>/` **inside the bigpowers package**, so there is no network dependency on any third party's repository. Override with `BIGPOWERS_CI_TEMPLATES=/path/to/your/templates`, laid out as `<root>/<forge>/test-build-release-<stack>.yml`.

## What this sets up

1. **Test Build Release workflow** — lint → test → build → release in one `needs:` chain
2. **`--validate` mode** — YAML syntax, workflow permissions, required secrets, common pitfalls
3. **`--dry-run` mode** — runs workflows locally via `act` before push
4. **Failure pattern documentation** — see the table below

Deploy workflows are **not** bundled: they are platform-specific. See [REFERENCE.md](REFERENCE.md) for a worked example.

## Process

### 1. Detect forge and stack

```bash
bash scripts/wire-ci.sh --detect
```

Stack detection reads the project root:

| Manifest | Stack | Bundled template |
|----------|-------|------------------|
| `Cargo.toml` | Rust | `test-build-release-rust.yml` |
| `package.json` | Node | `test-build-release-node.yml` |
| `pyproject.toml` / `setup.py` | Python | `test-build-release-python.yml` |
| `go.mod` | Go | `test-build-release-go.yml` |

No recognized manifest → exit 3 with the list of manifests it looked for. Do not guess.

### 2. Apply the template

```bash
bash scripts/wire-ci.sh --apply
```

**Do not rename the workflow `name:` field** — deploy listens for `"Test Build Release"`.

Edit placeholders after copying: language versions, `APP_TYPE`, `SITE_URL`.

### 3. Unsupported forges

`--apply` writes nothing and exits 3. Your options, in the order the runner prints them:

- point `BIGPOWERS_CI_TEMPLATES` at templates for your forge
- pin `forge: github` in `specs/forge.yaml` if the remote is misdetected
- write the CI config by hand

Contributing a `docs/templates/ci/gitlab/` set and adding `gitlab` to `FORGE_SUPPORTED_LIST` is the natural next slice — per-forge command mapping (`gh pr checks` → `glab ci status`) is not implemented yet.

### 4. Validate workflows (`--validate`)

See [REFERENCE.md](REFERENCE.md). Exit codes: `0` clean, `1` YAML syntax errors, `2` warnings only.

### 5. Dry-run workflows (`--dry-run`)

See [REFERENCE.md](REFERENCE.md).

> **act** runs workflows in a local Docker environment — the most accurate pre-push validation.
> **gh workflow run** sends the workflow to GitHub but does not execute locally.

### 6. Document common CI failure patterns

| Failure | Cause | Fix |
|---------|-------|-----|
| `npm publish` fails | `NPM_TOKEN` not set as repo secret | Add `NPM_TOKEN` to repo secrets |
| `semantic-release` fails on push | Missing `permissions: contents: write` | Add it to the release job |
| `cargo publish` auth fail | `CARGO_REGISTRY_TOKEN` not set | Add token to env or `~/.cargo/config.toml` |
| `go vet` fails | Go version mismatch | Use `go-version-file: go.mod` |
| `cargo clippy` errors | New nightly lints | Pin the toolchain; `cargo clippy --fix` |
| `act` not found | Docker not running or act missing | `brew install act`; `docker ps` |
| Hardcoded Node version stale | `.nvmrc` exists but workflow hardcodes | Use `node-version-file: .nvmrc` |
| Deploy never runs | TBR workflow renamed | Keep `name: Test Build Release` |
| Release rebuilds binary | Artifact not downloaded | `release` must `download-artifact` from `build` |

## Verify

→ verify: `bash scripts/wire-ci.sh --self-test`
→ verify: `test -f docs/templates/ci/github/test-build-release-node.yml && test -f scripts/lib/detect-forge.sh`
→ verify: `grep -q wire-ci SKILL-INDEX.md`
