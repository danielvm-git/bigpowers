---
name: research-first
description: "Look-before-build — search registries, repo, existing skills, and web for prior art before implementing. Appends Prior Art to the spec. Use after survey-context and before elaborate-spec, when adding dependencies, or when the task may already be solved."
model: sonnet
---


# Research First

> **HARD GATE** — Do NOT implement until prior art is searched. Minimum outcome: adopt, extend, compose, or build — with evidence.

## Process

1. Read `specs/product/SCOPE_LATEST.yaml`, `specs/release-plan.yaml + epic shards`, and the current task statement.
2. Search in order: this repo → bigpowers skills (`search-skills`) → package registries → web docs.
3. For each candidate: note name, URL/path, fit (adopt | extend | compose | build).
4. Append `## Prior Art` to `requirements/SCOPE_LATEST.yaml` notes or the active epic story.

## Outcome matrix

| Verdict | Action |
|---------|--------|
| **adopt** | Use as-is; link in plan; no new code |
| **extend** | Wrap or configure existing solution |
| **compose** | Chain existing skills/modules |
| **build** | New implementation — justify why others failed |

## Verify

→ verify: `grep -c "Prior Art" specs/product/SCOPE_LATEST.yaml specs/release-plan.yaml + epic shards 2>/dev/null | awk '{s+=$1} END {if(s>0) print "OK"; else print "MISSING"}'`

See [REFERENCE.md](REFERENCE.md) for search commands and registry checklist.

---

# Research First — Reference

## Search commands

```bash
# Repo prior art
rg -l "<keyword>" --glob '!node_modules' .
find . -maxdepth 3 -name "SKILL.md" | xargs grep -l "<intent>"

# Installed packages (if package.json exists)
cat package.json | jq '.dependencies,.devDependencies' 2>/dev/null
```

## Registry checklist

- [ ] npm / PyPI / crates.io (if applicable)
- [ ] Existing bigpowers skill (`bash scripts/build-skill-index.sh && rg "<intent>" specs/SKILL-SEARCH-INDEX.md`)
- [ ] Project `docs/` and `specs/adr/`
- [ ] Official library documentation (quote one API detail)

## Prior Art template

```markdown
## Prior Art

| Candidate | Source | Verdict | Notes |
|-----------|--------|---------|-------|
| ... | ... | adopt/extend/compose/build | ... |
```
