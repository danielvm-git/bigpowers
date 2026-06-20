---
name: commit-message
model: haiku
description: Reviews working-tree changes, then drafts a Conventional Commits title/body and states the semantic-release version bump a single such commit would imply. Also notes which defensive-code categories were touched. Use when the user wants to commit recent work, prepare a Conventional Commits message, or asks for semantic-release / semver-consistent messaging before git commit.
---

# Commit Message
> **HARD GATE** — **HARD GATE** — Commits must follow Conventional Commits spec (type(scope): description). Do NOT use vague messages like 'fix' or 'updates.' The message must explain the 'why,' not the 'what.'


## Modes

- Default: standard Conventional Commits message
- --fix-type: Forces type=fix. Use when commit type is unambiguous.

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
6. **Note fix-ratio contribution** — Each `fix:` commit counts toward `metrics.commit_ratio.fix` in `specs/state.yaml`. After `release-branch`, `session-state` recalculates the ratio automatically. A high fix rate (>30%) triggers a deploy + smoke-test suggestion.
7. **Deliver** — Output:
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

## Handoff

Gate: READY -> next: release-branch
Writes: state.yaml handoff.next_skill = release-branch
