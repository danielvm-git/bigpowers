import test, { before, after } from "node:test";
import assert from "node:assert";
import { fork } from "node:child_process";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), "..");
let child;
let baseUrl;

function get(route) {
  return new Promise((resolve, reject) => {
    http
      .get(baseUrl + route, (res) => {
        let data = "";
        res.on("data", (c) => (data += c));
        res.on("end", () => resolve({ headers: res.headers, body: JSON.parse(data) }));
      })
      .on("error", reject);
  });
}

before(async () => {
  child = fork(path.join(root, "src/server.js"), { stdio: "pipe" });
  const port = await new Promise((resolve) => child.on("message", (m) => m.port && resolve(m.port)));
  baseUrl = `http://localhost:${port}`;
});

after(() => child.kill());

const ids = (body) => body.map((u) => u.id);

test("hidden: partial last page", async () => {
  const res = await get("/users?page=17&limit=3");
  assert.deepStrictEqual(ids(res.body), [49, 50]);
});

test("hidden: large limit on a later page", async () => {
  const res = await get("/users?page=3&limit=20");
  assert.deepStrictEqual(ids(res.body), [41, 42, 43, 44, 45, 46, 47, 48, 49, 50]);
});

test("hidden: page without limit uses the default limit of 10", async () => {
  const res = await get("/users?page=2");
  assert.deepStrictEqual(ids(res.body), [11, 12, 13, 14, 15, 16, 17, 18, 19, 20]);
});

test("hidden: limit covering everything returns all users", async () => {
  const res = await get("/users?limit=50");
  assert.strictEqual(res.body.length, 50);
});

test("hidden: empty page still carries X-Total-Count", async () => {
  const res = await get("/users?page=9&limit=10");
  assert.deepStrictEqual(res.body, []);
  assert.strictEqual(res.headers["x-total-count"], "50");
});

test("hidden: users keep their fields", async () => {
  const res = await get("/users?limit=1");
  assert.deepStrictEqual(res.body[0], { id: 1, name: "User 1", email: "user1@example.com" });
});
