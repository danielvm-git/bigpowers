# e25s01: Promote ID tracking from YAML comments to first-class fields

**GitHub:** #22
**BCPs:** 2
**Status:** todo

## Problem

Source spec IDs (GSD REQ-XX, BMAD FR-XX/UJ-XX) are currently preserved as YAML comments:

```yaml
in_scope:
  - "Epic 0.1: Scaffold"  # REQ-EP01
```

This makes IDs invisible to automated tooling — `trace-requirement`, coverage audits, and diff analysis cannot parse them.

## Proposed change

When source has IDs → emit as structured YAML:

```yaml
in_scope:
  - id: REQ-EP01
    description: "Epic 0.1: Astro scaffold + Neon connection"
    source: "REQUIREMENTS.md"
```

When source has no IDs → prompt: "No IDs found. Assign auto-generated IDs? [yes / no]". If yes → emit `REQ-{NNN}` with `# auto-generated` comment.

## Gherkin

```gherkin
Given source artifacts contain IDs (REQ-XX, FR-XX, or UJ-XX)
When migrate-spec Step 3 transforms them into SCOPE_LATEST.yaml
Then each in_scope entry has an "id:" field with the source ID
And the description field contains the original text without the ID comment

Given source artifacts have NO IDs
When migrate-spec Step 3 runs
Then it prompts: "No IDs found. Assign auto-generated IDs? [yes / no]"
And if user says yes, each in_scope entry gets "id: REQ-NNN" with "# auto-generated"

Given source artifacts have MIXED IDs (some items have IDs, some don't)
When migrate-spec Step 3 runs
Then items with IDs get first-class "id:" fields
And items without IDs get auto-generated REQ-NNN IDs
And a comment in SCOPE_LATEST.yaml documents which were auto-generated
```

## Acceptance Criteria

- [ ] `in_scope` entries with source IDs emit `id:` field (not YAML comment)
- [ ] Auto-generated IDs use `REQ-{NNN}` format with `# auto-generated` annotation
- [ ] `REFERENCE.md` learnings table updated: ID tracking checkbox → checkmark (adopted)
- [ ] Backward compatible: GSD RULES.md bullet "Preserve source IDs" updated to reflect first-class field

## Files to modify

- `migrate-spec/SKILL.md` — update Step 3 transform rules
- `migrate-spec/REFERENCE.md` — update GSD→bigpowers mapping, learnings table
- `migrate-spec/REFERENCE-GSD.md` — update ID handling section

## Verify

```bash
grep -c "id:" migrate-spec/SKILL.md | awk '{if($1>=1) print "OK: ID tracking in SKILL.md"; else print "FAIL"}'
grep -E "in_scope.*id:" migrate-spec/REFERENCE.md | head -1 | grep -q "id:" && echo "OK: REFERENCE.md updated" || echo "FAIL: REFERENCE.md"
```
