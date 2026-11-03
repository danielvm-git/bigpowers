import fs from "node:fs";
import path from "node:path";
import { DEFAULTS } from "./defaults.js";

// Reads config.json from the working folder over the defaults.
export function loadConfig({ cwd = process.cwd() } = {}) {
  const file = path.join(cwd, "config.json");
  const fromFile = fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, "utf8")) : {};
  return merge(DEFAULTS, fromFile);
}

function merge(base, over) {
  const out = {};
  for (const [key, value] of Object.entries(base)) {
    const next = over[key];
    out[key] = isObject(value) && isObject(next) ? merge(value, next) : next ?? value;
  }
  return out;
}

function isObject(v) {
  return v !== null && typeof v === "object" && !Array.isArray(v);
}
