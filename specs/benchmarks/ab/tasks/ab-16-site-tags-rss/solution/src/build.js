import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parsePost } from "./frontmatter.js";
import { blocks, toHtml } from "./markdown.js";
import { escapeHtml, render } from "./template.js";

const TEMPLATES = path.join(path.dirname(fileURLToPath(import.meta.url)), "../templates");

// Builds the site: index.html and posts/<slug>.html from contentDir/*.md. Drafts are skipped.
// Returns the written paths, relative to outDir.
export function build({ contentDir, outDir, site }) {
  const posts = loadPosts(contentDir);
  const written = [];
  const write = (rel, html) => {
    fs.mkdirSync(path.dirname(path.join(outDir, rel)), { recursive: true });
    fs.writeFileSync(path.join(outDir, rel), html);
    written.push(rel);
  };
  const page = template("page.html");
  for (const post of posts) {
    write(`posts/${post.slug}.html`, render(page, {
      siteTitle: site.title, title: post.title, date: post.date,
      tags: post.tags.length ? `<p class="tags">Tags: ${escapeHtml(post.tags.join(", "))}</p>` : "",
      body: toHtml(post.body),
    }));
  }
  const items = posts.map((p) =>
    `<li><a href="posts/${p.slug}.html">${escapeHtml(p.title)}</a> <time>${p.date}</time></li>`).join("\n");
  write("index.html", render(template("index.html"), { siteTitle: site.title, items }));
  writeTags(posts, site, write);
  write("feed.xml", feed(posts, site));
  return written;
}

// Lower case, accents dropped, every other run of characters -> "-", no "-" at the ends.
export function tagSlug(tag) {
  return tag.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase()
    .replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
}

// Tags by slug, in post order (newest first), so the first spelling seen is the newest post's.
function tagsOf(posts) {
  const tags = new Map();
  for (const post of posts) {
    for (const name of post.tags) {
      const slug = tagSlug(name);
      if (!slug) continue;
      if (!tags.has(slug)) tags.set(slug, { slug, name, posts: [] });
      const tag = tags.get(slug);
      if (!tag.posts.includes(post)) tag.posts.push(post);
    }
  }
  return [...tags.values()].sort((a, b) => (a.slug < b.slug ? -1 : a.slug > b.slug ? 1 : 0));
}

function writeTags(posts, site, write) {
  const tags = tagsOf(posts);
  const page = template("tag.html");
  for (const tag of tags) {
    const items = tag.posts.map((p) =>
      `<li><a href="../posts/${p.slug}.html">${escapeHtml(p.title)}</a> <time>${p.date}</time></li>`).join("\n");
    write(`tags/${tag.slug}.html`, render(page, { siteTitle: site.title, tag: tag.name, items }));
  }
  const items = tags.map((t) => `<li><a href="${t.slug}.html">${escapeHtml(t.name)}</a> (${t.posts.length})</li>`).join("\n");
  write("tags/index.html", render(template("index.html"), { siteTitle: site.title, items }));
}

function escapeXml(text) {
  return String(text).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;").replace(/'/g, "&apos;");
}

function rfc822(date) {
  const [y, m, d] = date.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, d)).toUTCString().replace("GMT", "+0000");
}

function plainFirstParagraph(body) {
  const first = blocks(body).find((b) => !/^#{1,3} /.test(b)) || "";
  return first.replace(/\n/g, " ").replace(/\*\*|\*|`/g, "");
}

function feed(posts, site) {
  const base = site.url.replace(/\/+$/, "");
  const items = posts.slice(0, 20).map((p) => {
    const link = `${base}/posts/${p.slug}.html`;
    return ["<item>", `<title>${escapeXml(p.title)}</title>`, `<link>${escapeXml(link)}</link>`,
      `<guid isPermaLink="true">${escapeXml(link)}</guid>`, `<pubDate>${rfc822(p.date)}</pubDate>`,
      `<description>${escapeXml(p.summary ?? plainFirstParagraph(p.body))}</description>`, "</item>"].join("\n");
  });
  return ['<?xml version="1.0" encoding="UTF-8"?>', '<rss version="2.0">', "<channel>",
    `<title>${escapeXml(site.title)}</title>`, `<link>${escapeXml(base)}/</link>`,
    `<description>${escapeXml(site.description ?? "")}</description>`, ...items, "</channel>", "</rss>", ""].join("\n");
}

// Published posts, newest first; posts on the same date sort by title.
export function loadPosts(contentDir) {
  return fs.readdirSync(contentDir)
    .filter((f) => f.endsWith(".md"))
    .map((f) => ({ slug: f.slice(0, -3), ...parsePost(fs.readFileSync(path.join(contentDir, f), "utf8")) }))
    .filter((p) => !p.draft)
    .sort((a, b) => (a.date === b.date ? a.title.localeCompare(b.title) : a.date < b.date ? 1 : -1));
}

export function template(name) {
  return fs.readFileSync(path.join(TEMPLATES, name), "utf8");
}
