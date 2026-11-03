import test from "node:test";
import assert from "node:assert";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { build } from "../src/build.js";

const SITE = { title: "Notes", url: "https://notes.example", description: "Short notes" };

function site(posts) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "site-"));
  const content = path.join(dir, "content");
  fs.mkdirSync(content);
  for (const [slug, text] of Object.entries(posts)) fs.writeFileSync(path.join(content, `${slug}.md`), text);
  const out = path.join(dir, "out");
  build({ contentDir: content, outDir: out, site: SITE });
  return (rel) => fs.readFileSync(path.join(out, rel), "utf8");
}

const POST = (title, date, extra = "") => `---\ntitle: ${title}\ndate: ${date}\n${extra}---\nHello *world* & \`code\`.\n`;

test("the index lists published posts newest first", () => {
  const read = site({ a: POST("Alpha", "2026-01-01"), b: POST("Beta", "2026-02-01") });
  assert.match(read("index.html"), /Beta[\s\S]*Alpha/);
});

test("posts render Markdown and escape text", () => {
  const read = site({ a: POST("A & B", "2026-01-01") });
  assert.match(read("posts/a.html"), /<h1>A &amp; B<\/h1>/);
  assert.match(read("posts/a.html"), /<p>Hello <em>world<\/em> &amp; <code>code<\/code>\.<\/p>/);
});

test("drafts are not published", () => {
  const read = site({ a: POST("Alpha", "2026-01-01"), d: POST("Draft", "2026-03-01", "draft: true\n") });
  assert.doesNotMatch(read("index.html"), /Draft/);
  assert.throws(() => read("posts/d.html"));
});

test("post pages show their tags as text", () => {
  const read = site({ a: POST("Alpha", "2026-01-01", "tags: Node.js, Café Culture\n") });
  assert.match(read("posts/a.html"), /<p class="tags">Tags: Node\.js, Café Culture<\/p>/);
});
