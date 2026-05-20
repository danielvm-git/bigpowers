# ADR-0005: Hard Gate Mandate

**Status:** Accepted
**Date:** 2026-05-20

## Context

Agents rationalise skipping quality checks ("tests are already comprehensive", "this is too simple
to need design"). Without a visible, named stop condition, agents proceed through gates silently.
Prose instructions like "make sure to review" are ignored under time pressure.

## Decision

Every skill that has a critical transition point must include a `> **HARD GATE**` blockquote
immediately before that transition. The blockquote names the condition that must be true before
proceeding and uses a `→ verify:` shell command to make it testable.

```markdown
> **HARD GATE** — Do not proceed until all tests pass.
>
> → verify: `npm test 2>&1 | tail -5`
```

Skipping a HARD GATE requires the agent to name the rationalisation explicitly in `STATE.md`.

## Consequences

- Agents cannot silently skip gates — the skip must be logged.
- Skills are slightly longer (gate blockquotes add 3–5 lines each).
- Hard gates are scannable at a glance — reviewers can audit gate coverage in `audit-code`.
- The `superpowers` benchmark feature passes on this criterion.
