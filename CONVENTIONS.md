# story: e05s01 e46s04
# story: e06s02
# story: e07s01
# story: e30s02
# story: e30s03
# story: e38s08
# story: e45s10
# story: e51s01
# story: e45s25
# story: e45s36
# story: e27s01
# story: e29s03

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

### Pre-Merge Verification Gates

Before merging any branch, run the deterministic verification gates:

```bash
bash scripts/run-verification-gates.sh
```

This runs compliance → G-04 self-test. If any gate fails, the merge is blocked.
Pin a fresh baseline with `--baseline` after major structure changes.

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
- **Traceability Mandate:** Every story MUST have at least one `story: eNNsNN` tag in its implementing code or test file. `trace-stories.sh --strict` runs in CI to enforce this. Untagged stories fail the CI traceability gate.
- **Scenario ID Format (e46s04+):** When a `specs/tech-architecture/eNN-TEST_PLAN_LATEST.md` exists for the epic, critical-path scenarios use the format `SC-eNNsYY-P{0|1|2|3}-NN` (e.g. `SC-e46s04-P0-01`). These IDs are referenced inside test files as `// scenario: SC-eNNsYY-P0-NN` comments alongside the existing `// story: eNNsNN` tag. SC gaps detected via check-blind-spots.sh; no separate SC tracing script required. gate-trace treats a P0 story with zero `SC-*-P0-*` references in test files as a CONCERNS finding (waivable via `state.yaml`). P2/P3 epics may set `test_plan: waived` in `state.yaml` to skip the `plan-tests` skill.
- **Stream Continuity:** When writing large files or long documents, you MUST output continuously in chunks of ~200 lines. Do not pause between sections. Continue immediately until complete. If you need time to process, emit a placeholder comment or heading rather than going silent to prevent stream idle timeouts.

## Always Green / Shift Left

Solo developers own the whole codebase. **Always Green** means Preflight and CI are green before any forward work — not "green enough for this task."

**Shift Left (1-10-100):** Defects cost roughly 1× to fix in development, 10× in integration, 100× in production (IBM Systems Sciences Institute; CloudQA benchmarks). Fixing a red gate now is cheaper than shipping and debugging later.

**Preflight** — the project's full local verification stack (chained from test, lint, typecheck, and build commands recorded in `CLAUDE.md`). Preflight MUST pass before kickoff, develop, or verify phases advance.

**CI green** — when a PR exists or remote CI applies, `gh pr checks` (or equivalent) MUST show passing before merge or land.

**Existing projects:** Projects seeded before e51 do not receive these sections automatically. Re-run `seed-conventions` and merge the Always Green blocks, or copy § Always Green and § Discovered Defects from bigpowers `CONVENTIONS.md` manually.

## Discovered Defects

Any **reproducible gate failure** encountered during unrelated work is a discovered defect — not optional background noise.

**fix-or-log ladder (mandatory):**

1. **quick-fix** — trivial, data-only, or single-file fixes within guardrails.
2. **fix-bug** — when quick-fix guardrails abort, or the failure needs investigation (`specs/bugs/BUG-*.md` + TDD).
3. **Log** — only when reproduction is blocked after good-faith attempt; write a BUG spec and stop forward work on the original task until triaged.

Discovered fixes ship in the **same PR** as the original work but in **separate commits** (Conventional Commits). Never narrate a failure and continue.

**Hard block:** Red Preflight or red CI blocks kickoff-branch, develop-tdd, and verify-work forward progress until fix-or-log produces green.

## Risk Tiers (Effective Rule Matrix)

Human-readable source of truth for verification depth. Machine-readable compile:

```bash
bash scripts/compile-rule-matrix.sh   # → specs/rule-matrix.json
```

Diff `specs/rule-matrix.json` across git tags to audit rule drift. Schema version in JSON `matrix_version` field.

### P0 — Critical (never violate)

