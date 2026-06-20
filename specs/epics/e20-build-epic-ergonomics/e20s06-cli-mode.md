---
story_id: e20s06
title: "verify-work --cli mode for CLI tools"
status: backlog
bcps: 1
type: feat
context: infra
---

# Story e20s06: --cli mode for verify-work

Add a `--cli` mode to `verify-work` for CLI tools (like bts) where the
"cold-start smoke" section (stop server, clear caches, boot from scratch)
is not applicable.

In big-token-saver (a CLI toolchain), the verify-work cold-start section
was N/A. A --cli mode would run CLI-specific verification steps instead.

## Acceptance Criteria

- [ ] `verify-work/SKILL.md` has `--cli` mode section
- [ ] CLI verification checklist: --help, --version, happy-path, edge-case
- [ ] Auto-detection of binary name from project manifests

## CLI Verification Checklist

1. `--help` smoke: run `<binary> --help`, assert output contains usage text
2. `--version` check: run `<binary> --version`, assert version matches manifest
3. Happy-path: run the documented example command from README.md
4. Edge case: run with invalid args, assert non-zero exit and error message

## Gherkin Scenarios

```gherkin
Given a Rust CLI project with binary name "bts"
And Cargo.toml has version = "0.4.0"
When verify-work --cli runs
Then step 1 runs: bts --help → assert output contains "Usage: bts"
And step 2 runs: bts --version → assert output contains "0.4.0"
And step 3 runs: bts map → assert output contains ranked file map
And step 4 runs: bts --invalid-flag → assert exit code != 0
And no "stop server" or "clear caches" steps are executed
```

## Verification

```bash
grep -c "\-\-cli\|cli.mode\|help.*version\|binary.name" verify-work/SKILL.md | awk '{if($1>=2) print "OK: --cli mode"; else print "FAIL: only " $1 " refs"}'
```

## Implementation Notes

- Auto-detect binary name from Cargo.toml, package.json, or Makefile
- Default to --cli mode if project has no server/process (no server.js, no listen(), no blocking main())
- Keep existing server-centric mode for web/server projects
