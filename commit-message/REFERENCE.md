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
1.  A **`BREAKING CHANGE:`** footer (must be uppercase, at the start of the footer). This is the **most compatible** way to trigger a Major release in `semantic-release` (Angular preset).
2.  A **`!`** after the type/scope: `feat(api)!: change user response shape`.

**Pro-tip:** For maximum compatibility with all tooling (older and newer), use BOTH the `!` and the `BREAKING CHANGE:` footer.

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

## Release Type Mapping (Default Angular Preset)

This table reflects the **out-of-the-box** behavior of `semantic-release` using the `@semantic-release/commit-analyzer` default (Angular) rules.

| Commit pattern | Release | Notes |
|----------------|---------|-------|
| `fix:` | **Patch** | Bug fixes |
| `feat:` | **Minor** | New features |
| `perf:` | **Patch** | Performance improvements |
| `any type` + `BREAKING CHANGE:` footer | **Major** | **Mandatory** for Major version bumps in default configs. |
| `any type!:` (exclamation mark) | **Major** | Supported by modern CC parsers, but use footer for max safety. |
| `docs:`, `chore:`, `test:`, `ci:`, `refactor:`, `style:` | **None** | Does not trigger a new release by default. |

> **Warning:** While `refactor:` and `style:` improve code, they do NOT trigger a release in the default Angular preset. Use `fix:` if a refactor also fixes a bug, or `feat:` if it adds new behavior.

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
