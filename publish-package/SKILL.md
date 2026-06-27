---
name: publish-package
description: "Package registry publishing for npm, crates.io, PyPI, and Homebrew. Verifies prerequisites, runs the publish command, confirms success, and surfaces actionable error hints on failure."
model: sonnet
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
See [REFERENCE.md](REFERENCE.md)

**crates.io (`Cargo.toml`):**
See [REFERENCE.md](REFERENCE.md)

**PyPI (`setup.py` / `pyproject.toml`):**
See [REFERENCE.md](REFERENCE.md)

### 3. Run publish

After all prerequisite checks pass, run the registry-specific command:

See [REFERENCE.md](REFERENCE.md)

### 4. Verify publish success

After publish, confirm the version appears on the registry:

See [REFERENCE.md](REFERENCE.md)

### 5. Error handling

On failure, surface actionable hints:

See [REFERENCE.md](REFERENCE.md)

### 6. Dry-run mode (`--dry-run`)

Run `--dry-run` to verify all prerequisites without actually publishing:

See [REFERENCE.md](REFERENCE.md)

### 7. Dry-run mode per registry

See [REFERENCE.md](REFERENCE.md)

## Verify

→ verify: `test -f publish-package/SKILL.md && echo "OK: skill file exists" || echo "FAIL: no skill file"`
→ verify: `grep -q "name: publish-package" publish-package/SKILL.md && echo "OK: frontmatter" || echo "FAIL: frontmatter"`
→ verify: `grep -ci "npm\|crates.io\|pypi\|publish\|registry" publish-package/SKILL.md | awk '{if($1>=4) print "OK: semantics"; else print "FAIL: missing"}'`
→ verify: `grep -q "publish-package" SKILL-INDEX.md && echo "OK: in SKILL-INDEX" || echo "FAIL: not indexed"`
