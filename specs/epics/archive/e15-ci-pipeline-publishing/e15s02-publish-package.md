---
story_id: e15s02
title: "craft-skill: publish-package — npm, crates.io, PyPI publishing"
status: backlog
bcps: 1
type: feat
context: infra
---

# Story e15s02: publish-package skill

Create a `publish-package` skill that handles package registry publishing —
npm, crates.io, PyPI, Homebrew. `release-branch` handles git but doesn't know
about package registries.

In big-token-saver, npm publish required 2 iterations to fix (missing NPM_TOKEN,
prerelease version conflict).

## Acceptance Criteria

- [ ] Skill file: `publish-package/SKILL.md` with verb-noun naming
- [ ] Supports npm, crates.io, PyPI (at minimum)
- [ ] `--dry-run` for each registry
- [ ] Prerequisite checks before publish attempt
- [ ] Skill is listed in SKILL-INDEX.md

## Gherkin Scenarios

```gherkin
Given a Node project at version 0.4.0
And NPM_TOKEN is configured in .npmrc or env
When publish-package runs
Then it verifies version 0.4.0 is not already published
And runs npm publish --access public
And confirms the package appears at https://npmjs.com/package/<name>/v/0.4.0

Given NPM_TOKEN is missing
When publish-package runs
Then it reports: "FAIL: NPM_TOKEN not set. Set via: export NPM_TOKEN=<token> or .npmrc"
And exits non-zero
```

## Verification

```bash
test -f publish-package/SKILL.md && echo "OK: skill file exists" || echo "FAIL: no skill file"
grep -q "name: publish-package" publish-package/SKILL.md && echo "OK: frontmatter" || echo "FAIL: frontmatter"
grep -ci "npm\|crates.io\|pypi\|publish\|registry" publish-package/SKILL.md | awk '{if($1>=4) print "OK: semantics"; else print "FAIL: missing"}'
grep -q "publish-package" SKILL-INDEX.md && echo "OK: in SKILL-INDEX" || echo "FAIL: not indexed"
```

## Implementation Notes

- Detect package type from manifest files (package.json, Cargo.toml, setup.py, Formula/*.rb)
- Verify publish prerequisites: auth token exists, version not already published, build artifacts fresh, CHANGELOG updated
- On failure: surface the error with actionable hints
