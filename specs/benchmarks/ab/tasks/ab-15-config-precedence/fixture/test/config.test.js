import test from "node:test";
import assert from "node:assert";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { start } from "../src/index.js";
import { loadConfig } from "../src/config.js";
import { logLine } from "../src/logger.js";

function folder(config) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "shop-"));
  if (config) fs.writeFileSync(path.join(dir, "config.json"), JSON.stringify(config));
  return dir;
}

const DEFAULT_SUMMARY = [
  "app shop on 0.0.0.0:8080 (debug off)",
  "db postgres://localhost:5432/?max=10&ssl=false",
  "log level info",
  "mail from noreply@shop.test to ops@shop.test",
  "debug logging disabled",
].join("\n");

test("starts with the defaults", () => {
  assert.strictEqual(start({ cwd: folder() }), DEFAULT_SUMMARY);
});

test("config.json overrides only the keys it sets", () => {
  const config = loadConfig({ cwd: folder({ db: { host: "db1" } }) });
  assert.strictEqual(config.db.host, "db1");
  assert.strictEqual(config.db.port, 5432);
});

test("modules use the settings they are given", () => {
  const summary = start({ cwd: folder({ app: { port: 9000 }, log: { level: "debug" } }) });
  assert.match(summary, /0\.0\.0\.0:9000/);
  assert.match(summary, /\[debug\] shop: debug logging enabled/);
});

test("logger skips levels below the configured one", () => {
  const config = loadConfig({ cwd: folder({ log: { level: "warn" } }) });
  assert.strictEqual(logLine(config, "info", "x"), null);
  assert.strictEqual(logLine(config, "error", "x"), "[error] shop: x");
});
