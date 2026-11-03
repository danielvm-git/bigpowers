# story: e84s01
# File-Size Exceptions

The 300-line file cap exists to ensure files fit in a single agent context window. The following files are documented exceptions:

| File | Lines | Rationale | Review date |
|------|-------|-----------|-------------|
| `scripts/audit-compliance.sh` | 300 | Gherkin harness with embedded judge logic and waiver subsystem; splitting judge loop from reporting requires fragile state-passing. At 300-line cap; monitor. | 2026-10-01 |

**Historical note:** `scripts/trace-stories.sh` was refactored into a 69-line orchestrator delegating to `scripts/lib/trace-stories.py`. `scripts/lib/trace-matrix.py` was split into `simple_yaml.py` + `trace_renderer.py` (252 lines). Prior exception rows for both were removed as both are under the 300-line cap.

Any new exception requires an entry in this table with rationale and a review date.
