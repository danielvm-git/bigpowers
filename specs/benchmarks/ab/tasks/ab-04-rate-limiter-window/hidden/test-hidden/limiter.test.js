import test from "node:test";
import assert from "node:assert";
import RateLimiter from "../src/limiter.js";

test("hidden: a new window allows exactly `limit` requests again", () => {
  const l = new RateLimiter(2, 50);
  l.isAllowed();
  l.isAllowed();
  assert.strictEqual(l.isAllowed(), false);
  l.lastReset = Date.now() - 50;
  assert.strictEqual(l.isAllowed(), true);
  assert.strictEqual(l.isAllowed(), true);
  assert.strictEqual(l.isAllowed(), false);
});

test("hidden: just before the boundary is still blocked", () => {
  const l = new RateLimiter(1, 100);
  l.isAllowed();
  l.lastReset = Date.now() - 90;
  assert.strictEqual(l.isAllowed(), false);
});

test("hidden: several windows in a row each reset the count", () => {
  const l = new RateLimiter(1, 30);
  for (let i = 0; i < 3; i++) {
    assert.strictEqual(l.isAllowed(), true, `window ${i} first request`);
    assert.strictEqual(l.isAllowed(), false, `window ${i} second request`);
    l.lastReset -= 30;
  }
});

test("hidden: reset() makes requests allowed again", () => {
  const l = new RateLimiter(1, 1000);
  l.isAllowed();
  l.reset();
  assert.strictEqual(l.isAllowed(), true);
});
