---
story_id: e20s04
title: "verify-work verify-command validation — detect mismatches before UAT"
status: backlog
bcps: 1
type: feat
context: infra
---

# Story e20s04: verify command validation

Add a "verify the verify" pre-check to `verify-work` that validates each task's
`verify:` command against known output patterns before UAT begins.

In big-token-saver, task 4's verify command was `grep -q 'crates/bts-map'` but
bts-map output uses paths relative to the scanned directory (not absolute). The
UAT step caught this but required manual adjustment.

## Acceptance Criteria

- [ ] `verify-work/SKILL.md` has pre-UAT verify validation step
- [ ] Pattern mismatch detection for grep, awk, jq commands

## Gherkin Scenarios

```gherkin
Given task e21s04 has verify: grep -q 'crates/bts-map' some-output.txt
And some-output.txt contains src/bts-map (not crates/bts-map)
When verify-work runs the pre-check
Then it flags: "Pattern 'crates/bts-map' not found. Nearest match: 'src/bts-map' at line 5"
And asks: "Update verify command to 'src/bts-map'? [Y/n]"
```

## Verification

```bash
grep -c "verify.*mismatch\|pattern.*validation\|pre.UAT\|nearest.match" verify-work/SKILL.md | awk '{if($1>=1) print "OK: verify validation"; else print "FAIL: not implemented"}'
```

## Implementation Notes

- Parse each task's `verify:` from the epic YAML
- Run the verify command against current state
- If command fails, check if it's a pattern mismatch (not a real failure)
- For grep commands: run without -q to see output; compare grep pattern against actual content
- Report potential mismatches with nearest-match suggestions
