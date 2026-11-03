import test from "node:test";
import assert from "node:assert";
import { withRetry, RetryExhaustedError } from "../src/retry.js";

function failingTimes(n, value = "ok") {
  let calls = 0;
  const fn = async () => {
    calls++;
    if (calls <= n) throw new Error(`fail ${calls}`);
    return value;
  };
  return { fn, calls: () => calls };
}

test("hidden: first retry waits about 100 ms (exponential, not constant)", async () => {
  const { fn, calls } = failingTimes(1);
  const start = Date.now();
  assert.strictEqual(await withRetry(fn), "ok");
  const ms = Date.now() - start;
  assert.strictEqual(calls(), 2);
  assert.ok(ms >= 95 && ms < 290, `one retry took ${ms} ms`);
});

test("hidden: exhausting retries waits 100 + 200 + 400 ms", async () => {
  const { fn, calls } = failingTimes(10);
  const start = Date.now();
  const err = await withRetry(fn).catch((e) => e);
  const ms = Date.now() - start;
  assert.ok(err instanceof RetryExhaustedError, "rejects with RetryExhaustedError");
  assert.ok(err instanceof Error);
  assert.strictEqual(calls(), 4);
  assert.strictEqual(err.lastError.message, "fail 4");
  assert.ok(ms >= 690 && ms < 1500, `exhaustion took ${ms} ms`);
});

test("hidden: the resolved value is passed through untouched", async () => {
  const value = { nested: [1, 2, 3] };
  assert.strictEqual(await withRetry(async () => value), value);
});

test("hidden: success on the last allowed attempt", async () => {
  const { fn, calls } = failingTimes(3, "late");
  assert.strictEqual(await withRetry(fn), "late");
  assert.strictEqual(calls(), 4);
});
