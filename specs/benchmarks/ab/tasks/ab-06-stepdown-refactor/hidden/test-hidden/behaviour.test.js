import test from "node:test";
import assert from "node:assert";
import { processData } from "../src/processor.js";
import { originalProcessData } from "./oracle.js";

const inputs = {
  mixed: { a: "  Hello World  ", b: 120.5, c: 25, d: "medium-sized", e: "x".repeat(30) },
  boundaries: { n50: 50, n50b: 50.004, n100: 100, n100b: 100.01, n101: 101, s5: "abcde", s6: "abcdef", s20: "a".repeat(20), s21: "a".repeat(21) },
  skipped: { nul: null, undef: undefined, zero: 0, empty: "", spaces: "   ", ok: 75 },
  types: { bool: true, obj: { x: 1 }, arr: [1, 2], neg: -5, float: 33.333 },
  empty: {},
};

function stable(result) {
  return JSON.parse(JSON.stringify(result, (k, v) => (k === "processedAt" ? "<time>" : v)));
}

for (const [name, input] of Object.entries(inputs)) {
  test(`hidden: same output as before for ${name} input`, async () => {
    const quiet = console.warn;
    console.warn = () => {};
    try {
      assert.deepStrictEqual(stable(await processData(input)), stable(await originalProcessData(input)));
    } finally {
      console.warn = quiet;
    }
  });
}

for (const bad of [null, undefined, "text", 42]) {
  test(`hidden: same error for ${String(bad)}`, async () => {
    await assert.rejects(() => processData(bad), { message: "Invalid input: rawData must be an object" });
  });
}
