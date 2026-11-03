# e58s07: Docker sandbox for agent runs and grading

<!-- story: e58s07 -->

```
STORY KEY: e58s07
TITLE:     Run each agent and its grading in a container that cannot see the repo or the internet
TYPE:      Enabler
PARENT:    e58
STATUS:    Refined
AUTHOR:    danielvm-git (planned with claude-opus-5-5)   DATE: 2026-11-02
MATURITY:  4
SIZE:      M (3)
```

Source: runs on the host can read the hidden tests and reference solutions in this repo, write
outside their workdir (a smoke run wrote /tmp/prop.mjs) and reach any website; grading runs
agent-written code on the host. Daytona's default sandbox is a container too, so local Docker
gives the same boundary without an account (see the session notes in e58).

## Requirements

### ADDED

- `scripts/ab-sandbox.sh up|down|status` builds two pinned images and starts the network:
  `bp-ab-agent` (node 24 + git + python3 + pi 1.5.0, non-root) and `bp-ab-proxy` (tinyproxy that
  allows only `opencode.ai`), on an internal Docker network with no route to the internet.
- A `pi-docker` adapter runs pi in a fresh `bp-ab-agent` container per run that mounts only the
  run's workdir and its `$AB_HOME` (with the auth copy), on the internal network through the proxy,
  with CPU, memory and process limits and an in-container `timeout "$AB_TIMEOUT"`.
- An adapter MAY declare `grade_wrapper` (command template with `$AB_CMD`). The runner then runs
  the task's `grade` and `score` commands through it. `pi-docker` grades in a container with
  `--network none`.
- The runner exports `AB_TIMEOUT` = the task's `timeout_s` minus 30 s (at least 10 s), so the
  agent stops inside the container before the runner's own timeout.
- `default_adapter` becomes `pi-docker`. The host `pi` adapter stays for quick local checks.

## Acceptance criteria

```gherkin
Scenario: grade and score go through the adapter's grade_wrapper
  Given an adapter with a grade_wrapper that logs and runs $AB_CMD
  Then grade and score each ran once through it and the result is unchanged

Scenario: AB_TIMEOUT is exported
  Given a task with timeout_s 30
  Then the adapter sees AB_TIMEOUT=10

Scenario: The sandbox cannot see the host or the internet (needs Docker)
  Given the sandbox is up
  Then /Users and the repo path do not exist inside the agent container
  And example.com is unreachable while opencode.ai answers through the proxy
  And the grading container has no network at all
```

## Acceptance

```bash
python3 tests/test_ab_sandbox.py && bash scripts/ab-sandbox.sh status && echo OK
```
