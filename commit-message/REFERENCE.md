# Conventional Commits + semantic-style release (reference)

## Message format

From [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/#specification):

```text
<type>[optional scope][optional !]: <description>

[optional body]

[optional footer(s)]
```

- **Scope:** parenthesized noun, e.g. `feat(parser): …`.
- **Breaking:** `!` before `:` (e.g. `feat(api)!: …`) and/or footer `BREAKING CHANGE: description` (token must be uppercase per spec for that footer name).
- **Description:** short summary; body explains *why* or migration steps.

Common **types** (not exhaustive): `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore` — as in [Angular / commitlint conventions](https://github.com/conventional-changelog/commitlint).

## Advanced Specification Patterns

### Reverts
If the commit reverts a previous commit, it should begin with `revert:`, followed by the header of the reverted commit. In the body, it should say: `This reverts commit <hash>.`.

```text
revert: feat(api): add user endpoint

This reverts commit 676104e.
```

### Breaking Changes
A breaking change can be signaled by:
1.  A **`!`** after the type/scope: `feat(api)!: change user response shape`
2.  A **`BREAKING CHANGE:`** footer (must be uppercase).

**Pro-tip:** Use both for maximum visibility in auto-generated changelogs.

### Footers (Tokens & Values)
Footers follow the same `Token: value` pattern as Git Trailers. Common tokens:
- `Refs: #123`
- `See-also: docs/ADR-001.md`
- `Co-authored-by: Name <email>`
- `Signed-off-by: Name <email>`

**Multi-line footers:** If a footer value spans multiple lines, each subsequent line must be indented.

### Squashing & History
When using `gh pr merge --squash`, the PR title is usually used as the commit subject. 
- **PR Title:** MUST follow `<type>(<scope>): <description>`
- **PR Body:** Content will be moved to the commit body.

## Release Type Mapping (Strict)

| Commit pattern | Release |
|----------------|---------|
| `fix:` | Patch |
| `feat:` | Minor |
| `any type!:` | Major |
| `BREAKING CHANGE:` in footer | Major |
| `perf:`, `refactor:`, `style:` | Patch (usually) |
| `docs:`, `chore:`, `test:`, `ci:` | None |

## Custom Repositories

- Read `release.config.js`, `.releaserc`, or `package.json` → `release` / `semantic-release` config.
- The **@semantic-release/commit-analyzer** preset may map types differently; prefer **their** rules when they conflict with this reference.

## Squash and PR titles

- If the team squashes on merge, the **PR title** often becomes the single squashed commit subject — it should still follow `type(scope): description` for tooling.
- `revert:` type and `Refs:` footers are valid patterns; revert handling varies by [tooling](https://www.conventionalcommits.org/en/v1.0.0/#specification).

## Links

- [Conventional Commits — specification](https://www.conventionalcommits.org/en/v1.0.0/#specification)
- [semantic-release — README (commit format & flow)](https://github.com/semantic-release/semantic-release#commit-message-format)
- Fork pointer: [semantic-release-baby](https://github.com/danielvm-git/semantic-release-baby) (automation and docs align with upstream semantic-release)
