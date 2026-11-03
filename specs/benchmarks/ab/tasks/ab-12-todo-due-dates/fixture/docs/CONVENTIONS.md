# todo — conventions

- **Output:** results go to stdout, one line each. Errors go to stderr as `todo: <message>`.
- **Exit codes:** 0 on success, 2 for usage errors (bad arguments, unknown command or option),
  1 for any other failure (for example an unknown task id). Usage errors are `UsageError`.
- **Dates:** use `today()` from `src/clock.js` for the current date. Tests pin it with
  `TODO_TODAY=YYYY-MM-DD`; do not read the system clock anywhere else.
- **Data file:** `TODO_FILE`, or `todo.json` in the current folder. Format:
  `{ "version": 1, "nextId": <n>, "tasks": [{ "id", "text", "done" }] }`.
- **List format:** `[ ] <id> <text>` for an open task, `[x] <id> <text>` for a done one, in id
  order; `no tasks` when there are none.
