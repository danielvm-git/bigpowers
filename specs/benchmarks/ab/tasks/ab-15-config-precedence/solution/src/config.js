import fs from "node:fs";
import path from "node:path";
import { DEFAULTS } from "./defaults.js";

// Settings from defaults < config file < APP_* env < --set flags (docs/CONFIG.md). Frozen.
export function loadConfig({ argv = [], env = {}, cwd = process.cwd() } = {}) {
  const flags = parseArgs(argv);
  const config = structuredClone(DEFAULTS);
  applyFile(config, readFile(flags.file, cwd));
  for (const [name, value] of Object.entries(env)) {
    if (!name.startsWith("APP_") || value === "") continue;
    setKey(config, envKey(name), value);
  }
  for (const [key, value] of flags.sets) setKey(config, key, value);
  return deepFreeze(config);
}

function parseArgs(argv) {
  const flags = { file: null, sets: [] };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--config") flags.file = argv[++i];
    else if (arg.startsWith("--config=")) flags.file = arg.slice("--config=".length);
    else if (arg === "--set") flags.sets.push(splitSet(argv[++i] ?? ""));
    else if (arg.startsWith("--set=")) flags.sets.push(splitSet(arg.slice("--set=".length)));
  }
  return flags;
}

function splitSet(pair) {
  const at = pair.indexOf("=");
  return at === -1 ? [pair, ""] : [pair.slice(0, at), pair.slice(at + 1)];
}

function readFile(named, cwd) {
  const file = path.resolve(cwd, named ?? "config.json");
  if (!fs.existsSync(file)) {
    if (named) throw new Error(`config file not found: ${named}`);
    return {};
  }
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

// APP_DB__MAX_CONNECTIONS -> db.maxConnections
function envKey(name) {
  return name.slice(4).split("__")
    .map((part) => part.toLowerCase().replace(/_([a-z0-9])/g, (_, c) => c.toUpperCase()))
    .join(".");
}

function applyFile(config, fromFile, prefix = "") {
  for (const [name, value] of Object.entries(fromFile)) {
    const key = prefix + name;
    const current = defaultAt(key);
    if (isObject(current) && isObject(value)) applyFile(config, value, `${key}.`);
    else {
      if (!sameType(current, value)) throw new Error(`invalid type for ${key}`);
      assign(config, key, value);
    }
  }
}

function setKey(config, key, raw) {
  assign(config, key, coerce(key, defaultAt(key), raw));
}

function defaultAt(key) {
  let node = DEFAULTS;
  for (const part of key.split(".")) {
    if (!isObject(node) || !(part in node)) throw new Error(`unknown config key: ${key}`);
    node = node[part];
  }
  return node;
}

function coerce(key, current, raw) {
  if (isObject(current)) throw new Error(`unknown config key: ${key}`);
  if (typeof current === "number") {
    if (!/^-?\d+$/.test(raw.trim())) throw new Error(`invalid number for ${key}: ${raw}`);
    return Number(raw);
  }
  if (typeof current === "boolean") {
    const v = raw.trim().toLowerCase();
    if (v === "true" || v === "1") return true;
    if (v === "false" || v === "0") return false;
    throw new Error(`invalid boolean for ${key}: ${raw}`);
  }
  if (Array.isArray(current)) return raw.split(",").map((s) => s.trim()).filter(Boolean);
  return raw;
}

function sameType(current, value) {
  if (Array.isArray(current)) return Array.isArray(value) && value.every((v) => typeof v === "string");
  if (typeof current === "number") return Number.isInteger(value);
  return typeof value === typeof current && !isObject(value);
}

function assign(config, key, value) {
  const parts = key.split(".");
  const last = parts.pop();
  let node = config;
  for (const part of parts) node = node[part];
  node[last] = value;
}

function deepFreeze(value) {
  if (value && typeof value === "object") Object.values(value).forEach(deepFreeze);
  return Object.freeze(value);
}

function isObject(v) {
  return v !== null && typeof v === "object" && !Array.isArray(v);
}