- **[always-green]**: Preflight and CI must be green before forward work. (`verify-work`, `kickoff-branch`, `develop-tdd`)
- **[no-direct-coding]**: Route feature work through bigpowers skills — no ad-hoc implementation without a plan in `specs/`. (`plan-work`, `orchestrate-project`)
- **[traceability]**: Every story has ≥1 `story: eNNsNN` tag in implementing code or tests. (`trace-stories.sh --strict`)
- **[no-generated-edits]**: Never edit `.cursor/rules/`, `.gemini/`, or `website/src/content/docs/` directly. (`sync-skills.sh`)

### P1 — High (fix before merge)

- **[conventional-commits]**: All commits follow Conventional Commits; semantic-release owns version bumps. (`commit-message`, `release-branch`)
- **[verify-per-story]**: Every story/task has runnable `verify:` commands; `verify-work` confirms before done. (`plan-work`, `verify-work`)
- **[test-on-change]**: New functions and bug fixes include tests; regressions get regression tests. (`develop-tdd`, `validate-fix`)
- **[branch-protection]**: No direct work on `main`/`master`; feature branches via `kickoff-branch`. (`guard-git`)

### P2 — Medium (address in same epic or next)

- **[plan-tests-waiver]**: P2/P3-dominant epics may set `test_plan: waived` in `state.yaml`. (`plan-tests`)
- **[file-size-cap]**: Source files under 300 lines unless listed in § File-Size Exceptions. (`audit-code`)
- **[handoff-signaling]**: Critical-path skills write `handoff.next_skill` to `state.yaml`. (`session-state`)
- **[delta-requirements]**: Behavior changes require `ADDED`/`MODIFIED`/`REMOVED`/`RENAMED` tags in requirement specs. (`plan-work`, `change-request`)

### P3 — Low (best effort)

- **[boy-scout]**: Leave touched files at least as clean as found. (`audit-code`)
- **[terse-when-heavy]**: Switch to `terse-mode` when context exceeds ~20 turns. (`terse-mode`)
- **[skill-naming]**: Verb-noun kebab-case under `skills/`; documented exceptions only. (`craft-skill`)

### Banned dismissive phrases

Agents MUST NOT use these phrases (or close paraphrases) to ignore reproducible failures:

| Banned phrase | Required behavior instead |
|---------------|---------------------------|
| Pre-existing / pre-existing issues | Run fix-or-log; if truly unrelated, prove with a passing repro after revert |
| unrelated to this session | Same — session boundaries do not waive green gates |
| not introduced by my changes | Bisect or fix anyway; solo-default owns the whole tree |
| out of scope (ignoring a red gate) | Invoke quick-fix or fix-bug; scope-minimization never overrides Always Green |

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

Every critical-path skill (survey-context, plan-tests, plan-work, kickoff-branch, develop-tdd, verify-work, audit-code, commit-message, release-branch) MUST write `handoff.next_skill` to `specs/state.yaml` as its last action. Agents MUST read `state.yaml` and follow `handoff.next_skill` before asking "what comes next?".

`plan-tests` is an optional planning-spine step: after `slice-tasks`, before `plan-work`, for epics whose stories carry `risk: P0|P1`. It is skipped (set `test_plan: waived` in `state.yaml`) for P2/P3-dominant epics.

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

### Semantic-release — the real version is never hand-tracked

> **The authority is `gh release view` / git tags.** semantic-release decides the version
> at merge from Conventional Commits. Never hand-maintain a `target_version` to "predict" it —
> that field drifts from reality every release. The specs only *mirror* the real tag for reference.

1. **Planning intent (codename only)** — `specs/release-plan.yaml` → `release.version`, `release.bump_hint`.
   Treat `version` as a non-authoritative label; if you write a number, mark it "mirror, not the authority".
2. **Published version (authority)** — repo root `package.json`, git tag `vX.Y.Z`, `CHANGELOG.md` (CI semantic-release; not hand-edited in specs). Read with `gh release view`.
3. **Dashboard mirror** — `specs/state.yaml` → `release.last_tag`, `release.last_publish` (copied from `gh release view`; `target_version` is `null` — not tracked manually).

### Guardrails and other artifacts

