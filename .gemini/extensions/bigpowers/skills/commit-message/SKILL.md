---
name: commit-message
description: "Reviews working-tree changes, then drafts a Conventional Commits title/body and states the semantic-release version bump a single such commit would imply. Also notes which defensive-code categories were touched. Use when the user wants to commit recent work, prepare a Conventional Commits message, or asks for semantic-release / semver-consistent messaging before git commit."
---


# Commit Message

## What "last chat" means

- **Primary source of truth:** `git status`, `git diff` (unstaged), and `git diff --cached` (staged). Run these in the repo root (or the paths the user changed).
- **Context:** use the current conversation to summarize *intent* and to spot **breaking** API/behavior changes that diff alone may not show.
- If the user tracks a session baseline (e.g. branch, tag, or `git stash create` at start), you may `git diff <baseline>..HEAD` plus uncommitted diffs; otherwise use only the index and working tree.

## Quick workflow

1. **Inventory** — List changed paths; group by feature vs chore vs docs vs test-only.
2. **Decide commit shape** — One atomic commit is ideal. If the diff mixes unrelated concerns, recommend **multiple commits** (each with its own type/scope) before suggesting one message.
3. **Classify for semantic release** — `fix` → patch, `feat` → minor, **breaking** → major.
4. **Write the message** — `type(optional-scope)!: description` (see [REFERENCE.md](REFERENCE.md#message-format)). Use `!` or a `BREAKING CHANGE:` footer when behavior contracts change.
5. **Note defensive-code categories touched** — from CONVENTIONS.md: Rate limit | Retry with backoff | Circuit breaker | Timeout | Graceful degradation
6. **Deliver** — Output:
   - Proposed **full commit message** (title + optional body + footers).
   - **Release bump** this commit would drive: `patch` | `minor` | `major` | `none`.
   - Optional `git add …` and `git commit -m` instructions; do **not** run destructive git commands unless the user asked.

## Checklist before finalizing

- [ ] Type matches the **dominant** user-visible outcome (`feat` vs `fix` vs `perf`, etc.).
- [ ] **Scope** is a short noun in parentheses if it helps (e.g. `fix(api): …`).
- [ ] Breaking changes are explicit (`!` and/or `BREAKING CHANGE:` in the body/footer).
- [ ] Description is imperative, lowercase start after the prefix, no trailing period in the title line.

## When not to invent a bump

If the repo uses a custom `@semantic-release/commit-analyzer` preset, note that your bump is **heuristic** and they should match `.releaserc` / `release.config.*`. See [REFERENCE.md](REFERENCE.md#custom-repositories).

## Further reading

- [REFERENCE.md](REFERENCE.md) — Message shape, footers, release mapping, squashing notes.

---

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

## Release type from commits

The table below matches the **idea** used by [semantic-release](https://github.com/semantic-release/semantic-release) with typical **Conventional Commits** / Angular-style presets (e.g. [danielvm-git/semantic-release-baby](https://github.com/danielvm-git/semantic-release-baby) fork of semantic-release, which documents the same commit rules). Exact behavior is **plugin + preset** dependent.

| Commit pattern | Typical release |
|----------------|-----------------|
| `fix:` or patches bug behavior | **Patch** |
| `feat:` | **Minor** |
| `BREAKING CHANGE:` in footer, or `!` after type/scope | **Major** |
| `perf:` (no breaking) | Often **patch** in default angular preset |
| `docs:`, `chore:`, `ci:`, `style:`, `test:` | Often **no** version bump for library consumers — many teams still ship these without semver bump, or use a project-specific rule |

**Major without `feat`:** any type can be major if the footer documents a breaking change.

## Custom repositories

- Read `release.config.js`, `.releaserc`, or `package.json` → `release` / `semantic-release` config.
- The **@semantic-release/commit-analyzer** preset may map types differently; prefer **their** rules when they conflict with this reference.

## Squash and PR titles

- If the team squashes on merge, the **PR title** often becomes the single squashed commit subject — it should still follow `type(scope): description` for tooling.
- `revert:` type and `Refs:` footers are valid patterns; revert handling varies by [tooling](https://www.conventionalcommits.org/en/v1.0.0/#specification).

## Links

- [Conventional Commits — specification](https://www.conventionalcommits.org/en/v1.0.0/#specification)
- [semantic-release — README (commit format & flow)](https://github.com/semantic-release/semantic-release#commit-message-format)
- Fork pointer: [semantic-release-baby](https://github.com/danielvm-git/semantic-release-baby) (automation and docs align with upstream semantic-release)
