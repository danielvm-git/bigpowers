import test from "node:test";
import assert from "node:assert";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BIN = path.join(path.dirname(fileURLToPath(import.meta.url)), "../bin/todo.js");

function todo(file, ...args) {
  const res = spawnSync(process.execPath, [BIN, ...args], {
    env: { ...process.env, TODO_FILE: file, TODO_TODAY: "2026-11-03" }, encoding: "utf8",
  });
  return { out: res.stdout.trim(), err: res.stderr.trim(), code: res.status };
}

function tmpFile() {
  return path.join(fs.mkdtempSync(path.join(os.tmpdir(), "todo-")), "todo.json");
}

test("adds and lists tasks in id order", () => {
  const f = tmpFile();
  assert.strictEqual(todo(f, "add", "Buy", "milk").out, "added 1");
  todo(f, "add", "Call mum");
  assert.strictEqual(todo(f, "list").out, "[ ] 1 Buy milk\n[ ] 2 Call mum");
});

test("an empty list says so", () => {
  assert.strictEqual(todo(tmpFile(), "list").out, "no tasks");
});

test("marks a task done", () => {
  const f = tmpFile();
  todo(f, "add", "Buy milk");
  assert.strictEqual(todo(f, "done", "1").out, "done 1");
  assert.strictEqual(todo(f, "list").out, "[x] 1 Buy milk");
});

test("removes a task", () => {
  const f = tmpFile();
  todo(f, "add", "a");
  todo(f, "add", "b");
  assert.strictEqual(todo(f, "rm", "1").out, "removed 1");
  assert.strictEqual(todo(f, "list").out, "[ ] 2 b");
});

test("unknown task id is exit 1", () => {
  const res = todo(tmpFile(), "done", "7");
  assert.strictEqual(res.code, 1);
  assert.strictEqual(res.err, "todo: no task with id 7");
});

test("usage errors are exit 2", () => {
  const f = tmpFile();
  assert.strictEqual(todo(f, "add").code, 2);
  assert.strictEqual(todo(f, "frobnicate").code, 2);
  assert.strictEqual(todo(f, "done", "x").code, 2);
});

test("ids keep increasing after a removal", () => {
  const f = tmpFile();
  todo(f, "add", "a");
  todo(f, "rm", "1");
  assert.strictEqual(todo(f, "add", "b").out, "added 2");
});
