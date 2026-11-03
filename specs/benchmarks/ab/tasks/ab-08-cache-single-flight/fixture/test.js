import TTLCache from "./src/cache.js";
import assert from "assert";

async function runTests() {
  console.log("Running TTLCache Race Condition tests...");

  // Test 1: Basic set/get
  const cache = new TTLCache(100);
  await cache.get("a", async () => "value_a");
  assert.strictEqual(await cache.get("a"), "value_a");
  console.log("✓ Test 1 passed");

  // Test 2: TTL Expiry
  await new Promise((resolve) => setTimeout(resolve, 150));
  let fetched = false;
  const val2 = await cache.get("a", async () => {
    fetched = true;
    return "new_value";
  });
  assert.strictEqual(val2, "new_value");
  assert.strictEqual(fetched, true, "Should re-fetch after expiry");
  console.log("✓ Test 2 passed");

  // Test 3: Race Condition (Concurrent Get)
  console.log("Test 3: Concurrent Get (Exposing Race)...");
  let fetchCount = 0;
  const fetchFn = async (key) => {
    fetchCount++;
    await new Promise((resolve) => setTimeout(resolve, 50)); // simulate latency
    return `val_${key}_${fetchCount}`;
  };

  cache.clear();
  // Fire multiple concurrent requests for the same key
  const results = await Promise.all([
    cache.get("race", fetchFn),
    cache.get("race", fetchFn),
    cache.get("race", fetchFn),
  ]);

  // If fixed, fetchCount should be 1, and all results should be identical
  assert.strictEqual(
    fetchCount,
    1,
    `Fetch count should be 1, but got ${fetchCount}`
  );
  assert.strictEqual(results[0], results[1]);
  assert.strictEqual(results[1], results[2]);
  console.log("✓ Test 3 passed");

  console.log("All tests passed!");
}

runTests().catch((err) => {
  console.error("✗ Test failed:");
  console.error(err.message);
  process.exit(1);
});
