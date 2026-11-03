import RateLimiter from "./src/limiter.js";
import assert from "assert";

async function runTests() {
  console.log("Running RateLimiter tests...");

  // Test 1: Allow requests up to limit
  const limiter = new RateLimiter(2, 100);
  assert.strictEqual(limiter.isAllowed(), true, "Should allow 1st request");
  assert.strictEqual(limiter.isAllowed(), true, "Should allow 2nd request");
  assert.strictEqual(limiter.isAllowed(), false, "Should block 3rd request");
  console.log("✓ Test 1 passed");

  // Test 2: Block requests at limit
  assert.strictEqual(limiter.isAllowed(), false, "Should still block at limit");
  console.log("✓ Test 2 passed");

  // Test 3: Reset after window expires
  // We need to wait for the window to expire
  await new Promise((resolve) => setTimeout(resolve, 150));
  assert.strictEqual(
    limiter.isAllowed(),
    true,
    "Should allow request after window expires"
  );
  console.log("✓ Test 3 passed");

  // Test 4: Burst within limit
  limiter.reset();
  assert.strictEqual(limiter.isAllowed(), true, "Burst 1");
  assert.strictEqual(limiter.isAllowed(), true, "Burst 2");
  assert.strictEqual(limiter.isAllowed(), false, "Burst 3 (block)");
  console.log("✓ Test 4 passed");

  // Test 5: Boundary condition (precisely at windowMs)
  // This is hard to test precisely with setTimeout, but we can simulate it
  const preciseLimiter = new RateLimiter(1, 100);
  preciseLimiter.isAllowed(); // use up the limit
  preciseLimiter.lastReset = Date.now() - 100; // exactly at windowMs
  assert.strictEqual(
    preciseLimiter.isAllowed(),
    true,
    "Should allow exactly at windowMs"
  );
  console.log("✓ Test 5 passed");

  console.log("All tests passed!");
}

runTests().catch((err) => {
  console.error("✗ Test failed:");
  console.error(err.message);
  process.exit(1);
});
