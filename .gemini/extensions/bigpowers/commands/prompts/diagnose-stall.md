
# story: e45s38


# Diagnose Stall

> **HARD GATE** — Do NOT restart work blindly. Run this diagnostic first when orchestration goes quiet without an explicit terminal state.

Explicit handler for silent stalls in long-running agent workflows (`/loop`, `dispatch-agents`, `execute-plan`, `build-epic` resume mode).

## Stall signals

| Signal | Likely cause |
|--------|----------------|
| No stdout for >5 min on a monitored loop tick | Sleep/watcher misconfigured or prompt never re-armed |
| Subagent dispatched but no completion message | Agent hung, blocked on approval, or scope too large |
| `dispatch-agents` cycle 3 reached with gaps | Circuit exhausted — needs human escalation |
| Verify command running >15 min | Missing timeout or waiting on external service |
| `handoff.next_skill` unchanged across turns | Prior skill never wrote handoff |

## Process

1. **Read state** — `specs/state.yaml`: `handoff.next_skill`, `active_flow`, `metrics.story_start`, open decisions.
2. **Check locks** — `bash scripts/check-stale-locks.sh` if present; read `specs/agent-locks.yaml`.
3. **Inspect terminals** — list background shells; note PIDs, last output timestamp, exit codes.
4. **Classify stall type:**
   - **waiting_approval** — tool blocked on user consent
   - **blocked_dependency** — prior task incomplete or red gate
   - **agent_exhausted** — max iterations/cycles reached
   - **misconfigured_loop** — duplicate sentinel, wrong regex, or sleeper not re-armed
   - **external_io** — network, CI, or deploy wait without timeout
   - **unknown** — escalate with evidence bundle
5. **Recommend recovery** — one action only (resume, kill PID, re-dispatch with smaller brief, escalate to user).
6. **Write report** — `specs/verifications/STALL-<timestamp>.md` with classification, evidence, and recommended next skill.

## Integration

| Caller | When to invoke |
|--------|----------------|
| `/loop` (Cursor) | After two consecutive ticks with no observable progress |
| `dispatch-agents` | When a wave exceeds expected duration with zero returns |
| `execute-plan` | When a step checkpoint is overdue |
| User | "Why did this stop?" / "Nothing is happening" |

## Verify

→ verify: `test -f specs/state.yaml && echo "OK: diagnose-stall can read session state" || echo "WARN: no state.yaml — diagnostic limited"`

## Handoff

Gate: READY → next: survey-context (if state unclear) or resume prior skill from `state.yaml`
Writes: `specs/verifications/STALL-*.md`
