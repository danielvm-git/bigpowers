# Fix and Report: Examples

## Example 1: Fixing a TypeError

**User**: "The dashboard is crashing with 'TypeError: Cannot read properties of null (reading 'map')' when I open the projects tab."

**Agent Workflow**:
1. **Phase 1**: Investigates `ProjectList.tsx`, finds that `projects` can be null if the API returns no data. Creates GitHub Issue #123.
2. **Phase 2**: Plans to add a nullish coalescing check `projects ?? []` and a Zod default. Designs TDD: Test with null data should render "No projects found".
3. **Phase 3**: Implements the fix and adds a Vitest test case. Adds Zod `.default([])`.
4. **Phase 4**: Updates `bug-log.csv` and updates Issue #123 with the report.
5. **Phase 5**: Provides Git commands for `fix(ui): handle null projects in dashboard`.

## Example 2: Fixing a Failing Test

**User**: "The auth tests are failing after the last merge. Check `src/lib/__tests__/auth.test.ts`."

**Agent Workflow**:
1. **Phase 1**: Runs tests, finds `token-expiry` test fails. Traces to `auth.ts`. Creates GitHub Issue #124.
2. **Phase 2**: Identifies off-by-one error in timestamp comparison.
3. **Phase 3**: Fixes comparison and verifies with the failing test.
4. **Phase 4**: Updates `bug-log.csv` and Issue #124.
5. **Phase 5**: Provides Git commands.
