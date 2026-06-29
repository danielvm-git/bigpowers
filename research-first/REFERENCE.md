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
- [ ] Existing bigpowers skill (`bash scripts/build-skill-index.sh && rg "<intent>" specs/SKILL-SEARCH-INDEX_LATEST.md`)
- [ ] Project `docs/` and `specs/adr/`
- [ ] Official library documentation (quote one API detail)

## Prior Art template

```markdown
## Prior Art

| Candidate | Source | Verdict | Notes |
|-----------|--------|---------|-------|
| ... | ... | adopt/extend/compose/build | ... |
```
