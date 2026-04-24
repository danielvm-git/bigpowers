# Fix and Report: Reference

## GitHub Issue Templates

### Initial Triage (Phase 1)
```md
## Problem
[Description]

## Initial Diagnosis
- **Location**: [file:line]
- **Potential Root Cause**: [hypothesis]
```

### Final Bug Fix Report (Phase 4)
```md
## Bug Fix Report
**Bug ID:** `BUG-YYYY-MM-DD-NNN`
**Severity:** [Critical|High|Medium|Low]
**Status:** ✅ Fixed & Verified

### Error Summary
| Field | Value |
|-------|-------|
| Error | `[exact message]` |
| Location | `[file:line]` |
| Trigger | [cause] |

### Root Cause
[explanation]

### Fix Applied
[file list and approach]

### Prevention
- **Mechanism**: [type guard / schema / assertion / etc.]
- **Details**: [what was added]

### Test Coverage
- New tests: [count]
- Suite: ✅ All passing
- Type check / Lint: ✅ Pass

### Commit
`[conventional commit message]`
```

## Bug Log CSV Format (Phase 4)
File: `docs/bugs/bug-log.csv`

| Column | Format |
|---|---|
| bug_id | `BUG-YYYY-MM-DD-NNN` |
| date | `YYYY-MM-DD` |
| severity | `critical|high|medium|low` |
| priority | `p0|p1|p2|p3` |
| scope | `kebab-case` |
| error_message | `escaped string` |
| location | `file:line` |
| root_cause | `string` |
| trigger | `string` |
| files_changed | `semicolon-separated` |
| approach | `string` |
| risk_level | `low|medium|high` |
| breaking_change | `yes|no` |
| prevention_mechanism | `semicolon-separated` |
| prevention_details | `string` |
| new_tests | `int` |
| updated_tests | `int` |
| total_tests | `int` |
| type_check | `pass|fail` |
| lint | `pass|fail` |
| commit_type | `fix|feat|fix!|feat!` |
| release_type | `patch|minor|major` |
| commit_message | `string` |
| github_issue | `pending|URL` |
| follow_ups | `semicolon-separated` |

## Git Command Template (Phase 5)
```bash
git add <files> docs/bugs/bug-log.csv
git commit -m "fix(<scope>): <description>" -m "Root cause: <explanation>"
git push origin <branch>
```
