import fs from "node:fs";

// The todo file: TODO_FILE, or todo.json in the current folder.
function file() {
  return process.env.TODO_FILE || "todo.json";
}

export function load() {
  if (!fs.existsSync(file())) return { version: 1, nextId: 1, tasks: [] };
  return JSON.parse(fs.readFileSync(file(), "utf8"));
}

export function save(data) {
  fs.writeFileSync(file(), JSON.stringify(data, null, 2) + "\n");
}
