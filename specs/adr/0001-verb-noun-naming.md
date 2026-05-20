# ADR-0001: Verb-Noun Skill Naming

**Status:** Accepted
**Date:** 2026-05-18

## Context

Skills need names that are memorable, discoverable by agents scanning a directory, and unambiguous
when grep'd. Early naming (single nouns like `tdd`, `review`) caused collisions and unclear intent.

## Decision

All skill directories use a two-word `verb-noun` kebab-case pair (e.g., `develop-tdd`,
`audit-code`, `plan-work`). Exceptions (meta-skills, mode toggles) must be documented in
`CONVENTIONS.md` — they are not silent deviations.

## Consequences

- A global `grep` for any skill name returns < 5 results (grep-ability mandate, Akita #3).
- Skills self-document their intent: `investigate-bug` is unambiguous; `debug` is not.
- Two-word constraint prevents sprawl — a skill that needs three words is probably two skills.
- `terse-mode` and `visual-dashboard` are named exceptions (adjective-noun); noted in CONVENTIONS.md.
