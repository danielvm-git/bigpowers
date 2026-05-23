# Conventional Commits Guide

Used by semantic-release to automate versioning.

## Format

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

## Types

| Type | Meaning | Version |
|------|---------|---------|
| `feat` | New feature | Minor ↑ |
| `fix` | Bug fix | Patch ↑ |
| `docs` | Doc updates | No bump |
| `style` | Formatting | No bump |
| `refactor` | Code refactor | No bump |
| `perf` | Performance | No bump |
| `test` | Test updates | No bump |
| `chore` | Maintenance | No bump |

## Examples

### Feature (1.0.0 → 1.1.0)
```
feat(craft-skill): add interactive mode support

Allows users to run craft-skill with --interactive flag
for step-by-step guidance.
```

### Fix (1.0.0 → 1.0.1)
```
fix(sync-skills): handle missing directories gracefully

Previously threw error if .cursor directory didn't exist.
Now creates it automatically.
```

### Breaking Change (1.0.0 → 2.0.0)
```
feat(skills)!: restructure SKILL.md format

BREAKING CHANGE: SKILL.md now requires [usage] section
instead of [examples]. Update all existing skills.
```

### Multiple Changes
```
feat(sync-skills): add changelog generation
docs: update README with new examples
fix(craft-skill): handle edge case in validation
```

Semantic-release parses all and creates CHANGELOG.md

## Tips

- Be specific in scope: `fix(develop-tdd)` not `fix(core)`
- Use imperative mood: "add feature" not "added feature"
- Keep subject under 50 chars
- Separate subject from body with blank line
- Body explains *why*, not *what*

## Verification

```bash
git log --oneline main | head -10
# Should see: feat(...), fix(...), docs(...)
```

## Auto-Fix in IDE

Add `.gitmessage` template to repo root:

```
<type>(<scope>): <description>

[body]

[footer]
```

Configure git:
```bash
git config commit.template .gitmessage
```

Now `git commit` will prompt format.
