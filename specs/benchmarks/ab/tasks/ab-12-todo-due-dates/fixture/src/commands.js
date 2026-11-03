import { load, save } from "./store.js";

export class UsageError extends Error {}

const COMMANDS = { add, list, done, rm };

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
  const text = args.join(" ").trim();
  if (!text) throw new UsageError("usage: todo add <text>");
  const data = load();
  const task = { id: data.nextId, text, done: false };
  data.nextId += 1;
  data.tasks.push(task);
  save(data);
  return [`added ${task.id}`];
}

function list(args) {
  if (args.length) throw new UsageError(`unknown option for list: ${args[0]}`);
  const { tasks } = load();
  if (!tasks.length) return ["no tasks"];
  return tasks.map(format);
}

function format(task) {
  return `[${task.done ? "x" : " "}] ${task.id} ${task.text}`;
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
