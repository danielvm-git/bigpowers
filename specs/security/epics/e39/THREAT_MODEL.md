# Threat Model — e39: Semantic Context Bridge

Date: 2026-07-05
Assessor: cockpit (build-epic Step 0)
Confidence: High (documentation/scripting epic, well-understood surface area)

## Verdict

CLEAR — LOW risk. No blocking findings.

## Surface Area

| Component | Network? | User Input? | Auth? | DB? |
|-----------|----------|-------------|-------|-----|
| build-skill-graph.sh (MCP bridge) | Local MCP socket only | No (reads files) | No | No |
| agent-locks.yaml protocol | No | No | No | No |
| check-spec-drift.sh | No | No | No | No |
| OKF wiki generators (3 scripts) | No | No | No | No |
| maintain-wiki skill | No | No | No | No |
| Architecture guide (docs) | No | No | No | No |
| validate-okf.sh extension | No | No | No | No |

## Key Findings

1. **MCP data (LOW):** e39s01 bridges to bigpowers-mcp — MCP output must be parsed through `jq`/JSON before shell interpolation.
2. **Race conditions (LOW):** e39s02 agent-locks.yaml — atomic write pattern (temp + mv) recommended.
3. **Path traversal (NONE):** All scripts use deterministic globs (`skills/*/SKILL.md`), no user-controlled paths.

No injection, auth bypass, secrets exposure, or unsafe deserialization vectors.
All artifacts are git-tracked plain text under `specs/`.
