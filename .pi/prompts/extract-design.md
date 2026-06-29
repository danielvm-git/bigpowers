---
description: "Extract a Google DESIGN.md file from an HTML prototype (claude.ai/design or any styled page) using Puppeteer, producing machine-readable tokens and AI-generated prose. Use when the user has an HTML prototype and wants a DESIGN.md to anchor their project's visual identity, or when seed-conventions has just scaffolded a new project."
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

---

# Extract Design — Reference

## Extraction Algorithms

### Color Classification
1. Collect unique computed `background-color`, `color`, `border-color` from every DOM element.
2. Count frequency and context (text vs. bg vs. border vs. button).
3. Classify using Material 3 roles: surface = largest-area bg, on-surface = most-used text, tertiary = highest-saturation on CTAs, error = reddish.
4. Surface container levels: luminance-ordered. Hard-cap at 3 unless data supports 5.
5. Low-confidence → `<!-- AGENT NOTE -->` in Colors prose.

### Typography Classification
1. Collect unique (fontFamily, fontSize, fontWeight, lineHeight, letterSpacing) tuples.
2. Cluster by fontSize (±2px) → type scale.
3. Detect heading hierarchy from HTML tag + computed size.
4. Name levels: display-lg, headline-lg/md/sm, title-lg, body-lg/md/sm, label-lg/md/sm.
5. Parse `<link>` and `@font-face`; warn if computed font differs from declared.

### Spacing Classification
1. Collect unique padding, margin, gap values. Filter: ignore values < 3 occurrences.
2. Compute tolerance-based GCD (0.5px tolerance).
3. Declare base unit. Detect half-step if gcd/2 values present ≥3 times.
4. Map: unit×1 → sm, ×2 → md, ×4 → lg, ×8 → xl.

### Rounded Classification
1. Collect unique border-radius values. Cluster (1px tolerance).
2. Name: none (0), sm (smallest), md (median), lg (large), xl (largest), full (9999px).

### Component Detection
- Button: w<300px, h<64px, bg+radius set, short text. cursor:pointer is bonus.
- Card: bg+radius+padding set, larger area.
- Input: `<input>` or `<textarea>` tag.
- Pseudo-state variants: force :hover, :active, :focus for high-confidence components.

### Prose Generation
Generates all 8 DESIGN.md sections. Overview and Do's/Don'ts flagged with `<!-- AGENT NOTE: Generated from visual analysis. Grill-me should validate. -->`.

## Material 3 Token Conventions
Colors: primary, on-primary, secondary, tertiary, error, surface, on-surface, surface-container-*, outline, background, on-background.
Typography: display-lg/md/sm, headline-lg/md/sm, title-lg/md/sm, body-lg/md/sm, label-lg/md/sm.
Rounded: none, xs, sm, md, lg, xl, full.

## CI Compatibility
Chrome flags: `--headless=new --no-sandbox --disable-gpu --disable-dbus --use-gl=angle --use-angle=swiftshader`

## Defensive Code
Retry with backoff (3 attempts, 1s/2s/4s), Timeout (30s page load, 10s pseudo-state), Graceful degradation (Tier 2 on empty extraction).

## Known Risks
- DESIGN.md spec is alpha. Skill pins to current spec.
- Puppeteer is heavy (~300MB Chrome). Document requirement clearly.
- Prose quality depends on AI heuristics. grill-me is the validation gate.
