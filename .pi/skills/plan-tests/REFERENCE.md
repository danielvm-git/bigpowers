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
