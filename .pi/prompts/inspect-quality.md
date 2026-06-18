---
description: Interactive QA session where user reports bugs or issues conversationally, and the agent logs them to specs/bugs/registry.yaml with a structured audit schema. Explores the codebase in the background for context and domain language. Use when user wants to report bugs, do QA, or mentions "QA session".
---


# Inspect Quality
> **HARD GATE** — **HARD GATE** — Quality metrics (coverage, lint, cyclomatic complexity, security scans) must be monitored. If a metric degrades, surface it as a blocker. Do NOT accept regressions.


Run an interactive QA session. The user describes problems they're encountering. You clarify, explore the codebase for context, and log each issue to `specs/bugs/registry.yaml` with a structured, durable format.

## For each issue the user raises

### 1. Listen and lightly clarify

Let the user describe the problem in their own words. Ask **at most 2–3 short clarifying questions** focused on:

- What they expected vs what actually happened
- Steps to reproduce (if not obvious)
- Whether it's consistent or intermittent

Do NOT over-interview. If the description is clear enough to log, move on.

### 2. Explore the codebase in the background

Kick off an Agent (subagent_type=Explore) to understand the relevant area. The goal is NOT to find a fix — it's to:

- Learn the domain language used in that area (check `specs/UBIQUITOUS_LANGUAGE.md` if present)
- Understand what the feature is supposed to do
- Identify the user-facing behavior boundary

### 3. Assess scope: single issue or breakdown?

Break down when:

- The fix spans multiple independent areas
- There are clearly separable concerns that could be worked on in parallel
- The user describes something with multiple distinct failure modes

Keep as a single issue when:

- It's one behavior that's wrong in one place
- The symptoms are all caused by the same root behavior

### 4. Log to specs/bugs/registry.yaml

Append the issue to `specs/bugs/registry.yaml`. Create the `specs/bugs/` directory if it doesn't exist.

#### registry.yaml format

The file maintains a Markdown table with the following columns (derived from structured audit practice):

| Field | Description |
|-------|-------------|
| `bug_id` | `BUG-YYYY-MM-DDTHHMMSS` |
| `date` | `YYYY-MM-DD` |
| `severity` | `critical` / `high` / `medium` / `low` |
| `priority` | `p0` / `p1` / `p2` / `p3` |
| `scope` | kebab-case area (e.g. `auth`, `checkout`) |
| `what_happened` | actual behavior (user-facing terms) |
| `what_expected` | expected behavior |
| `steps_to_reproduce` | numbered steps |
| `root_cause` | one-line hypothesis |
| `files_changed` | filled in after fix |
| `approach` | filled in after fix |
| `risk_level` | `low` / `medium` / `high` |
| `new_tests` | count (filled in after fix) |
| `type_check` | `pass` / `fail` (filled in after fix) |
| `lint` | `pass` / `fail` (filled in after fix) |
| `commit_type` | `fix` / `fix!` / `feat` (filled in after fix) |
| `release_type` | `patch` / `minor` / `major` (filled in after fix) |
| `commit_message` | Conventional Commits message (filled in after fix) |
| `follow_ups` | semicolon-separated follow-up items |
| `file` | path to detailed `specs/bugs/BUG-*.md` (filled in by investigate-bug) |
| `status` | `open` / `in-progress` / `fixed` / `wont-fix` |

When a bug is fixed (via `validate-fix`), update the relevant row with the resolution fields.

#### Issue body (for context below the table)

For each bug, also append a detail section:

```markdown
### BUG-YYYY-MM-DDTHHMMSS: [short title]

**What happened:** [actual behavior, plain language]
**What I expected:** [expected behavior]
**Steps to reproduce:**
1. [Step 1]
2. [Step 2]

**Additional context:** [domain-language observations, no file paths]
```

#### Rules for all entries

- **bug_id** uses full timestamp: `BUG-YYYY-MM-DDTHHMMSS` — matches the individual bug file name in `specs/bugs/`
- **No file paths or line numbers** — these go stale
- **Use the project's domain language** (check `specs/UBIQUITOUS_LANGUAGE.md` if it exists)
- **Describe behaviors, not code** — "the sync service fails to apply the patch" not "applyPatch() throws"
- **Reproduction steps are mandatory** — if you can't determine them, ask the user

### 5. Continue the session

After logging, ask: "Next issue, or are we done?" Keep going until the user says done. Each issue is independent — don't batch them.
