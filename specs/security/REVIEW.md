# Security Review — e37: Reach — Universal Agent Portability

## Scope Resolution
Scanned changes: `feat/e37-reach` — AGENTS.md spine, `scripts/targets.yaml`, adapter dispatch, verify matrix, Codex optional wave.
Files changed: Bash scripts, Markdown skills/docs, YAML registry
Languages: Bash, Markdown, YAML

## Vulnerability Assessment

| Category | Finding | Severity | Mitigation |
|----------|---------|----------|------------|
| Path Traversal | Adapters write to configured output paths | LOW | Registry-validated adapter ids; no user-supplied paths in CLI |
| Symlink attacks | context-wire creates symlinks | LOW | Relative AGENTS.md → derivative only; copy fallback documented |
| Secrets Exposure | Codex template, seed REFERENCE | LOW | e37s15 verify: no api keys in templates; install touches ~/.codex/AGENTS.md only |
| Command Injection | validate-targets-yaml, test-adapters use yq/bash | LOW | No eval; fixed script paths |
| Supply chain | Optional big-counter N/A for e37 | NONE | — |

Threat model: `specs/security/epics/e37/THREAT_MODEL.md`

## Verdict
**PASS** — No unresolved HIGH findings. Bash-only surface; no network listeners. Codex global install limited to AGENTS.md symlink.
