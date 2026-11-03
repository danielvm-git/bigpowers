# story: e84s01
# Skill Naming — Conventions and Exceptions

All skill directories under `skills/` use a two-word `verb-noun` kebab-case pair (ADR-0001). Grep for any skill name must return < 5 results across the repo.

## Documented Exceptions

Adjective-noun retained for clarity; renaming would reduce usability:

| Skill | Convention deviation | Rationale |
|-------|----------------------|-----------|
| `terse-mode` | adjective-noun | `enable-terse` implies a toggle; `terse-mode` names a mode state |
| `visual-dashboard` | adjective-noun | `view-dashboard` implies read-only; `show-dashboard` collides with `show` verbs |
| `deploy` | single verb | Well-known DevOps single-word concept; renames like `deploy-app` or `deploy-service` are redundant since deploy always targets an application |
| `grill-with-docs` | three-word verb-prep-noun | Variant of `grill-me`; the `-with-docs` suffix is the distinguishing feature — collapsing it would hide the doc-grounded contract |
| `generate-allure-report` | three-word verb-noun-noun | `generate-report` is ambiguous across report types; `allure` names the specific output format consumers integrate with |
| `simple-english` | adjective-noun | Names the recognizable STE brand users search for (`simplify-english` / `write-plain` hide intent and break searchability for users coming from the upstream skill) |

Any new exception requires an entry in this table before the skill is published.
