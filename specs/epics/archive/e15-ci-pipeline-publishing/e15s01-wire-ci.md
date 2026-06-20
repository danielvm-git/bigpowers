---
story_id: e15s01
title: "craft-skill: wire-ci — CI pipeline setup with templates and local validation"
status: backlog
bcps: 2
type: feat
context: infra
---

# Story e15s01: wire-ci skill

Create a `wire-ci` skill that provides CI pipeline setup with pre-built templates
and local validation — the CI equivalent of `wire-observability` for logging.

In big-token-saver, `fix(ci):` was 15% of commits (5/34). CI is hard to test locally,
so build-epic should expect iteration. This skill provides the scaffold.

## Acceptance Criteria

- [ ] Skill file: `wire-ci/SKILL.md` with verb-noun naming
- [ ] Templates for: Rust, Node, Python, Go (at minimum)
- [ ] `--validate` catches: YAML syntax errors, missing permissions, missing secrets
- [ ] `--dry-run` attempts local execution (act or gh workflow run)
- [ ] Skill is listed in SKILL-INDEX.md

## Gherkin Scenarios

```gherkin
Given a Rust project with Cargo.toml
And no CI workflow exists
When wire-ci runs
Then .github/workflows/ci.yaml is created with test, lint, build steps
And the workflow uses actions-rs/toolchain for Rust setup
And wire-ci --validate passes (YAML valid, permissions correct)

Given a Node project with package.json and semantic-release
When wire-ci runs
Then .github/workflows/ci.yaml includes npm test, npm run lint
And .github/workflows/release.yaml includes semantic-release with NPM_TOKEN
And wire-ci --validate warns if NPM_TOKEN secret is not configured
```

## Verification

```bash
test -f wire-ci/SKILL.md && echo "OK: skill file exists" || echo "FAIL: no skill file"
grep -q "name: wire-ci" wire-ci/SKILL.md && echo "OK: frontmatter" || echo "FAIL: frontmatter"
grep -ci "template\|workflow\|validate\|dry.run" wire-ci/SKILL.md | awk '{if($1>=3) print "OK: semantics"; else print "FAIL: missing"}'
grep -q "wire-ci" SKILL-INDEX.md && echo "OK: in SKILL-INDEX" || echo "FAIL: not indexed"
```

## Implementation Notes

- The skill must detect project type from manifest files (Cargo.toml, package.json, setup.py, go.mod)
- Generate GitHub Actions workflow(s) in `.github/workflows/`
- Include: test, lint, typecheck, build steps (derived from AGENTS.md or manifest)
- Add semantic-release integration (if project uses it)
- Document common CI failure patterns and their fixes
