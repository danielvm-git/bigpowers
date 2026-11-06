# Generalize-fix (e80s04 / GH #98)

After local hardening in `validate-fix`, sweep the **defect class** across the codebase.

## Steps

1. **Classify** — name the pattern (e.g. `unscoped org query`, `fail-open verify`, `hardcoded package manager`).
2. **Sweep** — grep for sibling instances; record `match_count` and `grep_pattern`.
3. **Resolve** — patch all matches in this PR **or** file one tracking issue listing every remaining instance.
4. **Artifact** — write sweep evidence before declaring done:

```bash
cat > specs/verifications/generalize-sweep-BUG-YYYY-MM-DD-slug.json <<EOF
{
  "defect_class": "fail-open-verify",
  "grep_pattern": "\\\\|\\\\| echo",
  "match_count": 0,
  "sweep_scope": "skills/*/SKILL.md",
  "patched_in_pr": [],
  "tracked_issues": []
}
EOF
bash scripts/verify-generalize-sweep.sh specs/verifications/generalize-sweep-*.json
```

## Security classes

When the defect class is security- or gate-relevant:

- Add a row to `security-review` CWE fixture table (see `skills/security-review/SKILL.md` § CWE mapping mandate).
- If security-impact was MEDIUM+: add regression test, false-positive exclusion rule, and threat-model update (HIGH+).
