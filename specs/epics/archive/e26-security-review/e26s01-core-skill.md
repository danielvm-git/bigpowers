# e26s01: Core security-review skill + reference files

**BCPs:** 5
**Status:** todo

## Problem

There is no security-review skill in the bigpowers catalog. Every release ships
without automated security analysis at any lifecycle stage. The skill must exist
before any other skill can be integrated with it.

## Proposed change

Create `.pi/skills/security-review/` with:
- **SKILL.md** — the main skill definition with scan methodology, integration
  instructions, and HARD GATEs for each lifecycle touchpoint
- **REFERENCE-vuln-categories.md** — detection guidance for SQLi, XSS, SSRF,
  command injection, auth bypass, unsafe deserialization, path traversal, IDOR,
  crypto flaws, secrets exposure — with vulnerable vs safe code examples
- **REFERENCE-false-positives.md** — hard exclusion rules (no DOS, no rate-limit,
  env vars trusted, React/Angular XSS safety, UUID validity) + confidence rubric
  (only report findings ≥ 8/10)
- **REFERENCE-confidence-rubric.md** — scoring methodology: 0.9-1.0 (certain
  exploit path), 0.8-0.9 (clear pattern), 0.7-0.8 (suspicious, needs conditions),
  below 0.7 (don't report)

The skill scan methodology follows the Claude Code `/security-review` approach:
1. **Scope Resolution** — detect diff/scope from git or planned changes
2. **Context Research** — identify existing security patterns in codebase
3. **Vulnerability Assessment** — trace data flow, injection points, auth boundaries
4. **False-Positive Filtering** — cross-check each finding against exclusion rules
5. **Report Generation** — structured output: file:line, severity, category,
   description, exploit scenario, fix recommendation

Run `scripts/sync-skills.sh` after creation to propagate to Cursor/Gemini.

## Gherkin

```gherkin
Given the project has pending changes on a branch
When security-review skill is invoked
Then it scans the diff for vulnerabilities across all categories
And each finding includes file:line, severity, category, description, exploit scenario, fix
And only findings with confidence ≥ 8/10 are reported
And the report is output as structured markdown

Given a codebase with no security-relevant changes
When security-review skill is invoked
Then it reports "No findings" or zero results
And exits cleanly

Given a codebase with known-safe patterns (React with no dangerouslySetInnerHTML)
When security-review skill is invoked
Then it does not flag false-positive XSS in React/JSX files
```

## Acceptance Criteria

- [ ] `.pi/skills/security-review/SKILL.md` exists with 5-phase scan methodology
- [ ] Three reference files exist (vuln-categories, false-positives, confidence-rubric)
- [ ] `scripts/sync-skills.sh` runs cleanly and propagates new skill
- [ ] Skill description includes triggers ("Use when...")
- [ ] SKILL.md under 100 lines, HARD GATEs documented, verify commands included

## Files to create

- `.pi/skills/security-review/SKILL.md`
- `.pi/skills/security-review/REFERENCE-vuln-categories.md`
- `.pi/skills/security-review/REFERENCE-false-positives.md`
- `.pi/skills/security-review/REFERENCE-confidence-rubric.md`

## Verify

```bash
test -f .pi/skills/security-review/SKILL.md && echo "OK: SKILL.md exists" || echo "FAIL"
test -f .pi/skills/security-review/REFERENCE-vuln-categories.md && echo "OK: REFERENCE-vuln-categories.md" || echo "FAIL"
test -f .pi/skills/security-review/REFERENCE-false-positives.md && echo "OK: REFERENCE-false-positives.md" || echo "FAIL"
test -f .pi/skills/security-review/REFERENCE-confidence-rubric.md && echo "OK: REFERENCE-confidence-rubric.md" || echo "FAIL"
bash scripts/sync-skills.sh 2>&1 | grep -q "skills synced" && echo "OK: sync-skills.sh propagated" || echo "FAIL"
```
