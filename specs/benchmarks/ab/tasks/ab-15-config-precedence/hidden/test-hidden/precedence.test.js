// Hidden: docs/CONFIG.md, every stated rule plus the two that appear only in its examples.
import test from "node:test";
import assert from "node:assert";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { start } from "../src/index.js";
import { loadConfig } from "../src/config.js";

function folder(config, name = "config.json") {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "shop-h-"));
  if (config) fs.writeFileSync(path.join(dir, name), JSON.stringify(config));
  return dir;
}

const load = (opts) => loadConfig({ argv: [], env: {}, ...opts, cwd: opts?.cwd ?? folder() });
const DEFAULT_SUMMARY = [
  "app shop on 0.0.0.0:8080 (debug off)",
  "db postgres://localhost:5432/?max=10&ssl=false",
  "log level info",
  "mail from noreply@shop.test to ops@shop.test",
  "debug logging disabled",
].join("\n");

test("no sources: the startup summary is unchanged", () => {
  assert.strictEqual(start({ argv: [], env: {}, cwd: folder() }), DEFAULT_SUMMARY);
});

test("--config <path> reads that file, relative to the working folder", () => {
  const cwd = folder({ db: { host: "from-other" } }, "other.json");
  assert.strictEqual(load({ cwd, argv: ["--config", "other.json"] }).db.host, "from-other");
});

test("--config=<path> works too, and replaces config.json", () => {
  const cwd = folder({ db: { host: "default-file" } });
  fs.writeFileSync(path.join(cwd, "alt.json"), JSON.stringify({ db: { port: 7000 } }));
  const config = load({ cwd, argv: ["--config=alt.json"] });
  assert.strictEqual(config.db.port, 7000);
  assert.strictEqual(config.db.host, "localhost");
});

test("a missing --config file is an error; a missing config.json is not", () => {
  assert.throws(() => load({ argv: ["--config", "nope.json"] }), { message: "config file not found: nope.json" });
  assert.doesNotThrow(() => load({}));
});

test("env APP_DB__PORT becomes a number", () => {
  assert.strictEqual(load({ env: { APP_DB__PORT: "6543" } }).db.port, 6543);
});

test("env names map to camelCase keys (APP_DB__MAX_CONNECTIONS)", () => {
  assert.strictEqual(load({ env: { APP_DB__MAX_CONNECTIONS: "50" } }).db.maxConnections, 50);
});

test("an empty env value is ignored and the file value stays", () => {
  const cwd = folder({ log: { level: "warn" } });
  assert.strictEqual(load({ cwd, env: { APP_LOG__LEVEL: "" } }).log.level, "warn");
});

test("booleans accept true/false/1/0 in any case", () => {
  assert.strictEqual(load({ env: { APP_APP__DEBUG: "TRUE" } }).app.debug, true);
  assert.strictEqual(load({ env: { APP_DB__SSL: "1" } }).db.ssl, true);
  assert.strictEqual(load({ env: { APP_DB__SSL: "False" } }).db.ssl, false);
});

test("a bad boolean is an error", () => {
  assert.throws(() => load({ env: { APP_DB__SSL: "yes" } }), { message: "invalid boolean for db.ssl: yes" });
});

test("numbers must be whole numbers", () => {
  assert.throws(() => load({ env: { APP_DB__PORT: "12x" } }), { message: "invalid number for db.port: 12x" });
  assert.throws(() => load({ env: { APP_DB__PORT: "1.5" } }), { message: "invalid number for db.port: 1.5" });
});

test("lists are comma-separated with spaces trimmed", () => {
  const config = load({ env: { APP_MAILER__RECIPIENTS: "a@x.test, b@x.test ,c@x.test" } });
  assert.deepStrictEqual([...config.mailer.recipients], ["a@x.test", "b@x.test", "c@x.test"]);
});

test("--set beats env, env beats the file, the file beats the defaults", () => {
  const cwd = folder({ db: { host: "file", port: 1111 }, log: { level: "warn" } });
  const config = load({ cwd, env: { APP_DB__HOST: "env", APP_DB__PORT: "2222" }, argv: ["--set", "db.host=flag"] });
  assert.strictEqual(config.db.host, "flag");
  assert.strictEqual(config.db.port, 2222);
  assert.strictEqual(config.log.level, "warn");
  assert.strictEqual(config.db.maxConnections, 10);
});

test("--set can be repeated and is typed", () => {
  const config = load({ argv: ["--set", "db.port=7777", "--set", "app.debug=true"] });
  assert.strictEqual(config.db.port, 7777);
  assert.strictEqual(config.app.debug, true);
});

test("unknown keys are errors from every source", () => {
  assert.throws(() => load({ env: { APP_DB__HOTS: "x" } }), { message: "unknown config key: db.hots" });
  assert.throws(() => load({ cwd: folder({ db: { hots: "x" } }) }), { message: "unknown config key: db.hots" });
  assert.throws(() => load({ argv: ["--set", "cache.size=3"] }), { message: "unknown config key: cache.size" });
});

test("variables without the APP_ prefix are ignored", () => {
  assert.strictEqual(start({ argv: [], env: { PATH: "/usr/bin", DB__PORT: "1" }, cwd: folder() }), DEFAULT_SUMMARY);
});

test("file values must already have the right type", () => {
  assert.throws(() => load({ cwd: folder({ db: { port: "5432" } }) }), { message: "invalid type for db.port" });
});

test("the result is frozen, nested objects included", () => {
  const config = load({});
  assert.ok(Object.isFrozen(config) && Object.isFrozen(config.db) && Object.isFrozen(config.mailer.recipients));
});

test("every module sees the merged settings", () => {
  const summary = start({
    cwd: folder({ app: { name: "store" } }),
    env: { APP_DB__HOST: "db.internal", APP_APP__PORT: "9090", APP_MAILER__RECIPIENTS: "a@x.test, b@x.test" },
    argv: ["--set", "log.level=debug"],
  });
  assert.strictEqual(summary, [
    "app store on 0.0.0.0:9090 (debug off)",
    "db postgres://db.internal:5432/?max=10&ssl=false",
    "log level debug",
    "mail from noreply@shop.test to a@x.test, b@x.test",
    "[debug] store: debug logging enabled",
  ].join("\n"));
});
