# Story Template — bigpowers Countable Story Format

Use this template for new story specs under `specs/epics/eNN-slug/`.

## Sections

1. **ID + Title** — `eNNsYY: Short descriptive title`
2. **Epic** — `eNN — Epic Title`
3. **Type** — `feat | fix | refactor | chore`
4. **BCP** — Story complexity (Business Complexity Points, integer)
5. **BCP Plus** — Optional 13-dimension breakdown (see below)
6. **Risk** — `P0 | P1 | P2 | P3`
7. **WSJF** — Weighted Shortest Job First score
8. **Status** — `backlog | todo | in_progress | done`
9. **Context** — 1 paragraph: what this story implements and why
10. **Dependencies** — Epic IDs or external dependencies
11. **Steps** — Ordered implementation steps with verify commands
12. **Verification Script** — Human-readable verification steps
13. **Out of Scope** — Explicit exclusions
14. **Risks** — What could go wrong
15. **Security** — `none | low | medium | high` (from threat model)
16. **Acceptance Criteria** — Gherkin scenarios
17. **Test Plan** — Test coverage strategy
18. **Implementation Notes** — Architecture decisions, gotchas
19. **Alternatives Considered** — What was rejected and why
20. **References** — ADRs, commits, issues

## BCP Plus Breakdown (optional §5)

When BCP Plus sizing is available, add a `bcp_plus_breakdown` field:

```yaml
bcp_plus_breakdown:
  total: 14
  dimensions:
    dim_01_boundaries: 2
    dim_02_interface_elements: 3
    dim_03_business_rules: 4
    dim_04_solution_variabilities: 1
    dim_05_roles_permissions: 1
    dim_06_domain_entities_existing: 2
    dim_07_domain_entities_new: 0
    dim_08_notifications: 0
    dim_09_audits: 0
    dim_10_background_processes: 0
    dim_11_quality_attributes: 1
    dim_12_security_compliance: 0
    dim_13_ux_accessibility: 0
```

**NFR Gate:** Standard-expectation items (e.g., "use HTTPS") score N/A (0 points) with a one-line rationale. The breakdown above reflects counted complexity only — gated items are excluded.
