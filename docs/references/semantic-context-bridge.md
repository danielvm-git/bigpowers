# Semantic Context Bridge — Architecture & Operator Guide

> story: e39s09  
> Part of Epic e39 — Semantic Context Bridge

## Overview

The Semantic Context Bridge addresses the Layer 3 (Technical Context) and Layer 5
(Product Surface) gaps identified in the stack-layer analysis of bigpowers vs.
"The Agentic Coding Stack: 5 Layers and the Missing Link" by Murat Aslan.

It provides four mechanisms that give agents structured access to project context:

1. **Skill Graph** — machine-readable dependency graph between skills
2. **Agent Locks** — coordination protocol for multi-agent scenarios
3. **Spec Drift Detection** — alerts when code outpaces its specification
4. **OKF Wiki Bundle** — progressive-disclosure concept wikis derived from source docs

## Components

### 1. Skill Graph (e32s02 + e39s01)

- **Source:** `bigpowers-mcp/build_skill_graph` MCP tool (e32s02)
- **Runtime artifact:** `bigpowers-mcp/graph.jsonl` (entity → relation format)
- **Consumption:** `scripts/build-skill-graph.sh` reads graph.jsonl and writes:
  - `specs/skill-graph.json` — full node/edge dependency graph (74 nodes, 34 edges)
  - `specs/skills-wiki/skills/*.md` — per-skill OKF concept pages
- **CI Integration:** `scripts/sync-skills.sh --okf` triggers rebuild
- **Provenance:** Karpathy "Think Before Coding" — structured knowledge access

### 2. Agent Locks (e39s02)

- **Protocol file:** `specs/agent-locks.yaml`
- **Acquire:** `kickoff-branch` reads locks → fails if story already locked → appends entry
- **Release:** `release-branch` removes lock entry on completion
- **Stale detection:** CI validates no lock >24h old (non-blocking warning)
- **Provenance:** TEA (Traceability, Evidence, Accountability) — multi-agent coordination

### 3. Spec Drift Detection (e39s03)

- **Script:** `scripts/check-spec-drift.sh`
- **Input:** `specs/traceability-matrix.json` (from scripts/trace-stories.sh)
- **Output:** `specs/drift-report.json` with suspect/broken links
- **Verdict:** `gate-trace` downgrades PASS → CONCERNS when suspect links exist
- **Provenance:** Karpathy — evidence over claims

### 4. OKF Wiki Bundle (e39s04–e39s07)

- **skills-wiki:** `scripts/sync-skills.sh --okf` parses SKILL.md frontmatter → OKF concepts
- **conventions-wiki:** `scripts/decompose-conventions.sh` splits CONVENTIONS.md headings
- **agent-guide:** `scripts/generate-agent-guide.sh` splits CLAUDE.md into Guide concepts
- **Maintenance:** `skills/maintain-wiki` skill — INGEST, LINT, QUERY operations
- **CI Integration:** OKF wiki refresh in build-epic Step 9b; LINT in verify-work Phase 5b
- **Provenance:** OKF v0.1 spec, TEA framework

## CI/CD Integration

| Trigger | Action | Script |
|---------|--------|--------|
| Every push | Stale-lock check | Inline in sync-skills.yml |
| Every push | Skill graph rebuild | `scripts/build-skill-graph.sh` (via sync-skills --okf) |
| Pre-release | OKF wiki refresh | build-epic Step 9b |
| Pre-release | Spec drift check | `scripts/check-spec-drift.sh` |
| Per-epic | OKF wiki LINT | verify-work Phase 5b |

## Data Flow

```
SKILL.md ──> build_skill_graph (MCP) ──> graph.jsonl ──> build-skill-graph.sh ──> skill-graph.json
                                                              │
                                                              └─> skills-wiki/skills/*.md
                                                                    
CONVENTIONS.md ──> decompose-conventions.sh ──> conventions-wiki/*.md
CLAUDE.md ──────> generate-agent-guide.sh ────> agent-guide/*.md

trace-stories.sh ──> traceability-matrix.json ──> check-spec-drift.sh ──> drift-report.json
                                                              │
                                                              └─> gate-trace CONCERNS
```
