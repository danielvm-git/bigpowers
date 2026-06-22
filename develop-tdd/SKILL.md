---
name: develop-tdd
model: sonnet
description: Test-driven development with red-green-refactor loop using vertical slices. Use for features (epic tasks) or bugs (specs/bugs/BUG-*.md).
---

# Develop TDD

> **HARD GATE** — Do NOT proceed if on `main` or `master`. Run `kickoff-branch` first to create a feature branch or worktree.
>
> **HARD GATE** — Do NOT write code before you have a plan. New feature: `plan-work` → epic capsule tasks. Bug: `investigate-bug` → `specs/bugs/BUG-*.md` (or use `fix-bug` orchestrator).
>
> **RECURSIVE DISCIPLINE** — This lifecycle applies to EVERY task, including updating these skills. Never skip planning because a task is "meta" or "just documentation."

## Philosophy

Tests verify behavior through public interfaces, not implementation details. A good test reads like a specification. See [REFERENCE.md](REFERENCE.md) for the horizontal-slice anti-pattern and TDD phase detail.

## Red Flags

If you catch yourself thinking these, stop and reconsider — you are likely deviating from production-grade craft.

| Red Flag | Reality |
| :--- | :--- |
| "This is too simple to need tests." | Simple code is where bugs hide. If it's simple, the test is cheap. |
| "I'll refactor this later." | "Later" is when technical debt becomes bankruptcy. Refactor while Green. |
| "The tests are already comprehensive." | If you're adding behavior, you need a new test. Coverage ≠ Correctness. |
| "I'm just fixing a small bug." | Small bugs often indicate deep interface flaws. Investigate root cause. |
| "I need to mock this internal class." | Mocking internals couples tests to implementation. Mock only I/O. |
| "This refactor is out of scope." | Leave the code cleaner than you found it (Boy Scout Rule). |

## Workflow

> **Timing:** `bash scripts/bp-timing.sh start develop-tdd` at invocation; `bash scripts/bp-timing.sh end develop-tdd` before handoff.

### 1. Planning

- [ ] Read active `specs/epics/*/epic.yaml` story tasks or `specs/bugs/BUG-*.md` — understand verify steps
- [ ] Confirm interface changes and behaviors to test (prioritize)
- [ ] Design interfaces for testability — identify [deep modules](deep-modules.md) opportunities
- [ ] Get user approval on the plan

Apply the **enforce-first** F.I.R.S.T rubric: Fast, Independent, Repeatable, Self-Validating, Timely.

### 2. Tracer Bullet

Write ONE test that confirms ONE thing about the system:

```
RED:    Write test for first behavior → test fails → commit: test(<scope>): ...
GREEN:  Write minimal code to pass → test passes → commit: feat(<scope>): ...
REFACTOR (optional): clean up → commit: refactor(<scope>): ...
```

### 3. Incremental Loop

> **STREAM CONTINUITY** — When writing file content, output in continuous chunks of ~200 lines. Do not pause. Emit a placeholder comment rather than going silent.

For each remaining behavior: RED → GREEN → REFACTOR (optional). One test at a time. Commit after every GREEN phase.

### 4. Visual Slices (UI alternate workflow)

For UI components where behavioral unit testing is brittle: extract logic into a Controller/ViewModel/Hook (pure TDD), then use Visual Slices for the View layer. See [REFERENCE.md](REFERENCE.md) for the full Visual Slices procedure.

### 5. Refactor

After all tests pass: extract duplication, deepen modules, apply SOLID principles. **Never refactor while RED.**

### 6. Verify

After every behavior cycle, run the verify command from the active epic task. Show evidence before declaring the step done.

### 6a. CI dry-run sub-step (when modifying workflows)

If this cycle modified files in `.github/workflows/`, run a CI dry-run before pushing:

```bash
# 1. Check for workflow file changes
CHANGED_WORKFLOWS=$(git diff --name-only HEAD | grep '\.github/workflows/' || true)
if [ -n "$CHANGED_WORKFLOWS" ]; then
  echo "==> CI dry-run: workflow files changed"
  echo "    $CHANGED_WORKFLOWS"

  # 2. Validate YAML syntax
  if command -v yamllint &>/dev/null; then
    for f in $CHANGED_WORKFLOWS; do
      yamllint "$f" && echo "  OK: $f passes YAML lint" || echo "  WARN: $f has YAML issues"
    done
  else
    # Fallback: Python YAML parse
    for f in $CHANGED_WORKFLOWS; do
      python3 -c "import yaml; yaml.safe_load(open('$f'))" 2>/dev/null && \
        echo "  OK: $f YAML syntax valid" || \
        echo "  FAIL: $f has YAML syntax errors"
    done
  fi

  # 3. Run actionlint if available
  if command -v actionlint &>/dev/null; then
    for f in $CHANGED_WORKFLOWS; do
      actionlint "$f" && echo "  OK: $f passes actionlint" || echo "  WARN: $f has actionlint issues"
    done
  fi

  # 4. Check common pitfalls
  for f in $CHANGED_WORKFLOWS; do
    # Missing permissions block
    if ! grep -q 'permissions:' "$f"; then
      echo "  WARNING: $f missing permissions block — add one for security"
    fi
    # npm publish without NPM_TOKEN
    if grep -q 'npm publish\|npx semantic-release' "$f" && ! grep -q 'NPM_TOKEN' "$f"; then
      echo "  WARNING: $f has npm publish/semantic-release but no NPM_TOKEN in secrets"
    fi
    # Hardcoded Node versions
    if grep -q 'node-version: [0-9]' "$f"; then
      echo "  NOTE: $f has hardcoded Node version — consider node-version-file: .nvmrc"
    fi
  done

  # 5. Suggest local dry-run
  if command -v act &>/dev/null; then
    echo "  SUGGESTION: Run 'act push --dry-run' to test workflows locally"
  fi
fi
```

Checklist:
- [ ] YAML syntax validated for all changed workflow files
- [ ] No missing permissions, secrets, or hardcoded versions flagged
- [ ] Local dry-run suggested if `act` is available

### 7. Manual Verification Handover

Once all tests pass: locate the Verification Script in the active epic capsule, present it to the user step-by-step, and wait for confirmation of behavioral correctness.

## Checklist Per Cycle

```
[ ] Test describes behavior, not implementation
[ ] No test is ignored without an explicit ambiguity note (T4)
[ ] Boundary conditions tested: empty, max, min, off-by-one (T5)
[ ] Tests verify behavior through public interface only — no private methods (T8)
[ ] Test would survive internal refactor
[ ] Code is minimal for this test
[ ] No speculative features added
[ ] Every new abstraction has an explicit "Reason for Depth" justification
[ ] Progress committed (Conventional Commits)
[ ] verify: command passes
```

## --config mode

For pure-config tasks (update package.json, edit YAML, tweak manifest) where there is no test infrastructure to write against. The RED state is "verify command fails"; GREEN is "verify command passes."

**When to use:** task has a runnable `verify:` command and the deliverable is a config file change with no new behavior to unit-test. Invoke as `develop-tdd --config`.

**Cycle:**

```
RED:    Run verify command → it fails (expected)
GREEN:  Apply config change → verify passes
COMMIT: commit: chore(<scope>): <change>
```

**Rules:**
- Skips test-writing phase entirely — do NOT write a test file for config tasks.
- `verify:` command is **required** and must be runnable (no placeholder).
- Commit message follows Conventional Commits (`chore:` or `feat:` as appropriate).
- Still runs full `verify-work` after all tasks complete.

## Handoff

Gate: READY -> next: verify-work
Writes: state.yaml handoff.next_skill = verify-work
