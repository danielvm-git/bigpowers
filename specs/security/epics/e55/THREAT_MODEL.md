# Threat Model — Epic e55 (Extract Constitution)

**Scope:** e55 reads `CLAUDE.md`, `CONVENTIONS.md`, `docs/PRINCIPLES.md`, all 46
`docs/references/*.md` files, and `specs/reborn-constitution.md` (structural
reference only — not a content source). It writes a new `constitution.md` and adds
cross-reference pointers to `CLAUDE.md`/`CONVENTIONS.md`. No application code, no
network surface, no auth/session/data-storage boundary, no user-input handling — this
is a local, git-tracked documentation reorganization.

**Risk level: LOW.** No category from the standard vulnerability list (SQLi, XSS,
SSRF, command injection, auth bypass, unsafe deserialization, path traversal, IDOR,
crypto flaws, secrets exposure, template injection, NoSQLi) has an applicable surface
here — there is no code execution path, no external input, no credential handling.

## Categories considered and dismissed

- **Secrets exposure (CWE-200/CWE-522):** source files are all first-party
  maintainer-authored doctrine, already committed and public within the repo. No
  `.env`, credentials, or tokens are referenced by any of the audited files. N/A.
- **Path traversal / arbitrary file write:** `constitution.md`'s output path is fixed
  (repo root, alongside `CLAUDE.md`) and chosen by the agent per story 2's spec, not
  derived from any external or attacker-controlled input. N/A.
- **Command injection:** no shell commands in this epic's stories take
  attacker-controlled arguments; any `verify:` commands are static, spec-authored
  strings. N/A.

## Category that IS applicable: doctrine-as-instruction integrity

`constitution.md` becomes a file that Claude Code (and other agents) will read as
**authoritative rule content at runtime** — the same trust class as `CLAUDE.md` and
`CONVENTIONS.md` today. This makes the one real risk in scope a **supply-chain /
instruction-integrity** concern, not a classic input-sanitization one:

- **Risk:** if content were pulled from an untrusted or attacker-influenced source
  and merged into `constitution.md` without review, it could smuggle an instruction
  that later manipulates agent behavior (a documentation-layer prompt-injection
  vector).
- **Mitigation already satisfied by scope:** every source this epic reads
  (`CLAUDE.md`, `CONVENTIONS.md`, `docs/PRINCIPLES.md`, `docs/references/*.md`) is
  first-party, already-committed, already-reviewed repo content — not fetched from
  the network, not user-submitted, not sourced from `specs/reborn-constitution.md`
  (explicitly structural-reference-only, per the approved plan, precisely to avoid
  carrying forward that draft's own unreviewed/aspirational content as if it were
  established doctrine). No new untrusted input enters the trust boundary in any of
  the 3 stories.
- **Residual guidance for build:** story 2's `develop-tdd` pass should introduce no
  rule that isn't traceable to an existing line in one of the audited source files
  (per the epic's own "reorganization, not rewrite" constraint) — this is already the
  functional acceptance criterion, and it happens to also be the security control
  here: traceability to first-party source is the mitigation.

## Verdict

**PASS — no HIGH or above findings.** No blocking security condition exists for this
epic. `audit-code`'s per-story checklist can mark "Supply Chain & Security" as
PASS/N/A for all 3 stories on the same basis: doc-only, first-party-sourced content,
no attacker-reachable surface.
