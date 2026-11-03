import test from "node:test";
import assert from "node:assert";
import TTLCache from "../src/cache.js";

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function slowFetch(ms) {
  const calls = {};
  const fn = async (key) => {
    calls[key] = (calls[key] || 0) + 1;
    await sleep(ms);
    return `${key}#${calls[key]}`;
  };
  return { fn, calls };
}

test("hidden: five concurrent misses share one fetch", async () => {
  const cache = new TTLCache(1000);
  const { fn, calls } = slowFetch(40);
  const values = await Promise.all(Array.from({ length: 5 }, () => cache.get("k", fn)));
  assert.strictEqual(calls.k, 1);
  assert.ok(values.every((v) => v === "k#1"));
});

test("hidden: different keys fetch in parallel", async () => {
  const cache = new TTLCache(1000);
  let active = 0;
  let maxActive = 0;
  const fn = async (key) => {
    active++;
    maxActive = Math.max(maxActive, active);
    await sleep(40);
    active--;
    return `${key}#1`;
  };
  const [a, b] = await Promise.all([cache.get("a", fn), cache.get("b", fn)]);
  assert.deepStrictEqual([a, b], ["a#1", "b#1"]);
  assert.strictEqual(maxActive, 2, "fetches for different keys must overlap (no global lock)");
});

test("hidden: a failed fetch is shared, not cached, and retried next time", async () => {
  const cache = new TTLCache(1000);
  let calls = 0;
  const flaky = async () => {
    calls++;
    await sleep(20);
    if (calls === 1) throw new Error("backend down");
    return "recovered";
  };
  const results = await Promise.allSettled([cache.get("f", flaky), cache.get("f", flaky)]);
  assert.deepStrictEqual(results.map((r) => r.status), ["rejected", "rejected"]);
  assert.strictEqual(calls, 1);
  assert.strictEqual(await cache.get("f", flaky), "recovered");
  assert.strictEqual(calls, 2);
});

test("hidden: concurrent misses after expiry refetch once", async () => {
  const cache = new TTLCache(30);
  const { fn, calls } = slowFetch(20);
  await cache.get("e", fn);
  await sleep(50);
  const values = await Promise.all([cache.get("e", fn), cache.get("e", fn), cache.get("e", fn)]);
  assert.strictEqual(calls.e, 2);
  assert.ok(values.every((v) => v === "e#2"));
});

test("hidden: fresh values are served without fetching", async () => {
  const cache = new TTLCache(1000);
  const { fn, calls } = slowFetch(5);
  await cache.get("h", fn);
  assert.strictEqual(await cache.get("h", fn), "h#1");
  assert.strictEqual(calls.h, 1);
});
