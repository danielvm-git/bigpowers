# Fix and Report: Reference

## GitHub Issue Templates

### Initial Triage (Phase 1)
```md
## Problem
[Description of actual vs expected behavior]

## Initial Diagnosis
- **Location**: [file:line]
- **Potential Root Cause**: [Why it fails]
- **Reproducer**: [Minimal steps or test command]
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
[2-3 sentences max]

### Fix Applied
[Approach and file list]

### Prevention
- **Mechanism**: [type guard / schema / assertion / lint rule / env check]
- **Details**: [what was added to prevent recurrence]

### Test Coverage
- New tests: [count]
- Suite: ✅ All passing
- Type check / Lint: ✅ Pass

### Commit
`[conventional commit message]`
```

## Automated Logging (Phase 4)

To update the `docs/bugs/bug-log.csv` without formatting errors, use the helper script. 

### Step 1: Prepare JSON
Create a temporary file `bug.json` with all 25 fields (see CSV format below).

### Step 2: Run Script
```bash
# Preview the CSV row
node fix-report/scripts/log-bug.js "$(cat bug.json)"

# Append to log
node fix-report/scripts/log-bug.js "$(cat bug.json)" >> docs/bugs/bug-log.csv
```

## Bug Log CSV Format
File: `docs/bugs/bug-log.csv`

| # | Column | Format |
|---|---|---|
| 1 | bug_id | `BUG-YYYY-MM-DD-NNN` |
| 2 | date | `YYYY-MM-DD` |
| 3 | severity | `critical|high|medium|low` |
| 4 | priority | `p0|p1|p2|p3` |
| 5 | scope | `kebab-case` |
| 6 | error_message | `string` |
| 7 | location | `file:line` |
| 8 | root_cause | `string` |
| 9 | trigger | `string` |
| 10 | files_changed | `semicolon-separated` |
| 11 | approach | `string` |
| 12 | risk_level | `low|medium|high` |
| 13 | breaking_change | `yes|no` |
| 14 | prevention_mechanism | `semicolon-separated` |
| 15 | prevention_details | `string` |
| 16 | new_tests | `int` |
| 17 | updated_tests | `int` |
| 18 | total_tests | `int` |
| 19 | type_check | `pass|fail` |
| 20 | lint | `pass|fail` |
| 21 | commit_type | `fix|feat|fix!|feat!` |
| 22 | release_type | `patch|minor|major` |
| 23 | commit_message | `string` |
| 24 | github_issue | `URL` |
| 25 | follow_ups | `semicolon-separated` |

## Git Command Template (Phase 5)
```bash
git add .
git commit -m "fix(<scope>): <description>" -m "Root cause: <explanation>" -m "Refs: #<issue-number>"
git push origin <branch>
```
