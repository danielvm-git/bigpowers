import test from "node:test";
import assert from "node:assert";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const file = path.join(path.dirname(fileURLToPath(import.meta.url)), "../src/processor.js");
const source = fs.readFileSync(file, "utf8");
const lines = source.split("\n");

// Function declarations and arrow/function expressions bound to a const at top level.
const DECL = /^(?:export\s+)?(?:async\s+)?function\s+(\w+)|^(?:export\s+)?const\s+(\w+)\s*=\s*(?:async\s*)?(?:function\b|\([^)]*\)\s*=>|\w+\s*=>)/;
const declared = lines
  .map((line, index) => ({ match: line.match(DECL), index }))
  .filter(({ match }) => match)
  .map(({ match, index }) => ({ name: match[1] || match[2], index }));

function bodyLines(startIndex) {
  let depth = 0;
  let opened = false;
  let count = 0;
  for (let i = startIndex; i < lines.length; i++) {
    for (const ch of lines[i]) {
      if (ch === "{") { depth++; opened = true; }
      if (ch === "}") depth--;
    }
    if (opened && i > startIndex && depth > 0 && lines[i].trim()) count++;
    if (opened && depth === 0) return count;
  }
  return count;
}

test("hidden: processData is the first function in the file", () => {
  assert.ok(declared.length > 0, "no functions found");
  assert.strictEqual(declared[0].name, "processData");
});

test("hidden: processData body is at most 15 lines", () => {
  const n = bodyLines(declared[0].index);
  assert.ok(n <= 15, `processData body has ${n} non-blank lines`);
});

test("hidden: processData calls at least three helpers defined below it", () => {
  const helpers = declared.slice(1).map((d) => d.name);
  const end = declared[1] ? declared[1].index : lines.length;
  const body = lines.slice(declared[0].index + 1, end).join("\n");
  const called = helpers.filter((name) => new RegExp(`\\b${name}\\s*\\(`).test(body) || new RegExp(`\\b${name}\\b`).test(body));
  assert.ok(called.length >= 3, `processData uses ${called.length} helpers: ${called.join(", ")}`);
});
