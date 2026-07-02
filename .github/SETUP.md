# GitHub Actions CI/CD Setup

## 1. Configure npm Token

Generate an npm automation token:

```bash
# On npmjs.org:
# 1. Login to https://www.npmjs.com
# 2. Settings → Access Tokens
# 3. Create Token → Automation
# 4. Copy token
```

Add to GitHub:

```bash
gh secret set NPM_TOKEN --body "your-automation-token"
```

## 2. Release Workflow

Releases are automated by [semantic-release](https://github.com/semantic-release/semantic-release) on every push to `main` with conventional commits.

```bash
git commit -m "feat(skills): add example skill"
git push origin main
```

GitHub Actions automatically:

1. Analyzes commits and bumps semver
2. Updates `CHANGELOG.md` and `package.json`
3. Publishes to [npm](https://www.npmjs.com/package/bigpowers)
4. Creates a GitHub Release and git tag

Manual tagging (`git tag v1.0.0`) is not required.

See `docs/RELEASE.md` and `.github/SEMANTIC-RELEASE.md` for commit format and troubleshooting.

## 3. Sync Skills Workflow

Automatically syncs skill artifacts when SKILL.md files change:

```bash
git push origin main
# .cursor/rules and .gemini/ auto-regenerated and committed
```

## 4. Verify Setup

```bash
# Workflows enabled
gh workflow list

# NPM_TOKEN secret set
gh secret list

# Latest published version
npm view bigpowers version
```
