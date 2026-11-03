// Hidden: the split must actually happen (limits stated in the task prompt).
import test from "node:test";
import assert from "node:assert";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const SRC = path.join(path.dirname(fileURLToPath(import.meta.url)), "../src");
const ENTRY = path.join(SRC, "orders.js");
const PUBLIC_API = ["formatInvoice", "formatMoney", "parseOrder", "priceOrder", "processOrder"];

function jsFiles(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) return jsFiles(full);
    return /\.(js|mjs)$/.test(entry.name) ? [full] : [];
  });
}

const codeLines = (file) => fs.readFileSync(file, "utf8").split("\n").filter((l) => l.trim()).length;
const files = jsFiles(SRC);
const modules = files.filter((f) => f !== ENTRY);
const defines = (name) =>
  files.filter((f) => new RegExp(`function\\s+${name}\\s*\\(|(?:const|let|var)\\s+${name}\\s*=`).test(fs.readFileSync(f, "utf8")));

test("orders.js is only the entry point (at most 40 lines)", () => {
  assert.ok(codeLines(ENTRY) <= 40, `src/orders.js has ${codeLines(ENTRY)} non-blank lines`);
});

test("at least four new modules under src/", () => {
  assert.ok(modules.length >= 4, `found ${modules.length}: ${modules.map((f) => path.relative(SRC, f)).join(", ")}`);
});

test("no module is longer than 100 lines", () => {
  const long = modules.filter((f) => codeLines(f) > 100).map((f) => `${path.relative(SRC, f)} (${codeLines(f)})`);
  assert.deepStrictEqual(long, []);
});

test("parsing, pricing and formatting live in different modules", () => {
  const homes = ["parseOrder", "priceOrder", "formatInvoice"].map((name) => {
    const found = defines(name);
    assert.strictEqual(found.length, 1, `${name} should be defined in exactly one file, found ${found.length}`);
    return found[0];
  });
  assert.strictEqual(new Set(homes).size, 3, homes.map((f) => path.relative(SRC, f)).join(", "));
});

test("the public API of src/orders.js is unchanged", async () => {
  const api = await import(ENTRY);
  assert.deepStrictEqual(Object.keys(api).sort(), PUBLIC_API);
});
