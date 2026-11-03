---
bug_id: BUG-2026-11-03-prod-dependency-advisories
status: fixed
severity: high
scope: dependencies / shipped runtime
title: "The production dependency tree carried 10 advisories including a critical (proxy-addr IP spoofing) and two high direct dependencies (js-yaml, zod), with no gate watching it"
files_changed: "package.json, package-lock.json, scripts/test-prod-dependency-audit.sh (new), scripts/lib/golden-suite-gates.sh, README.md"
approach: "Update the production tree with a non-breaking `npm audit fix --omit=dev`, take the one remaining high (zod) as the major bump its own SDK peer range already allows, and gate `npm audit --omit=dev` so the tree cannot rot silently again"
risk_level: medium
commit_message: "fix(deps): clear the production dependency advisories and gate the audit"
---

# BUG-2026-11-03: production dependency advisories

Found while salvaging `danielvm-git/fix-audit-gaps` (a 2026-10-09 audit sweep that was never pushed).
That branch had logged the same class of defect a month earlier; on 2.93.1 it had come back, larger.

## Problem

- **Actual:** `npm audit --omit=dev` on `main` (2.93.1) — what users install:
  ```
  10 vulnerabilities (5 moderate, 4 high, 1 critical)
  critical  proxy-addr  ≤2.0.7   IP spoofing via IPv4-mapped IPv6 trust subnet
  high      body-parser 2.3.0   DoS via trailing bytes after a compressed body
  high      @modelcontextprotocol/sdk ≤1.31.0
  high      js-yaml               merge-key chains force quadratic CPU consumption
  high      zod <4.6.6            memory exhaustion on oversized constrained collections
  moderate  hono, @hono/node-server, fast-uri, ip-address, qs
  ```
  Two of those (`js-yaml`, `zod`) are **direct** production dependencies.
- **Expected:** the shipped tree is advisory-free, and something notices when it stops being.

## Root Cause Analysis

1. **Reproduce:** `npm audit --omit=dev` on `origin/main` at 2.93.1 → the 10 above.
2. **Isolate:** the express/hono/body-parser/proxy-addr/qs/fast-uri cluster all arrives through
   `@modelcontextprotocol/sdk@1.30.0 → express@5.2.1`; `js-yaml` and `zod` are direct.
3. **Exposure:** `bigpowers-mcp/src/index.ts` wires only `StdioServerTransport` — no
   `StreamableHTTPTransport`, no listening socket. So express is installed but never serves a
   request in the shipped server: **dependency hygiene, not a live exploitable surface**. It becomes
   live the moment anyone adds the HTTP transport, which is why it is still worth clearing now.
4. **Why nothing caught it:** the dependency gates we had (`mcp-package`, `install-hub`) ask whether
   the package *builds*. Nothing asked whether the tree is *safe*.

## Fix

- `npm audit fix --omit=dev` — non-breaking; takes `@modelcontextprotocol/sdk` 1.30.0 → **1.32.2**
  (which is what carries the express/hono/body-parser/proxy-addr/qs/fast-uri/ip-address fixes) and
  `js-yaml` within range. 9 of 10 gone, no `--force`.
- `zod` `^3.24.2` → `^4.6.7` (4.6.7 is the first release without the advisory). The SDK's own peer
  range is `zod: ^3.25 || ^4.0`, so 4.x is supported rather than merely tolerated.
- `package.json` — `audit:prod` so the audit is one command.
- `scripts/test-prod-dependency-audit.sh` + `prod-dependency-audit` gate.

## Verifying the zod major

The committed MCP build (`bigpowers-mcp/build/`, vendored — there is no TypeScript compiler in the
dependency tree) is compiled against zod 3, so the bump was checked at runtime rather than assumed:
all **10 registered tools** build their schemas and `safeParse` correctly under zod 4.6.7, with the
same required/optional shape (`read_skill` still requires `name`, `index_skills` still accepts `{}`).
`scripts/validate-mcp-package.sh` passes too.

## Regression guard

`prod-dependency-audit` (gate):
- any advisory in the production tree → FAIL, listing package + severity + title;
- an unparseable audit (registry unreachable) → **FAIL**, naming the escape hatch — never a silent
  pass. Deliberate skipping uses the runner's own mechanism, which records the gate as SKIPPED:
  `GOLDEN_SKIP_GATES=prod-dependency-audit bash scripts/run-verification-gates.sh`.

Non-vacuity proven: restored the pre-fix lockfile and the gate failed with all 10 rows; with the fix
it passes.

## Evidence

```
=== test-prod-dependency-audit.sh ===        (fixed lockfile)
  PASS no advisories in the production dependency tree (npm audit --omit=dev)
1 passed, 0 failed

=== test-prod-dependency-audit.sh ===        (pre-fix lockfile)
  FAIL 10 advisories in the production dependency tree:
      moderate  @hono/node-server …
      high      @modelcontextprotocol/sdk …
      critical  proxy-addr  proxy-addr vulnerable to IP spoofing …
      high      zod  Zod can exhaust memory while validating oversized constrained collections
0 passed, 1 failed
```

## Not in scope

The **dev** tree still reports 49 advisories (35 moderate, 12 high, 2 critical), concentrated in the
`npm` bundle inside `@semantic-release/npm` plus `semantic-release`/`ts-morph`/`glob` tooling. Clearing
them needs major release-tool upgrades, which can change the release pipeline — logged as
`BUG-2026-11-03-dev-dependency-advisories` (**open**), not attempted here.
