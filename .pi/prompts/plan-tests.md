---
description: "Design a risk-scaled test architecture for an epic before implementation begins. Produces prioritized scenarios, test level distribution, and fixture plans based on TEA and bigpowers principles."
---


# Plan Tests

> **Spine position:** Between `slice-tasks` and `plan-work` for epics with `risk: P0|P1`. Optional (can be waived in `state.yaml`) for P2/P3.

Bridges the gap between slicing and planning by systematically designing the test suite as a first-class system. Produces `specs/tech-architecture/eNN-TEST_PLAN_LATEST.md`.

## Pre-flight
- Read `specs/epics/eNN-*/` story list.

## Core Workflow
1. **Analyze Epic**: Read sliced stories in the active epic capsule.
2. **Risk Assessment**: Map behaviors to P0–P3 risk tiers.
3. **Level Strategy**: Classify each scenario (Unit, Integration, E2E).
4. **Fixture Design**: Plan factories, network intercepts, mocks (see REFERENCE.md).
5. **NFR Plan**: Define verifiable commands for Non-Functional Requirements. Skip if `--lite`.
6. **Publish**: Generate `specs/tech-architecture/eNN-TEST_PLAN_LATEST.md`.

## Hard Gates & Guardrails
- **DO NOT** write test code or production code during this skill.
- Scenario ID format MUST be: `SC-eNNsYY-P{0|1|2|3}-NN`.
- `plan-work` MUST reference these scenario IDs in its §17 Gherkin acceptance criteria.
- Default to pushing tests to the lowest possible level.

## Execution Modes
- `$bmad plan-tests`: Standard execution.
- `$bmad plan-tests --lite`: Skips NFRs and complex fixture planning.

## Verify

→ verify: `test -f specs/tech-architecture/$(echo $EPIC | sed "s|.*/||")-TEST_PLAN_LATEST.md && echo OK`

## Handoff

Gate: READY -> next: plan-work
Writes: state.yaml handoff.next_skill = plan-work

---

# Plan Tests — Reference

## Test Plan Template (`specs/tech-architecture/eNN-TEST_PLAN_LATEST.md`)

```markdown
# Test Design: [eNN-slug]

## 1. Risk Matrix & Scenarios
| Scenario ID | Behavior Description | Risk | Test Level | Target File/Module |
|-------------|----------------------|------|------------|--------------------|  
| SC-P0-01    | Primary checkout     | P0   | Integration | checkout.spec.ts  |

## 2. Fixture Architecture & Isolation
- Data Factories: (e.g. UserFactory)
- Network Intercepts: (e.g. MSW handlers)
- Database State: (e.g. in-memory SQLite)

## 3. NFR Verification
| NFR Type | Requirement | Verification Command |
|----------|-------------|----------------------|
| Perf     | < 200ms     | `npm run test:perf`  |

## 4. Out of Scope
- [Explicitly excluded testing areas]
```

## Fixture Planning Guidance

- **Data Factories**: Prefer factory functions over manual object construction.
- **Network Intercepts**: For frontend integration tests, use tools like Mock Service Worker (MSW) to intercept and mock HTTP requests.
- **Database State**: For backend tests, use a clean database state per test or an in-memory database to ensure isolation.