| Document | Path |
|----------|------|
| Stack / architecture | `specs/tech-architecture/TECH_STACK_LATEST.md` |
| Security / test / design plans | `specs/tech-architecture/*_PLAN_LATEST.md` |
| Epic test plan (P0/P1 epics) | `specs/tech-architecture/eNN-TEST_PLAN_LATEST.md` — produced by `plan-tests` skill (e46s04); one per epic. |
| Domain context + ADRs | `specs/tech-architecture/TECH_STACK_LATEST.md` or legacy `specs/CONTEXT.md` + `specs/adr/` |
| Bug investigation | `specs/bugs/BUG-*.md` + `specs/bugs/registry.yaml` (generated) |
| Refactor / impact | `specs/tech-architecture/REFACTOR_LATEST.md`, `specs/tech-architecture/IMPACT_LATEST.md` |
| Legacy markdown | `specs/archive/` after `bash scripts/convert-legado.sh` |

Validate YAML layout: `bash scripts/validate-specs-yaml.sh`. Patch runtime keys: `bash scripts/bp-yaml-set.sh specs/state.yaml git.branch feat/foo`.

### Documentation Responsibilities (e45s36)

Each specs/ artifact owns specific facts. Update the owning file when the fact changes — do not duplicate across files.

| File / directory | Owns | Update when |
|------------------|------|-------------|
| `specs/state.yaml` | Active session, handoff, story timing, workflow mode | Every skill handoff; branch switch; story start/end |
| `specs/release-plan.yaml` | Epic ordering, WSJF, BCP baselines, release codename | New epic scoped; WSJF re-prioritized; BCP re-estimated |
| `specs/execution-status.yaml` | Story/epic done/todo status (sole SoT) | Story completes; gate-trace runs; manual status change |
| `specs/product/SCOPE_LATEST.yaml` | In/out of scope, initiative boundaries | scope-work; change-request Add mode |
| `specs/product/VISION_LATEST.yaml` | North star, strategic intent | Major product pivot; scope-work |
| `specs/product/GLOSSARY_LATEST.yaml` | Canonical domain terms | define-language; model-domain term crystallizes |
| `specs/epics/eNN-*/epic.yaml` | Epic manifest, story list, BCPs | slice-tasks; plan-work adds stories |
| `specs/epics/eNN-*/eNNsYY-*.md` | Story requirements (countable-story-format) | plan-work; section approval state changes |
| `specs/epics/eNN-*/eNNsYY-tasks.yaml` | Runnable implementation tasks + verify | plan-work; develop-tdd task completion |
| `specs/tech-architecture/tech-stack.md` | Stack, modules, gray areas | map-codebase; deepen-architecture; model-domain |
| `specs/tech-architecture/eNN-TEST_PLAN_LATEST.md` | P0/P1 test scenarios per epic | plan-tests |
| `specs/adr/ADR-*.md` | Architectural decisions | model-domain; deepen-architecture ADR offer accepted |
| `specs/bugs/BUG-*.md` | Bug RCA + fix plan | investigate-bug |
| `specs/bugs/registry.yaml` | Bug index (generated) | inspect-quality; sync-bugs-registry.sh |
| `specs/verifications/*` | Verify evidence, audit reports, eval reports | verify-work; audit-code; run-evals |
| `specs/security/REVIEW.md` | Latest security scan findings | security-review |
| `specs/metrics/cycle-times.yaml` | Delivery velocity ledger | release-branch lands story |

### Generated artifact targets

Skill content is edited in `skills/*/SKILL.md` and auto-propagated to these targets by `bash scripts/sync-skills.sh`:
- `.cursor/rules/` — Cursor IDE rules
- `.gemini/extensions/bigpowers/` — Gemini CLI extensions
- `.pi/skills/` + `.pi/prompts/` — pi agent
- `website/src/content/docs/` — Docs website (Astro Starlight, deployed to GitHub Pages)

**Never edit any of these targets directly.** Edit the SKILL.md sources and run rebuild scripts (`bash scripts/sync-skills.sh`, `npm run site:build`).

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

