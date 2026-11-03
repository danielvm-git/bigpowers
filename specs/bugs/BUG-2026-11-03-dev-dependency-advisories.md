---
bug_id: BUG-2026-11-03-dev-dependency-advisories
status: open
severity: medium
scope: development dependencies / release tooling
title: "The dev tree reports 49 advisories (2 critical) in the npm bundle inside @semantic-release/npm and the semantic-release/ts-morph/glob toolchain; clearing them needs major release-plugin upgrades"
files_changed: "(none yet)"
approach: "Review the supported semantic-release plugin matrix, move the release tooling to a non-vulnerable set (or apply narrowly scoped overrides), then re-run the release dry-run, compliance and every gate before accepting the new graph"
risk_level: medium
commit_message: "chore(deps): clear the development dependency advisories"
---

# BUG-2026-11-03: development dependency advisories

**Status: open — logged, not fixed.** Found while clearing the production tree
(`BUG-2026-11-03-prod-dependency-advisories`). Dev-only risk, and the remediation is a major
toolchain move, so it is recorded rather than bundled into a security fix.

## Problem

`npm audit` (full tree) on 2.93.1, after the production fix:

```
49 vulnerabilities (35 moderate, 12 high, 2 critical)
```

Concentrated in:

- the **`npm` package bundled inside `@semantic-release/npm`** — which drags in `@npmcli/*`,
  `libnpm*`, `pacote`, `cacache`, `tar`, `sigstore`, `tuf-js`, `node-gyp`;
- `semantic-release` plugins (`@semantic-release/github`, `@semantic-release/exec`);
- `ts-morph` / `@ts-morph/common` / `@ctxo/lang-typescript`;
- `glob` / `minimatch` / `brace-expansion` / `picomatch`.

`npm audit --omit=dev` is clean; none of this reaches an installed user.

## Why it is not fixed here

`npm audit fix --force` resolves it by moving `@semantic-release/npm` to 13.x and
`@semantic-release/changelog` to 5.x (and similar majors). That is the **release pipeline** — the
thing that tags, publishes to npm and cuts GitHub releases. Changing it inside a dependency-security
PR would mean the fix and the risk ship in the same commit.

Risk: **medium, dev-only.** Affected environments are contributor/CI machines that unpack package and
archive data while releasing — not the published artifact.

## Fix plan

1. Enumerate the supported `semantic-release` plugin matrix at the versions we need.
2. Move the release tooling to a non-vulnerable set (or apply narrowly scoped `overrides` where the
   transitive range is the only problem).
3. `npm run release -- --dry-run --no-ci`, then compliance and every gate — a green release dry-run
   with a new toolchain is the acceptance signal.
4. Re-run `npm audit` and confirm; keep `audit:prod` green throughout.

## Acceptance criteria

- [ ] `npm audit` reports no vulnerabilities, or the remainder is reviewed and recorded here with
      human approval.
- [ ] Release dry-run succeeds on the upgraded toolchain.
- [ ] `npm audit --omit=dev` stays clean (`prod-dependency-audit` gate green).
