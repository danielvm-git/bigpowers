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
# In your GitHub repo:
# Settings → Secrets and variables → Actions
# New repository secret:
#   Name: NPM_TOKEN
#   Value: [paste token from npm]
```

## 2. Publishing Workflow

```bash
# Tag a release
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions automatically:
# 1. Publishes to npm
# 2. Creates GitHub Release
```

## 3. Sync Skills Workflow

Automatically syncs skill artifacts when SKILL.md files change:

```bash
git push origin main
# .cursor/rules and .gemini/ auto-regenerated and committed
```

## 4. Semantic Versioning

```bash
# Patch (bug fixes)
npm version patch  # 1.0.0 → 1.0.1
git push && git push --tags

# Minor (new features)
npm version minor  # 1.0.0 → 1.1.0
git push && git push --tags

# Major (breaking changes)
npm version major  # 1.0.0 → 2.0.0
git push && git push --tags
```

## 5. Verify Setup

```bash
# Check workflows are enabled:
# GitHub repo → Actions → should see both workflows

# Check secrets are set:
# GitHub repo → Settings → Secrets → NPM_TOKEN should exist
```
