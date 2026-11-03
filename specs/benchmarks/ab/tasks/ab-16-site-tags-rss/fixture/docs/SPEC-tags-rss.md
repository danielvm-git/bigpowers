# Tag pages and an RSS feed

`build()` gains three outputs. **Nothing else changes: `index.html` and every `posts/*.html` must
stay byte-for-byte what they are today.** (Linking the tags on post pages is a separate issue.)

Everything below uses only published posts: drafts never appear in a tag page, the tag index or
the feed, and never count. Posts are ordered as on the home page: newest first, and posts on the
same date by title.

## Tag slugs

A tag's slug is its name in lower case, with accented letters written as plain letters, and every
run of other characters turned into a single `-`, with no `-` at either end:

| Tag | Slug |
|---|---|
| `JavaScript` | `javascript` |
| `Node.js` | `node-js` |
| `Café Culture` | `cafe-culture` |
| ` Static  Sites! ` | `static-sites` |

Tags with the same slug are the same tag. A tag is shown with the spelling used by its newest post.

## 1. Tag pages — `tags/<slug>.html`

One page per tag, using `templates/tag.html` (`tag` is the tag's spelling, `items` the list). Each
item is `<li><a href="../posts/<post-slug>.html">Title</a> <time>YYYY-MM-DD</time></li>`, with the
title HTML-escaped.

## 2. Tag index — `tags/index.html`

Every tag, sorted by slug, as `<li><a href="<slug>.html">Tag</a> (<count>)</li>`, where count is the
number of published posts with the tag. Use `templates/index.html` with the site title. With no tags
the list is empty but the page still exists.

## 3. RSS 2.0 feed — `feed.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
<channel>
<title>…site title…</title>
<link>…site url…/</link>
<description>…site description…</description>
<item>
<title>…</title>
<link>…site url…/posts/<post-slug>.html</link>
<guid isPermaLink="true">…same as link…</guid>
<pubDate>Tue, 03 Nov 2026 00:00:00 +0000</pubDate>
<description>…</description>
</item>
</channel>
</rss>
```

- The newest 20 posts, in post order.
- `pubDate` is the post date at midnight UTC in RFC-822 format, as in the example.
- An item's description is the post's `summary` front matter, or else the plain text of its first
  paragraph (no Markdown markers).
- All text is XML-escaped.
- `site.url` may or may not end with `/`; links must not get a double `/`.
