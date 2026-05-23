# Release & Publishing Guide

## Quick Start

### 1. Setup (one-time)

```bash
# Add NPM_TOKEN to GitHub Secrets
# → GitHub repo → Settings → Secrets and variables → Actions
# → New secret: NPM_TOKEN (from npmjs.org → Access Tokens)

# Commit setup
git add .github/ .releaserc.json .gitmessage package.json package-lock.json
git commit -m "chore: add semantic-release automation"
git push origin main
```

### 2. Making Releases

**Just commit with conventional messages:**

```bash
git commit -m "feat(new-skill): add orchestrate-project skill"
git commit -m "fix(sync-skills): handle missing directories"
git push origin main
```

**Automatically:**
- ✅ Analyzes commits
- ✅ Bumps version (semver)
- ✅ Updates CHANGELOG.md
- ✅ Creates git tag (v1.2.3)
- ✅ Publishes to npm
- ✅ Creates GitHub Release

### 3. Check Release Status

```bash
# View Actions
# GitHub → Actions → Release workflow

# View published version
npm view bigpowers

# View releases
# GitHub → Releases
```

## Commit Message Format

**Required for automatic releases:**

```
feat(scope): description          # Minor version bump (1.0.0 → 1.1.0)
fix(scope): description           # Patch version bump (1.0.0 → 1.0.1)
docs: description                 # No version bump
```

**Examples:**
```
feat(skills): add new craft-skill command
fix(sync): handle edge case in directory creation
docs: update README with examples
feat(develop-tdd)!: redesign test structure  # Major bump (BREAKING)
```

See `.github/CONVENTIONAL-COMMITS.md` for full format.

## Manual Release (Local)

```bash
export GITHUB_TOKEN=$(gh auth token)
export NPM_TOKEN=[from npmjs.org]

npm run release
```

## Version History

All releases in:
- `CHANGELOG.md` — generated from commits
- GitHub → Releases — GitHub release page
- `npm view bigpowers versions` — all npm versions

## Troubleshooting

**No release created after push?**
→ Commits may not follow conventional format
→ Check Actions log: GitHub → Actions → Release workflow

**"ENOAUTH" error?**
→ Verify NPM_TOKEN in GitHub Secrets

**Want to skip release for a commit?**
→ Add `[skip ci]` in commit message:
```
chore: update docs [skip ci]
```

## Architecture

- `.releaserc.json` — configuration
- `.github/workflows/publish.yml` — GitHub Actions workflow
- `.gitmessage` — commit template (optional)
- `package.json` — version source of truth
- `CHANGELOG.md` — auto-generated release notes

See `.github/SEMANTIC-RELEASE.md` for detailed setup.
