import { fork } from "child_process";
import http from "http";
import assert from "assert";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function fetchJson(url) {
  return new Promise((resolve, reject) => {
    http
      .get(url, (res) => {
        let data = "";
        res.on("data", (chunk) => (data += chunk));
        res.on("end", () => {
          resolve({
            status: res.statusCode,
            headers: res.headers,
            body: JSON.parse(data),
          });
        });
      })
      .on("error", reject);
  });
}

async function runTests() {
  console.log("Starting T02 Pagination tests...");

  const child = fork(path.join(__dirname, "src/server.js"), { stdio: "pipe" });

  const port = await new Promise((resolve) => {
    child.on("message", (msg) => {
      if (msg.port) resolve(msg.port);
    });
  });

  const baseUrl = `http://localhost:${port}`;

  try {
    // Test 1: Default pagination (page 1, limit 10)
    console.log("Test 1: Default pagination...");
    const res1 = await fetchJson(`${baseUrl}/users`);
    assert.strictEqual(
      res1.body.length,
      10,
      "Should return 10 users by default"
    );
    assert.strictEqual(res1.body[0].id, 1, "First user ID should be 1");
    assert.strictEqual(
      res1.headers["x-total-count"],
      "50",
      "Should have X-Total-Count: 50"
    );

    // Test 2: Custom limit
    console.log("Test 2: Custom limit...");
    const res2 = await fetchJson(`${baseUrl}/users?limit=5`);
    assert.strictEqual(res2.body.length, 5, "Should return 5 users");

    // Test 3: Custom page
    console.log("Test 3: Custom page...");
    const res3 = await fetchJson(`${baseUrl}/users?page=2&limit=10`);
    assert.strictEqual(res3.body.length, 10);
    assert.strictEqual(
      res3.body[0].id,
      11,
      "First user on page 2 should be ID 11"
    );

    // Test 4: Last page
    console.log("Test 4: Last page...");
    const res4 = await fetchJson(`${baseUrl}/users?page=5&limit=10`);
    assert.strictEqual(res4.body.length, 10);
    assert.strictEqual(
      res4.body[9].id,
      50,
      "Last user on page 5 should be ID 50"
    );

    // Test 5: Out of bounds
    console.log("Test 5: Out of bounds...");
    const res5 = await fetchJson(`${baseUrl}/users?page=6&limit=10`);
    assert.strictEqual(
      res5.body.length,
      0,
      "Should return empty array for page 6"
    );

    console.log("All tests passed!");
  } finally {
    child.kill();
  }
}

runTests().catch((err) => {
  console.error("✗ Test failed:");
  console.error(err.message);
  process.exit(1);
});
