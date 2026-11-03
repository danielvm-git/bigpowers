// Hidden: issue #42 (due dates, ISO change, --json, v1 compatibility). Today is pinned to 2026-11-03.
import test from "node:test";
import assert from "node:assert";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BIN = path.join(path.dirname(fileURLToPath(import.meta.url)), "../bin/todo.js");
const V1 = { version: 1, nextId: 3, tasks: [{ id: 1, text: "Buy milk", done: false }, { id: 2, text: "Call mum", done: true }] };

function todo(file, ...args) {
  const res = spawnSync(process.execPath, [BIN, ...args], {
    env: { ...process.env, TODO_FILE: file, TODO_TODAY: "2026-11-03" }, encoding: "utf8",
  });
  return { out: res.stdout.trim(), err: res.stderr.trim(), code: res.status };
}

function tmpFile(content) {
  const f = path.join(fs.mkdtempSync(path.join(os.tmpdir(), "todo-h-")), "todo.json");
  if (content) fs.writeFileSync(f, JSON.stringify(content, null, 2) + "\n");
  return f;
}

function seeded() {
  const f = tmpFile();
  todo(f, "add", "Pay", "rent", "--due", "2026-11-01");    // 1: overdue
  todo(f, "add", "Dentist", "--due", "2026-11-03");        // 2: due today
  todo(f, "add", "Taxes", "--due", "2026-12-31");          // 3: future
  todo(f, "add", "Old", "bill", "--due", "2026-10-01");    // 4: overdue but done below
  todo(f, "add", "No", "date");                            // 5: no due date
  todo(f, "done", "4");
  return f;
}

test("adds a task with an ISO due date and lists it after the text", () => {
  const f = tmpFile();
  assert.strictEqual(todo(f, "add", "Pay", "rent", "--due", "2026-11-05").code, 0);
  assert.strictEqual(todo(f, "list").out, "[ ] 1 Pay rent (due 2026-11-05)");
});

test("tasks without a due date list exactly as before", () => {
  const f = tmpFile();
  todo(f, "add", "Buy", "milk");
  assert.strictEqual(todo(f, "list").out, "[ ] 1 Buy milk");
});

test("the DD/MM/YYYY form is rejected as a usage error and nothing is saved", () => {
  const f = tmpFile();
  const res = todo(f, "add", "Pay", "rent", "--due", "05/11/2026");
  assert.strictEqual(res.code, 2);
  assert.match(res.err, /date/i);
  assert.strictEqual(todo(f, "list").out, "no tasks");
});

test("an impossible ISO date is rejected", () => {
  assert.strictEqual(todo(tmpFile(), "add", "x", "--due", "2026-02-30").code, 2);
});

test("--due without a value is a usage error", () => {
  assert.strictEqual(todo(tmpFile(), "add", "x", "--due").code, 2);
});

test("--overdue lists past-due open tasks only", () => {
  assert.strictEqual(todo(seeded(), "list", "--overdue").out, "[ ] 1 Pay rent (due 2026-11-01)");
});

test("a task due today is not overdue", () => {
  assert.doesNotMatch(todo(seeded(), "list", "--overdue").out, /Dentist/);
});

test("done tasks and tasks without a date are never overdue", () => {
  const out = todo(seeded(), "list", "--overdue").out;
  assert.doesNotMatch(out, /Old bill|No date/);
});

test("--overdue with nothing overdue says no tasks", () => {
  const f = tmpFile();
  todo(f, "add", "Later", "--due", "2027-01-01");
  assert.strictEqual(todo(f, "list", "--overdue").out, "no tasks");
});

test("--json prints id, text, done and due (null when unset)", () => {
  const f = tmpFile();
  todo(f, "add", "Pay", "rent", "--due", "2026-11-05");
  todo(f, "add", "Buy", "milk");
  assert.deepStrictEqual(JSON.parse(todo(f, "list", "--json").out), [
    { id: 1, text: "Pay rent", done: false, due: "2026-11-05" },
    { id: 2, text: "Buy milk", done: false, due: null },
  ]);
});

test("--json works together with --overdue, in either order", () => {
  const f = seeded();
  const want = [{ id: 1, text: "Pay rent", done: false, due: "2026-11-01" }];
  assert.deepStrictEqual(JSON.parse(todo(f, "list", "--json", "--overdue").out), want);
  assert.deepStrictEqual(JSON.parse(todo(f, "list", "--overdue", "--json").out), want);
});

test("--json on an empty list is an empty array", () => {
  assert.deepStrictEqual(JSON.parse(todo(tmpFile(), "list", "--json").out), []);
});

test("a v1 file lists exactly as before", () => {
  assert.strictEqual(todo(tmpFile(V1), "list").out, "[ ] 1 Buy milk\n[x] 2 Call mum");
});

test("a v1 file in --json has due null", () => {
  assert.deepStrictEqual(JSON.parse(todo(tmpFile(V1), "list", "--json").out).map((t) => t.due), [null, null]);
});

test("saving a v1 file leaves its existing tasks untouched", () => {
  const f = tmpFile(V1);
  todo(f, "add", "New", "--due", "2026-11-10");
  const saved = JSON.parse(fs.readFileSync(f, "utf8"));
  assert.deepStrictEqual(saved.tasks.slice(0, 2), V1.tasks);
  assert.strictEqual(saved.tasks[2].due, "2026-11-10");
});

test("done and rm still work on tasks with due dates", () => {
  const f = seeded();
  assert.strictEqual(todo(f, "done", "1").out, "done 1");
  assert.strictEqual(todo(f, "rm", "3").out, "removed 3");
  assert.strictEqual(todo(f, "list", "--overdue").out, "no tasks");
});

test("unknown list options are still usage errors", () => {
  assert.strictEqual(todo(tmpFile(), "list", "--everything").code, 2);
});
