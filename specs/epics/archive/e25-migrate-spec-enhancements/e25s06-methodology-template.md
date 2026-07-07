# e25s06: Add methodology doc template (GSD learning)

**GitHub:** #27
**BCPs:** 1
**Status:** todo

## Problem

migrate-spec's Step 5 offers "Methodology doc" as an optional learning from GSD, but produces no output artifact. Agents have no standing analytical framework to inform planning and audit sessions.

## Proposed change

Add an optional Step 6 that scaffolds `specs/tech-architecture/METHODOLOGY_LATEST.md` from a template.

Template sketch:

```markdown
# Methodology — {{project_name}}

The following analytical lenses should inform `plan-work` and `audit-code` sessions.

## Cost of Delay (CD3)
CD3 = {{value}} / {{duration}}

## STRIDE
- Spoofing: ...
- Tampering: ...
- Repudiation: ...
- Information disclosure: ...
- Denial of service: ...
- Elevation of privilege: ...

## Optional (uncomment as needed)
<!--
## Bayesian Updating
...
-->
```

## Gherkin

```gherkin
Given the user selected "Methodology doc" in the learnings checklist
When Step 6 runs
Then it prompts: "Which analytical lenses to include?"
And presents a checklist: [CD3, STRIDE, Bayesian Updating, Threat Modeling]
And creates specs/tech-architecture/METHODOLOGY_LATEST.md from template

Given the user selected only CD3
When Step 6 runs
Then METHODOLOGY_LATEST.md contains only the CD3 section
And STRIDE, Bayesian, Threat sections are commented out

Given the user did NOT select "Methodology doc"
When Step 6 is offered
Then it is skipped with note: "Methodology doc: skipped"
```

## Acceptance Criteria

- [ ] Template file at `migrate-spec/templates/METHODOLOGY_LATEST.md`
- [ ] Step 6 prompts for lens selection with checklist
- [ ] Only selected lenses are active (others commented out)
- [ ] Not selected → skipped with note in handoff
- [ ] `REFERENCE.md` learnings table updated: methodology checkbox → checkmark (adopted)

## Files to modify

- `migrate-spec/SKILL.md` — add Step 6 for methodology doc scaffolding
- `migrate-spec/REFERENCE.md` — update learnings table

## Create

- `migrate-spec/templates/METHODOLOGY_LATEST.md`

## Verify

```bash
test -f migrate-spec/templates/METHODOLOGY_LATEST.md && echo "OK: methodology template" || echo "FAIL: no template"
grep -c "Methodology\|METHODOLOGY" migrate-spec/SKILL.md | awk '{if($1>=1) print "OK: methodology in SKILL.md"; else print "FAIL"}'
```
