import { processData } from "./src/processor.js";
import assert from "assert";

async function runTests() {
  console.log("Running Processor Refactor tests...");

  const input = {
    item1: "  Hello World  ",
    item2: 120.5,
    item3: 25,
    item4: "medium-sized",
    item5: "this is a very long string that should be categorized as long",
  };

  const result = await processData(input);

  // Assert external behavior remains unchanged
  assert.strictEqual(result.summary.totalProcessed, 5);
  assert.strictEqual(result.summary.categories.short, 2);
  assert.strictEqual(result.summary.categories.high, 1);
  assert.strictEqual(result.summary.categories.low, 1);
  assert.strictEqual(result.summary.categories.long, 1);

  assert.strictEqual(
    result.items.find((i) => i.id === "item1").normalizedValue,
    "hello world"
  );
  assert.strictEqual(result.items.find((i) => i.id === "item2").score, 180.75); // 120.5 * 1.5

  console.log("✓ External behavior verified");
  console.log("All tests passed!");
}

runTests().catch((err) => {
  console.error("✗ Test failed:");
  console.error(err.message);
  process.exit(1);
});
