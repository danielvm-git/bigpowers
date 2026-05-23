# Semantic Release Setup

Automated versioning and publishing with conventional commits.

## Installation ✅

```bash
npm install --save-dev semantic-release \
  @semantic-release/commit-analyzer \
  @semantic-release/release-notes-generator \
  @semantic-release/changelog \
  @semantic-release/git \
  @semantic-release/github
```

Already in package.json devDependencies.

## Configuration

`.releaserc.json` handles:
- Conventional commit parsing
- Automatic changelog generation
- Git tag creation
- GitHub release creation
- npm publication

## Tokens Setup

Two environment variables needed in GitHub Actions:

### 1. NPM_TOKEN
```bash
# On npmjs.org:
# → Settings → Access Tokens → Create Token (Automation)
# → Copy token

# On GitHub (this repo):
# → Settings → Secrets and variables → Actions
# → New secret: NPM_TOKEN = [paste]
```

### 2. GITHUB_TOKEN
Built-in GitHub secret (auto-provided to Actions).

## Workflow

### Automatic (on push to main)

Just push with conventional commits:

```bash
git commit -m "feat: add new skill"
git commit -m "fix: resolve bug in sync"
git commit -m "docs: update README"
git push origin main
```

GitHub Actions automatically:
1. Analyzes commits
2. Bumps version (semver)
3. Generates changelog
4. Creates git tag
5. Publishes to npm
6. Creates GitHub Release

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature (minor bump)
- `fix`: Bug fix (patch bump)
- `docs`: Documentation
- `refactor`: Code refactor (no version bump)
- `chore`: Maintenance

**Examples:**
```
feat(skills): add new craft-skill command
fix(sync): handle missing skill directories
docs: update setup instructions
```

**Breaking changes** (major bump):
```
feat!: redesign skill structure
feat(skills)!: remove deprecated syntax
```

Or in footer:
```
feat: new feature

BREAKING CHANGE: old syntax no longer supported
```

## Manual Release (local)

```bash
npm run release
```

Requires:
- GITHUB_TOKEN env var
- NPM_TOKEN env var

## Verify Setup

```bash
# Check workflows
git log --oneline main | head -5

# View Actions
# GitHub → Actions → Release workflow

# View release
# GitHub → Releases

# Verify npm
npm view bigpowers versions
```

## Troubleshooting

### "ENOAUTH" error
→ Check NPM_TOKEN in GitHub Secrets

### "Not authorized to create release"
→ Check GITHUB_TOKEN permissions

### No release created after push
→ Commits may not be conventional format
→ Check Actions log for details

## Version History

Versions follow semver with conventional commits:
- `1.0.0` → Initial release
- `1.0.1` → patch fixes only
- `1.1.0` → new features + fixes
- `2.0.0` → breaking changes

Check CHANGELOG.md for all releases.
