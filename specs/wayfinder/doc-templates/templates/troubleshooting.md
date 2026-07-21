<!-- wayfinder resolution artifact — T11 (troubleshooting-vs-bug-rca), closed -->
<!-- ON THE SHELF: optional, same treatment as release-notes.md. Most bugs never get an entry
     here — only ones that manifest as a symptom an end user (not a contributor) can hit.
     This is NOT a public-facing copy of BUG-*.md — it translates, it doesn't restate. The
     bug's internal RCA (code paths, TDD plan, tests) stays in the BUG-*.md record; this file
     holds only what a user needs: what they're seeing, why, and what to do. -->
<!-- Composed from: big-docs/docs/troubleshooting/template_troubleshooting.md (TGDP). -->
<!-- {curly braces} mark fill-in points, following TGDP convention. -->

# Troubleshooting — {Project Name}

{1-2 sentences: what this guide covers — the full project, or a specific feature/task.}

## {Symptom — the error text or observed behavior, verbatim if there's an error message}

### Cause

{Explain the cause. If there's more than one possible cause for this symptom, repeat this
Cause/Solution pair for each — don't merge unrelated causes into one explanation.}

### Solution

{What to do. Steps if needed. State what success looks like — how the user knows it's fixed.}

---

{Repeat the Symptom/Cause/Solution block above for each known, recurring issue.}

## For more information

{Links to related docs, the source bug record for provenance, or upstream issues.}

- [{Link text}]({url})
