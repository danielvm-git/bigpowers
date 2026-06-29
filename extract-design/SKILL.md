---
name: extract-design
description: "Extract a Google DESIGN.md file from an HTML prototype (claude.ai/design or any styled page) using Puppeteer, producing machine-readable tokens and AI-generated prose. Use when the user has an HTML prototype and wants a DESIGN.md to anchor their project's visual identity, or when seed-conventions has just scaffolded a new project."
model: sonnet
---

# Extract DESIGN.md from HTML

> **HARD GATE** — Do NOT write DESIGN.md without Puppeteer dual-pass extraction. Tokens from static HTML (Cheerio, regex, string scanning) are invalid — they miss cascade, custom properties, and Tailwind resolution.
>
> **HARD GATE** — Do NOT claim certainty where evidence is thin. Low-confidence color roles, component classifications, and prose assertions MUST be flagged with `<!-- AGENT NOTE: uncertain — validate during grill-me. Evidence: [what was observed] -->`.
>
> **HARD GATE** — Do NOT ship DESIGN.md without running `npx @google/design.md lint`. Unvalidated output is unverified output. If lint is unavailable (offline), flag prominently in terminal and in DESIGN.md prose.

## Quick Start

```bash
# First run — extract from HTML prototype
node extract-design/scripts/extract.js --source ./prototype.html

# From a published URL
node extract-design/scripts/extract.js --source https://my-prototype.example.com

# With a custom name
node extract-design/scripts/extract.js --source ./proto.html --name "My Design System"

# Update — re-extract from new HTML, diff against existing
node extract-design/scripts/extract.js --source ./proto-v2.html

# Lint-only — validate existing DESIGN.md without re-extraction
node extract-design/scripts/extract.js --lint-only
```

## Flow

1. **Launch Puppeteer** — dual-pass (light + dark) with retry + timeout. CI flags: `--headless=new --no-sandbox --disable-gpu --disable-dbus --use-gl=angle --use-angle=swiftshader`.
2. **Collect styles** — `page.evaluate()` collects computed styles from every element. Returns raw JSON to Node.js. Browser = sensor; Node = brain.
3. **Classify tokens** — modular pipeline: colors (Material 3 roles), typography (scale detection), spacing (tolerance GCD), rounded (clustering), components (visual signature + pseudo-state variants).
4. **Generate prose** — AI heuristics produce all 8 DESIGN.md sections. Overview and Do's/Don'ts flagged with agent notes.
5. **Write + validate** — serialize to `specs/tech-architecture/DESIGN_LATEST.md`, run `npx @google/design.md lint`, report to terminal.
6. **Handoff** — writes `handoff.next_skill: grill-me` to `specs/state.yaml` with uncertain decisions context.

## Inputs

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--source <file\|url>` | First run: yes. Update: optional | HTML prototype path or URL |
| `--name <string>` | No | Design system name (defaults to `<title>` or directory name) |
| `--lint-only` | No | Validate existing DESIGN.md without re-extraction |

## Output

- `specs/tech-architecture/DESIGN_LATEST.md` — replaces `DESIGN_PLAN_LATEST.md` as the canonical design artifact
- Terminal summary: token counts, component count, lint result, uncertain decisions
- Structured JSON log to stderr: extraction events, timing, counts
- `specs/state.yaml` → `handoff.next_skill: grill-me` with context

## Error Tiers

| Tier | Condition | Response |
|------|-----------|----------|
| Fatal | No Chrome, page load timeout after retries | Exit non-zero, suggest fixes |
| Degraded | Zero colors, zero typography, SPA shell | Write DESIGN.md with degradation warning |
| Warned | Lint errors, uncertain decisions | Write DESIGN.md, flag in terminal, hand off to grill-me |

## Dependencies

- **Puppeteer** (Chrome binary) — wrapped behind `BrowserExtractor` interface for testability
- **`@google/design.md`** (soft, via `npx`) — wrapped behind `DesignValidator` interface. Warns and skips if offline.

## verify

```bash
node extract-design/tests/test-extraction.js
```

See [REFERENCE.md](REFERENCE.md) for extraction algorithms and heuristics.
