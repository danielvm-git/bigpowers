import { today } from "./clock.js";
import { load, save } from "./store.js";

export class UsageError extends Error {}

const COMMANDS = { add, list, done, rm };
const ISO_DATE = /^(\d{4})-(\d{2})-(\d{2})$/;

// Runs one command and returns the lines to print. Throws UsageError for bad usage (exit 2)
// and Error for everything else (exit 1).
export function run(args) {
  const [name, ...rest] = args;
  if (!name) throw new UsageError("usage: todo <add|list|done|rm> ...");
  const command = COMMANDS[name];
  if (!command) throw new UsageError(`unknown command: ${name}`);
  return command(rest);
}

function add(args) {
  const { words, due } = splitDue(args);
  const text = words.join(" ").trim();
  if (!text) throw new UsageError("usage: todo add <text> [--due YYYY-MM-DD]");
  const data = load();
  // Tasks without a due date keep the v1 shape, so v1 files stay untouched.
  const task = due ? { id: data.nextId, text, done: false, due } : { id: data.nextId, text, done: false };
  data.nextId += 1;
  data.tasks.push(task);
  save(data);
  return [`added ${task.id}`];
}

function splitDue(args) {
  const at = args.indexOf("--due");
  if (at === -1) return { words: args, due: null };
  const value = args[at + 1];
  if (value === undefined) throw new UsageError("--due needs a date (YYYY-MM-DD)");
  if (!isIsoDate(value)) throw new UsageError(`invalid date: ${value} (use YYYY-MM-DD)`);
  return { words: [...args.slice(0, at), ...args.slice(at + 2)], due: value };
}

function isIsoDate(value) {
  const m = ISO_DATE.exec(value);
  if (!m) return false;
  const date = new Date(Date.UTC(Number(m[1]), Number(m[2]) - 1, Number(m[3])));
  return date.toISOString().slice(0, 10) === value;
}

function list(args) {
  const unknown = args.find((a) => a !== "--overdue" && a !== "--json");
  if (unknown) throw new UsageError(`unknown option for list: ${unknown}`);
  let { tasks } = load();
  if (args.includes("--overdue")) {
    const now = today();
    tasks = tasks.filter((t) => !t.done && t.due && t.due < now);
  }
  if (args.includes("--json")) {
    return [JSON.stringify(tasks.map((t) => ({ id: t.id, text: t.text, done: t.done, due: t.due ?? null })), null, 2)];
  }
  if (!tasks.length) return ["no tasks"];
  return tasks.map(format);
}

function format(task) {
  const due = task.due ? ` (due ${task.due})` : "";
  return `[${task.done ? "x" : " "}] ${task.id} ${task.text}${due}`;
}

function done(args) {
  const data = load();
  const task = find(data, args);
  task.done = true;
  save(data);
  return [`done ${task.id}`];
}

function rm(args) {
  const data = load();
  const task = find(data, args);
  data.tasks = data.tasks.filter((t) => t !== task);
  save(data);
  return [`removed ${task.id}`];
}

function find(data, args) {
  const id = Number(args[0]);
  if (!Number.isInteger(id) || id < 1) throw new UsageError("usage: todo <done|rm> <id>");
  const task = data.tasks.find((t) => t.id === id);
  if (!task) throw new Error(`no task with id ${id}`);
  return task;
}
