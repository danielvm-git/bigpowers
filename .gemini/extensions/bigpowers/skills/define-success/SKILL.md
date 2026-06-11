---
name: define-success
description: "Convert an imperative task statement into explicit "step → verify: <cmd>" pairs before implementation begins. Use before plan-work when success criteria are unclear, when a task lacks verifiable checkpoints, or when user says "how will we know this is done?"."
---


# Define Success

Transform "do X" into "step → verify: <cmd>" pairs. This is the pre-flight check before `plan-work` or `develop-tdd` — it makes success observable and removes ambiguity about when you're done.

> **HARD GATE** — Success criteria must be testable and user-observable. "Code should be fast" is not testable. "Pageload latency < 2s" is testable.

## Why this matters

"Implement user authentication" is not a plan. It has no checkpoints, no evidence requirement, and no way to know if you're done. The Karpathy principle: every step must be independently verifiable with a runnable command. If you can't verify it, you can't prove it works.

## Process

### 1. Read the task statement

Take the task as stated (from conversation, or from `specs/epics/ (see slice-tasks)`, or from `specs/requirements/SCOPE_LATEST.yaml`).

### 2. Break into observable outcomes

For each thing the task requires, identify:
- The smallest unit of observable behavior that proves something works
- The command that proves it

Work at the level of behaviors (what the system does) not implementation steps (how you'll write the code).

### 3. Write the pairs

Format each pair as:
```
N. [What must be true] → verify: <runnable command>
```

Examples:

```
Task: "Add user registration to the API"

1. POST /users accepts {email, name} and returns {id, email, name} → verify: curl -s -X POST http://localhost:3000/users -H 'Content-Type: application/json' -d '{"email":"test@test.com","name":"Test"}' | jq .id
2. Duplicate email is rejected with 409 → verify: npm test -- user-registration.test.ts
3. Missing email is rejected with 400 and descriptive error → verify: npm test -- user-validation.test.ts
4. Password is hashed (never stored in plaintext) → verify: npm test -- user-security.test.ts
5. All existing tests still pass → verify: npm test
```

### 4. Challenge completeness

Ask yourself:
- Is there any behavior the task requires that isn't covered by a verify step?
- Is every verify step runnable right now without additional setup?
- Does the final step verify the whole thing end-to-end?

Add any missing pairs.

### 5. Output

Present the pairs to the user and ask: "Does this capture everything the task requires? Anything missing?"

Once confirmed, these pairs become the skeleton for `plan-work`'s steps. Pass them along when calling `plan-work`.
