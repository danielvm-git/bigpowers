import { withRetry, RetryExhaustedError } from "./src/retry.js";
import assert from "assert";

async function runTests() {
  console.log("Running Retry with Backoff tests...");

  // Test 1: Success on first try
  console.log("Test 1: Success on first try...");
  let calls1 = 0;
  const res1 = await withRetry(async () => {
    calls1++;
    return "success";
  });
  assert.strictEqual(res1, "success");
  assert.strictEqual(calls1, 1);

  // Test 2: Success after 2 retries (3 calls total)
  console.log("Test 2: Success after retries...");
  let calls2 = 0;
  const startTime2 = Date.now();
  const res2 = await withRetry(async () => {
    calls2++;
    if (calls2 < 3) throw new Error("fail");
    return "success";
  });
  const duration2 = Date.now() - startTime2;
  assert.strictEqual(res2, "success");
  assert.strictEqual(calls2, 3);
  // Expected delays: 100ms, 200ms = 300ms total
  assert.ok(
    duration2 >= 300,
    `Duration ${duration2}ms should be at least 300ms`
  );

  // Test 3: Exhaust all retries
  console.log("Test 3: Exhaust all retries...");
  let calls3 = 0;
  try {
    await withRetry(async () => {
      calls3++;
      throw new Error("permanent fail");
    });
    assert.fail("Should have thrown RetryExhaustedError");
  } catch (err) {
    assert.ok(err instanceof RetryExhaustedError);
    assert.strictEqual(
      calls3,
      4,
      "Should have tried 4 times (initial + 3 retries)"
    );
    assert.strictEqual(err.lastError.message, "permanent fail");
  }

  console.log("All tests passed!");
}

runTests().catch((err) => {
  console.error("✗ Test failed:");
  console.error(err.message);
  process.exit(1);
});