All skill directories under `skills/` use a two-word `verb-noun` kebab-case pair (ADR-0001). Grep for any skill
name must return < 5 results across the repo.

**Documented exceptions** (adjective-noun retained for clarity; renaming would reduce usability):

| Skill | Convention deviation | Rationale |
|-------|----------------------|-----------|
| `terse-mode` | adjective-noun | `enable-terse` implies a toggle; `terse-mode` names a mode state |
| `visual-dashboard` | adjective-noun | `view-dashboard` implies read-only; `show-dashboard` collides with `show` verbs |
| `deploy` | single verb | Well-known DevOps single-word concept; renames like `deploy-app` or `deploy-service` are redundant since deploy always targets an application |
| `grill-with-docs` | three-word verb-prep-noun | Variant of `grill-me`; the `-with-docs` suffix is the distinguishing feature — collapsing it would hide the doc-grounded contract |

Any new exception requires an entry in this table before the skill is published.

## Tombstone Aliases (e53s02)

Every skill rename or merge ships a tombstone alias for one release, so consumers
referencing the old name don't break immediately.

**Mechanism:**

1. Run `bash scripts/tombstone-skill.sh <old-name> <new-name-or-merge-target>` when
   renaming or merging a skill. It replaces `skills/<old-name>/SKILL.md` with a stub
   pointing at the new name/location, preserves the old skill's `# story: eNNsNN` tags
   for traceability, and registers the mapping in `specs/tombstones.yaml` (old name,
   new name/target, creation timestamp, and the `bigpowers_version` at creation time).
2. Run `bash scripts/validate-tombstones.sh` to confirm every registered tombstone's
   stub still resolves, and to flag any tombstone whose `created_at_version` differs
   from the current release — that stub has served its one-release transition window
   and should be removed.
3. **Required alongside the first real use of `tombstone-skill.sh`:** update
   `docs/references/model-profiles.md`'s skill-count annotations. A tombstone stub is
   still a `skills/*/SKILL.md` file — it increments the live skill count the same as
   any other skill, and the count doc must reflect that.

**Rejected names:** both the old and new name must be a bare kebab-case skill name
(`^[a-z][a-z0-9-]*$`) — `tombstone-skill.sh` refuses anything else before touching the
filesystem (path segments, absolute paths, etc.).

This story (e53s02) builds the mechanism only; it creates no real tombstone stub
itself, so the live skill count doesn't move yet. The first real use is expected in
e56 (skill reclassification/merges).

## File-Size Exceptions

The 300-line file cap exists to ensure files fit in a single agent context
window. The following files are documented exceptions:

| File | Lines | Rationale | Review date |
|------|-------|-----------|-------------|
| `scripts/audit-compliance.sh` | 300 | Gherkin harness with embedded judge logic and waiver subsystem; splitting the judge loop from the reporting layer would require fragile state-passing. At the 300-line cap; monitor. | 2026-10-01 |

**Note:** `scripts/trace-stories.sh` was refactored from a 613-line monolith into a
69-line orchestrator delegating to `scripts/lib/trace-stories.py`. `scripts/lib/trace-matrix.py`
was split into `simple_yaml.py` + `trace_renderer.py` (252 lines); see
BUG-2026-07-06-gate-trace-matrix-oversized. Prior exception rows for trace-matrix.py
and trace-stories.py are removed — both are now under the 300-line cap.

Any new exception requires an entry in this table with rationale and a review date.

## docs/references SSOT Sync (e45s10)

Agent-guidance files under `docs/references/` are **distilled from upstream sources**, not hand-edited ad hoc. Canonical inputs live in `CLAUDE.md`, `docs/PRINCIPLES.md`, and `skills/*/SKILL.md`.

| Action | Command |
|--------|---------|
| Regenerate locally | `bash scripts/sync-references.sh` |
| Manifest | `scripts/references-manifest.yaml` |
| Scheduled CI | `.github/workflows/sync-references.yml` (weekly) |

After changing SKILL.md `model:` frontmatter or token-management prose in CLAUDE.md, run `sync-references.sh` to refresh reference docs and `.sync-stamp`.
