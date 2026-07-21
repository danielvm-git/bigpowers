<!-- wayfinder resolution artifact — T12 (story-template), closed -->
<!-- THIN WRAPPER, not a duplicate. The 20 sections + maturity rubric + hard rules stay
     single-sourced in docs/countable-story-format.md — copy that file's section content
     below the header shown here, unchanged. This artifact shows only the reconciliation:
     how the existing, already-mandatory countable-story format takes T1's OKF envelope,
     following T5's exemplar (frontmatter + human-readable body header, light intentional
     redundancy between them). Per bigspec's own architecture.md diagnosis: "the countable-
     story 'counter' is just the validator for okf_kind: story" — the format doesn't change,
     it gets wrapped. -->

---
okf_kind: story
okf_version: "1.0"
generated_by: "{skill:elaborate-spec | skill:plan-work | human}"
generated_at: {YYYY-MM-DDTHH:MM:SSZ}
supersedes: {filepath | null}
commit_range: {string | null}
---

```
STORY KEY: {PROJECT-NNN}
TITLE:     {short imperative title}
TYPE:      Story | Spike | Bug | Enabler
PARENT:    {epic key or N/A}
STATUS:    Draft | Ready for refinement | Refined | Counted | In sprint
AUTHOR:    {name}           DATE: {YYYY-MM-DD}
MATURITY:  {self-score 1-5}
SIZE:      {XS | S | M | L | XL}   (Fibonacci 1/2/3/5/8)
```

<!-- SIZE RULING (T12): this is a coarse, PRE-COUNT Fibonacci T-shirt estimate for sprint-commit
     gating — it is NEVER the computed BCP total. The actual BCP total is derived independently
     by count-bcp / the Element Router from the sections below, and is never hand-stamped here.
     Writing a BCP number into this header, or letting SIZE anchor the eventual count, violates
     constitution B9. SIZE and BCP are different instruments at different points in time. -->

{Copy the 20 sections verbatim from docs/countable-story-format.md below this line, including
the maturity rubric, the [draft]/[reviewed]/[locked] per-section tags, and the NFR tags on
§14-16. That file is the single source for section content — this wrapper does not restate it.}
