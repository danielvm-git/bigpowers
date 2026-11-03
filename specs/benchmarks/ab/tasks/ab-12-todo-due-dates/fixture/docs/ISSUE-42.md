# Issue #42 — Due dates

**@rita (2026-10-20)**

I'd love due dates. Something like `todo add Pay rent --due 05/11/2026`, and then `todo list`
showing the date right after the task, like `[ ] 3 Pay rent (due 05/11/2026)`.

Also a way to see what I missed: `todo list --overdue` should show only the tasks that are past
their due date and not done yet. (A task due today isn't overdue — I still have the whole day.)

**@sam (maintainer, 2026-10-24)**

Agreed, with two changes.

1. Dates are ISO-8601 everywhere, in and out: `--due 2026-11-05`. The DD/MM form is ambiguous
   for half of our users, so reject it with a clear error instead of guessing. That's a usage
   error like any other bad argument.
2. Add `--json` to `list`: print an array of `{ "id", "text", "done", "due" }`, with `due` set
   to `null` when a task has none. `--json` has to work together with `--overdue`.

**@sam (2026-10-25)**

One more thing: everyone already has a todo file written by the current version, without any
`due` field. Those files must keep loading and listing exactly as they do today, and saving must
leave their existing tasks untouched.
