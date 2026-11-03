// Hidden: docs/SPEC-tags-rss.md. Existing pages are compared byte for byte with the original
// generator (oracle/). The corpus covers case-merged and accented tags, a draft-only tag,
// escaping, same-date ties, summaries, a post that opens with a heading and more than 20 posts.
import test from "node:test";
import assert from "node:assert";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { build } from "../src/build.js";
import { build as oracleBuild } from "./oracle/src/build.js";

const SITE = { title: "Notes & Ideas", url: "https://notes.example", description: "Short <notes>" };

function corpus() {
  const posts = {
    "js-old": ["Old JS", "2026-01-05", "javascript, Node.js", "", "First *old* post."],
    "js-new": ["New JS", "2026-03-10", "JavaScript", "", "Second post with `code`."],
    "cafe": ["Coffee", "2026-02-01", "Café Culture", "A summary & more", "Body text."],
    "tips": ["Tips & Tricks <2026>", "2026-03-10", "Node.js,  Static  Sites! ", "", "# Heading first\n\nThe *real* first\nparagraph & more."],
    "draft": ["Secret", "2026-04-01", "Secret Plans, JavaScript", "", "Hidden.", true],
    "plain": ["No Tags", "2026-02-15", "", "", "Just text."],
  };
  for (let i = 1; i <= 20; i++) {
    const day = String(i).padStart(2, "0");
    posts[`filler-${day}`] = [`Filler ${day}`, `2025-06-${day}`, i % 2 ? "Node.js" : "", "", `Filler body ${i}.`];
  }
  return posts;
}

function write(dir, posts) {
  fs.mkdirSync(dir);
  for (const [slug, [title, date, tags, summary, body, draft]] of Object.entries(posts)) {
    const fm = [`title: ${title}`, `date: ${date}`, tags && `tags: ${tags}`, summary && `summary: ${summary}`, draft && "draft: true"];
    fs.writeFileSync(path.join(dir, `${slug}.md`), `---\n${fm.filter(Boolean).join("\n")}\n---\n${body}\n`);
  }
}

function builds(site = SITE) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "site-h-"));
  const content = path.join(root, "content");
  write(content, corpus());
  build({ contentDir: content, outDir: path.join(root, "new"), site });
  oracleBuild({ contentDir: content, outDir: path.join(root, "old"), site });
  const reader = (side) => (rel) => fs.readFileSync(path.join(root, side, rel), "utf8");
  return { read: reader("new"), old: reader("old"), exists: (rel) => fs.existsSync(path.join(root, "new", rel)), root };
}

const B = builds();
const items = (html) => [...html.matchAll(/<li>[\s\S]*?<\/li>/g)].map((m) => m[0]);
const feedItems = () => [...B.read("feed.xml").matchAll(/<item>([\s\S]*?)<\/item>/g)].map((m) => m[1]);
const field = (item, name) => (new RegExp(`<${name}[^>]*>([\\s\\S]*?)</${name}>`).exec(item) || [])[1];

test("index.html and every post page are byte-for-byte unchanged", () => {
  const posts = fs.readdirSync(path.join(B.root, "old", "posts"));
  for (const rel of ["index.html", ...posts.map((p) => `posts/${p}`)]) assert.strictEqual(B.read(rel), B.old(rel), rel);
  assert.deepStrictEqual(fs.readdirSync(path.join(B.root, "new", "posts")).sort(), posts.sort());
});

test("one tag page per published tag, named by slug", () => {
  for (const slug of ["javascript", "node-js", "cafe-culture", "static-sites"]) assert.ok(B.exists(`tags/${slug}.html`), slug);
});

test("a tag used only by drafts gets no page", () => {
  assert.ok(!B.exists("tags/secret-plans.html"));
});

test("tags that differ only in case are one tag, shown with the newest post's spelling", () => {
  const page = B.read("tags/javascript.html");
  assert.match(page, /<h1>Posts tagged JavaScript<\/h1>/);
  assert.strictEqual(items(page).length, 2);
});

test("a tag page lists its posts newest first, same-date posts by title, with ../posts links", () => {
  const list = items(B.read("tags/node-js.html"));
  assert.match(list[0], /^<li><a href="\.\.\/posts\/tips\.html">Tips &amp; Tricks &lt;2026&gt;<\/a> <time>2026-03-10<\/time><\/li>$/);
  assert.match(list[1], /js-old\.html/);
  assert.strictEqual(list.length, 12);
});

test("the tag index lists every tag by slug with published counts", () => {
  assert.deepStrictEqual(items(B.read("tags/index.html")), [
    '<li><a href="cafe-culture.html">Café Culture</a> (1)</li>',
    '<li><a href="javascript.html">JavaScript</a> (2)</li>',
    '<li><a href="node-js.html">Node.js</a> (12)</li>',
    '<li><a href="static-sites.html">Static  Sites!</a> (1)</li>',
  ]);
});

test("the tag index exists even with no tags", () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "site-e-"));
  write(path.join(root, "c"), { a: ["A", "2026-01-01", "", "", "x"] });
  build({ contentDir: path.join(root, "c"), outDir: path.join(root, "o"), site: SITE });
  assert.deepStrictEqual(items(fs.readFileSync(path.join(root, "o", "tags", "index.html"), "utf8")), []);
});

test("the feed is RSS 2.0 with the escaped channel fields", () => {
  const feed = B.read("feed.xml");
  assert.match(feed, /^<\?xml version="1\.0" encoding="UTF-8"\?>\s*<rss version="2\.0">\s*<channel>/);
  assert.match(feed, /<title>Notes &amp; Ideas<\/title>\s*<link>https:\/\/notes\.example\/<\/link>\s*<description>Short &lt;notes&gt;<\/description>/);
  assert.doesNotMatch(feed, /&(?!amp;|lt;|gt;|quot;|apos;|#\d+;)/);
});

test("the feed holds the newest 20 published posts in post order", () => {
  const titles = feedItems().map((i) => field(i, "title"));
  assert.strictEqual(titles.length, 20);
  assert.deepStrictEqual(titles.slice(0, 5), ["New JS", "Tips &amp; Tricks &lt;2026&gt;", "No Tags", "Coffee", "Old JS"]);
  assert.ok(!titles.includes("Secret"));
});

test("pubDate is RFC-822 at midnight UTC", () => {
  assert.strictEqual(field(feedItems()[0], "pubDate"), "Tue, 10 Mar 2026 00:00:00 +0000");
});

test("links and guids are absolute permalinks without a double slash", () => {
  for (const site of [SITE, { ...SITE, url: "https://notes.example/" }]) {
    const feed = builds(site).read("feed.xml");
    const item = /<item>([\s\S]*?)<\/item>/.exec(feed)[1];
    assert.strictEqual(field(item, "link"), "https://notes.example/posts/js-new.html");
    assert.match(item, /<guid isPermaLink="true">https:\/\/notes\.example\/posts\/js-new\.html<\/guid>/);
    assert.match(feed, /<link>https:\/\/notes\.example\/<\/link>/);
  }
});

test("description is the summary, else the first paragraph as plain text", () => {
  const byTitle = Object.fromEntries(feedItems().map((i) => [field(i, "title"), field(i, "description")]));
  assert.strictEqual(byTitle["Coffee"], "A summary &amp; more");
  assert.strictEqual(byTitle["New JS"], "Second post with code.");
  assert.strictEqual(byTitle["Tips &amp; Tricks &lt;2026&gt;"], "The real first paragraph &amp; more.");
});
