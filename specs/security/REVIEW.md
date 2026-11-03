# Security Review — fix/guard-git-flag-normalize

## Scope Resolution

Branch `fix/guard-git-flag-normalize` vs `main` (2 commits, PR #194).

Files reviewed (excluding generated adapter copies under `.cursor/`, `.gemini/`, `.pi/`, … which are
byte-identical renders of `skills/guard-git/SKILL.md`):

- `scripts/lib/git-argv.py` (new) — quote-aware tokenizer + rule table, the shell side of the guard
- `extensions/omp-hooks.ts` — TS mirror (`tokenizeArgs`, `gitInvocations`, `classifyGitInvocation`,
  `dangerousGitCommand`, `evaluateBashCall`) called from the `tool_call` handler
- `hooks/pre-tool-use.sh`, `hooks/pre/bash.sh` — wire the helper in, keep legacy literals as fallback
- `scripts/omp-guard-probe.ts`, `scripts/test-guard-git-normalize.sh`,
  `specs/verifications/fixtures/guard-git-normalize.yaml` — the parity gate
- `skills/guard-git/SKILL.md` — rule documentation

Languages: Bash + Python + TypeScript. No network, no credentials, no new dependencies
(`package.json` changed only the version string).

## Threat model

The guard is a **deny-list for destructive git operations run by an AI agent or a human through a
shell tool**. Adversary = the command string. The attacker's goal is not RCE (the command runs
anyway, by design) but *silent destruction of uncommitted work / remote history* — the guard's job
is to stop the agent from doing it by accident or by plausible inference.

## Findings

| # | Area | Severity | Status |
|---|------|----------|--------|
| 1 | Command-injection into the guard itself | — | not applicable |
| 2 | Quoting / escaping bypass of the tokenizer | low | tested |
| 3 | Indirection bypass (command substitution, aliases) | medium | **accepted, documented** |
| 4 | Fail-open path when the helper is unreachable | low | mitigated |
| 5 | Gate that cannot fail (vacuous verification) | high | **fixed** |

### 1. Command injection into the guard — not applicable
`git-argv.py` receives the command as argv (`--command "$cmd"`, quoted) and parses it with
`shlex.split`, never `eval`/`shell=True`. The TS side tokenizes in-process. The guard does not
execute any part of the command it inspects.

### 2. Quoting / escaping — tested
`shlex.split` normalises `"git"`, `\git`, `'git'` to `git`, so quote-obfuscation of the program name
does not bypass classification. A `ValueError` (unbalanced quote) degrades to whitespace splitting,
never to eval and never to "allow because unparseable" — the tokens are still classified.

### 3. Indirection bypass — accepted residual (medium, not addressed)
`git $(printf reset) --hard` and a shell alias for `git` are not seen as a `git` invocation, so the
argv rules do not fire. The previous literal matcher would not reliably catch these either (the
destructive phrase is not present as text). Exploiting this requires deliberately obfuscating the
command — it is an evasion, not an accident, and the guard's purpose is accident-prevention.
Consequence for reviewers: **the guard is a guardrail, not a sandbox.** Recorded here rather than
silently fixed; closing it needs process-level controls (allow-list of subcommands), which is a
separate design decision.

### 4. Fail-open when the helper is unreachable — mitigated
`hooks/pre-tool-use.sh` falls back to the legacy literal `DANGEROUS_PATTERNS` when
`scripts/lib/git-argv.py` is absent (the hook can be symlinked outside an installed package). The
fallback is weaker but never "allow everything". Non-git commands skip the helper entirely (no
Python spawn per tool call) — `classify_git_argv()` short-circuits when the string has no `git` token.

### 5. A gate that could not fail — fixed (this is why the review exists)
`guard-git-normalize` compared `dangerousGitCommand()` (destructive argv only) against the whole
shell hook, so the protected-branch and Conventional-Commit rules had no TS oracle; the fixture also
asserted `allow` for a push to protected `main`, and the harness inherited `GIT_BIGPOWERS_LAND`,
which disables the protected-branch block. The gate was green locally and red in CI for the same
commit. Fixed in `a7345487` — probe `evaluateBashCall()` (what the handler actually calls), strip
`GIT_BIGPOWERS_LAND`, split the mislabelled fixture row. Non-vacuity proven by mutation: disabling
`protectedPushTarget` on the TS side alone now fails (b) and (c).

## Secrets / sensitive data

No secrets in the diff (`git diff main...HEAD` scanned for `sk-`, `ghp_`, `AKIA`, `.env` values). No
PII. No auth surface touched. No new external calls.

## Verdict

**PASS** — no unresolved HIGH findings. One documented medium residual (finding 3) inherent to any
argv-based deny-list.

Gates: `npm run compliance` pass · `bash scripts/run-verification-gates.sh` 54/54 pass ·
`bash scripts/run-gate-trace-verify.sh` BLOCKER=0 · CI run 41662950007 green.
