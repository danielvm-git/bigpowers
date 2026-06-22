# Conventions

## Conventional Commits & Semantic Versioning

All changes to this repository MUST follow the [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) specification. Versioning MUST strictly adhere to [Semantic Versioning 2.0.0](https://semver.org/).

### Commit Message Format
`<type>(<scope>): <description>` (Space after colon is MANDATORY)

### Types & Version Bumps
- `feat`: Minor (x.Y.z) - New feature
- `fix`: Patch (x.y.Z) - Bug fix
- `perf`: Patch (x.y.Z) - Performance improvement
- `docs`, `chore`, `style`, `refactor`, `test`: No bump (unless breaking)
- `BREAKING CHANGE:` (or `!` after type): Major (X.y.z)

## GitHub & Git Operations

- No direct work on `main` or `master`. Every task MUST start with a feature branch or worktree via `kickoff-branch`.
- **Integrate (team default):** Use `gh pr create` and `gh pr merge --squash` via `release-branch` (team-pr mode). Prefer `gh` over ad-hoc `git push` + manual PR UI.
- **Integrate (solo profile):** When `profiles/solo-git.md` or `specs/WORKFLOW-solo-git.md` is active, ship with `bash scripts/land-branch.sh <branch> "<conventional message>"` after `release-branch` gates — local squash to `main`, then push. PR is optional (remote CI / branch protection only).
- `git push origin <feature-branch>` is allowed for backup or CI; never push directly to `main`/`master` except via `land-branch.sh` (`GIT_BIGPOWERS_LAND=1`).
- Use `gh repo clone` not `git clone` for GitHub repos
- Use `gh run view` / `gh run watch` for CI status
- Verify auth with `gh auth status` before operations
- **Git Attribution:** NEVER include `Co-authored-by`, `Co-Authored-By`, or any other footer that attributes code to an AI agent (e.g., Claude, Gemini). All commits must appear as if they were authored solely by the human user.
- **State Commit Policy:** To minimize git history noise, intermediate `chore(state):` commits (e.g., tracking build-epic step transitions) should either be squashed locally using the `--squash-state` flag on `release-branch` before merging, or kept out-of-band using local cycle-state files.
- Never call GitHub REST API directly (curl, fetch, etc.)
- Never create GitHub issues from automated workflows — produce local .md files in specs/ instead

## Agent Workflow Mandates

**AGENTS MUST NEVER BYPASS THE BIGPOWERS WORKFLOW.**
You are operating within the `bigpowers` spec-driven development methodology.
- **No Direct Coding:** When a user issues a directive like "build feature X" or "go epic 10", you MUST NOT execute the request by writing code directly.
- **Required Skills:** You MUST route all work through the appropriate bigpowers skills.
  - Start with `survey-context` if you lack context.
  - Use `plan-work` to flesh out tasks in `specs/epics/eNN-*.yaml` (with `verify:` per task) before writing any feature code.
  - Use `develop-tdd` or `execute-plan` to implement the plan.
  - Use `investigate-bug` for bug reports before writing a fix.
- **Verification Mandate:** Every story implementation MUST end with a step-by-step manual verification script provided to the user. You must wait for the user to confirm behavioral correctness (UAT) before declaring the story done or moving to the next.
- **Verification:** You MUST verify every change with tests. Code generation without a corresponding plan in `specs/` is strictly forbidden.
- **Stream Continuity:** When writing large files or long documents, you MUST output continuously in chunks of ~200 lines. Do not pause between sections. Continue immediately until complete. If you need time to process, emit a placeholder comment or heading rather than going silent to prevent stream idle timeouts.

## specs/ — All Planning Output Goes Here

Every skill that produces written output writes to `specs/` at the project root.

### YAML cockpit (runtime + delivery)

| Layer | File | Answers |
|-------|------|---------|
| Session | `specs/state.yaml` | Active flow, epic/bug, ship-epic step, git, `handoff.next_skill`, `metrics.story_start` |
| Release index | `specs/release-plan.yaml` | Target semver, WSJF epic list, BCP baseline per story |
| Progress | `specs/execution-status.yaml` | Flat status keys (`e01`, `e01s01`) — sole SoT for story state |
| Cycle-time ledger | `specs/metrics/cycle-times.yaml` | Per-story: BCPs, start, end, cycle minutes, BCP/hr **(v2.0.0)** |
| Planning UI | `specs/planning-status.yaml` | Discover-phase workflow checklist (optional) |

**Do not** put story status in `release-plan.yaml`. **Do not** duplicate the release plan inside `state.yaml`.

### BCP accounting mandate (v2.0.0)

**BCP = Business Complexity Points** — a pre-build story size, not a per-task annotation. Canonical method: [`docs/references/bcp.md`](docs/references/bcp.md) (sourced from `flow-ciandt/bcp-agent`).

- **Sizing (plan-release):** Every story in `specs/release-plan.yaml` MUST have a `bcps:` field set via the 6-step BCP sizing method before implementation begins. No story enters the build queue without a BCP baseline.
- **Session state:** `plan-work` confirms the BCP size and writes it to `specs/state.yaml` as `epic_cycle.story_bcps`.
- **Velocity (release-branch):** After landing, `release-branch` appends a row to `specs/metrics/cycle-times.yaml` with `bcp_per_hour = story_bcps / cycle_minutes * 60`.

BCP is a **story-level** size. Per-task `[BCP N]` annotations are not part of the canonical method.

### Timestamp mandate (v2.0.0)

- `survey-context` MUST write `metrics.story_start` (ISO 8601) to `specs/state.yaml` at the start of every story.
- `release-branch` MUST write `metrics.story_end`, `metrics.cycle_minutes`, and `metrics.bcp_per_hour` to `specs/state.yaml` and append a row to `specs/metrics/cycle-times.yaml` when the story lands.

Missing timestamps are a gate violation — do not advance past `release-branch` without them.

### next_skill signaling mandate (v2.0.0)

Every critical-path skill (survey-context, plan-work, kickoff-branch, develop-tdd, verify-work, audit-code, commit-message, release-branch) MUST write `handoff.next_skill` to `specs/state.yaml` as its last action. Agents MUST read `state.yaml` and follow `handoff.next_skill` before asking "what comes next?".

### Intent vs delivery vs execution

| Question | File | Format |
|----------|------|--------|
| What should the product do? | `specs/product/SCOPE_LATEST.yaml` | YAML |
| North star / initiative | `specs/product/VISION_LATEST.yaml` | YAML |
| Glossary | `specs/product/GLOSSARY_LATEST.yaml` | YAML |
| What ships in this release, in what order? | `specs/release-plan.yaml` | YAML |
| How to implement an epic/story? | `specs/epics/eNN-*.yaml` or `specs/epics/eNN-*/stories/` | YAML + MD |
| Where are we in the session? | `specs/state.yaml` | YAML |

Epic IDs: `e01`, `e30`. Story IDs: `e01s01`. One FR in SCOPE may span multiple epics or releases.

### Frozen release (ex-baseline)

When planning closes, copy to `specs/product/snapshots/release-<version>/` (`release-plan.yaml`, `SCOPE_LATEST.yaml`, `VISION_LATEST.yaml`). No separate `baselines/` folder.

### Semantic-release — three places

1. **Planning intent** — `specs/release-plan.yaml` → `release.version`, `release.bump_hint` (minor/patch/major expectation).
2. **Published version** — repo root: `package.json`, git tag `vX.Y.Z`, `CHANGELOG.md` (CI semantic-release; not hand-edited in specs).
3. **Dashboard optional** — `specs/state.yaml` → `release.last_tag`, `release.last_publish` (from tags/CI).

### Guardrails and other artifacts

| Document | Path |
|----------|------|
| Stack / architecture | `specs/tech-architecture/TECH_STACK_LATEST.md` |
| Security / test / design plans | `specs/tech-architecture/*_PLAN_LATEST.md` |
| Domain context + ADRs | `specs/tech-architecture/TECH_STACK_LATEST.md` or legacy `specs/CONTEXT.md` + `specs/adr/` |
| Bug investigation | `specs/bugs/BUG-*.md` + `specs/bugs/registry.yaml` (generated) |
| Refactor / impact | `specs/tech-architecture/REFACTOR_LATEST.md`, `specs/tech-architecture/IMPACT_LATEST.md` |
| Legacy markdown | `specs/archive/` after `bash scripts/convert-legado.sh` |

Validate YAML layout: `bash scripts/validate-specs-yaml.sh`. Patch runtime keys: `bash scripts/bp-yaml-set.sh specs/state.yaml git.branch feat/foo`.

### Legacy paths (migrate away)

| Old | New |
|-----|-----|
| `specs/STATE.md` | `specs/state.yaml` |
| `specs/RELEASE-PLAN.md` | `specs/release-plan.yaml` + `specs/epics/` |
| `specs/SCOPE.md` | `specs/product/SCOPE_LATEST.yaml` |

## Code Style

- Functions: 4–20 lines. Split if longer.
- Files: under 300 lines. Split by responsibility to ensure content fits within a single agent context window.
- One thing per function, one responsibility per module (SRP).
- Names: specific and unique. Avoid `data`, `handler`, `Manager`, `Service`. Prefer names whose grep returns < 5 hits in this codebase.
- Types: explicit. No `any`, no untyped public functions.
- No code duplication. Extract shared logic into a function/module.
- Early returns over nested ifs. Max 2 levels of indentation.
- Conditionals: expressed as positives (G29). Avoid negative flags or `unless` logic where possible.
- The Stepdown Rule (G34): functions should descend exactly one level of abstraction.
- Names describe side-effects (N7): if a function sends email, writes to disk, or mutates state, the name must say so (`sendWelcomeEmail`, not `processUser`).
- No magic strings or numbers (G25): every bare string literal or numeric literal used in logic must be extracted to a named constant.
- Boolean logic in named functions (G28): complex boolean expressions must be extracted into a named predicate function, not inlined.
- Prefer exceptions over error codes: throw/raise an exception rather than returning a numeric or boolean error sentinel.
- Remove dead code (G9/F4): unused functions, unreachable branches, and stale imports must be deleted — not commented out.
- Boy Scout Rule: leave every file you touch at least as clean as you found it. Fix the first broken window you see.
- **Law of Demeter:** A method should call only its immediate collaborators — not `a.getB().getC().doX()`. Chain violations need explicit justification in code review.
- **Verification mandate:** Every story must include runnable `verify:` commands (in epic shards or story files). No story is done until `verify-work` confirms it (or user explicitly waives with documented reason in `specs/state.yaml` handoff).
- Exception messages must include the offending value, expected shape, and an actionable remediation hint for the agent.
- SOLID beyond SRP: favor interfaces over concrete types (DIP) when injecting dependencies.

## Comments

- Keep your own comments. Never strip them on refactor — they carry intent and provenance.
- Write WHY, not WHAT.
- Complex or non-obvious logic must include "Provenance" links (e.g., Jira issue, GitHub commit SHA, or ADR filename).
- Docstrings on public functions: intent + one usage example.
- Reference issue numbers / commit SHAs when a line exists because of a specific bug.
- No obvious comments that restate the code.
- No commented-out code (C5): dead code must be deleted, not commented out. Use git history to recover it.

## Tests (F.I.R.S.T — Uncle Bob Ch 9)

- Tests run headless with a single command (recorded in CLAUDE.md).
- Every new function gets a test. Every bug fix gets a regression test.
- Mocks for external I/O are named fake classes, not inline stubs.
- Tests are **F**ast, **I**ndependent, **R**epeatable, **S**elf-Validating, **T**imely.
- Never skip or @ignore a test without an explicit ambiguity note explaining what is unresolved (T4); silently ignored tests are prohibited.
- Test boundary conditions (T5): every suite must cover exact edge values — empty input, maximum, minimum, and off-by-one.
- Test through public interfaces only (T8): assert on observable outcomes (return values, API responses, UI state). Never assert on internal state or private methods.
- Every change must be verifiable with a single runnable command before it is marked done.

## Dependencies

- Inject dependencies through constructor/parameter, not global/import.
- Wrap third-party libs behind a thin project-owned interface.

## Structure

- Follow the framework convention (Rails, Django, Next.js, etc.).
- Predictable paths: controller/model/view, src/lib/test.
- Prefer small focused modules over god files.

## Formatting

- Use the language default formatter (cargo fmt, gofmt, prettier, black, rubocop -A).
- Configured in pre-commit and on-save. No style debates beyond that.

## Logging

- Structured JSON for debugging / observability.
- Plain text only for user-facing CLI output.

## Defensive Code

- Retry with backoff (for API/network calls in skill implementations)
- Timeout (for long-running operations)
- Graceful degradation (when external services/dependencies fail)

The agent implements defensive code only for categories explicitly listed here.

## Skill Naming — Conventions and Exceptions

All skill directories use a two-word `verb-noun` kebab-case pair (ADR-0001). Grep for any skill
name must return < 5 results across the repo.

**Documented exceptions** (adjective-noun retained for clarity; renaming would reduce usability):

| Skill | Convention deviation | Rationale |
|-------|----------------------|-----------|
| `terse-mode` | adjective-noun | `enable-terse` implies a toggle; `terse-mode` names a mode state |
| `visual-dashboard` | adjective-noun | `view-dashboard` implies read-only; `show-dashboard` collides with `show` verbs |
| `deploy` | single verb | Well-known DevOps single-word concept; renames like `deploy-app` or `deploy-service` are redundant since deploy always targets an application |

Any new exception requires an entry in this table before the skill is published.
