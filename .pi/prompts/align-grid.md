---
description: "Build editorial/magazine/report webpages on a GENUINE Müller-Brockmann modular grid (International Typographic Style) — not a decorative one. Encodes the discipline (columns + modules + baseline, grotesque type, flush-left, restrained black/white/red palette) AND the hard-won front-end engineering to make the grid real, visible, and verified: one CSS-variable source of truth, an interactive grid-toggle overlay that lives in the SAME content box as the content, subgrid \"bands\" so every element snaps to a column line, an 8px baseline lock, and runtime OPTICAL ALIGNMENT that puts display type's ink (not its box) on the line. Ships with a scaffold generator and a Puppeteer verification harness that proves 0px adherence."model: sonnet
---


# Müller-Brockmann Grid Systems — built real, visible, and verified

Josef Müller-Brockmann (1914–1996), Zurich; *Grid Systems in Graphic Design* (1981) is the corpus. The grid is treated as an ethic, not decoration: **"The grid system is an aid, not a guarantee. It permits a number of possible uses and each designer can look for a solution appropriate to his personal style. But one must learn how to use the grid; it is an art that requires practice."** This skill encodes that discipline AND — the part most attempts get wrong — the front-end engineering to make the grid genuinely load-bearing on the web, plus a harness that PROVES it.

> Two real review notes this skill exists to prevent:
> 1. *"the grid is just slapped on top and misaligned"* → the overlay wasn't in the same content box as the content (see §2.2).
> 2. *"the H in the headline is off the grid"* → the headline's BOX was on the grid but its INK wasn't; large glyphs carry a side-bearing (see §2.6). **Box-on-grid ≠ ink-on-grid.**


## PART 1 — THE DISCIPLINE (decide before drawing)
- **Objective order.** The grid brings "constructive thought," legibility, and "objective and functional" design. Restraint is the point; the system, not the ego, organizes the page.
- **Modular grid.** Divide the type area into a field of **modules** — columns AND rows — separated by consistent **gutters**, inside defined **margins**. Text and images occupy whole modules. Müller-Brockmann specimens common field counts (8 / 20 / 32 fields). For the web, a **12-column grid + 8px baseline** is a robust general default; a **6×6 or 4×8 modular field grid** when you want visible rows too.
- **Baseline grid.** Vertical rhythm is sacred: **leading = a whole multiple of the baseline unit**, and every element snaps to it. This is what makes facing columns and images line up across the page.
- **Typography.** A **grotesque sans** (Akzidenz-Grotesk / Helvetica; on the web Inter, Helvetica Now, Archivo). **Flush-left, ragged-right.** Few sizes, large jumps in **scale** for hierarchy; objective, not expressive. Big **numerals/data set large** is a signature move.
- **Palette.** Pure white paper, near-black ink, **one accent — red is canonical**. Avoid the warm-cream "Claude look"; **never blue/purple gradients** (hard house rule).
- **White space + asymmetry.** Generous margins; asymmetric compositions held in tension by the grid.


## PART 2 — MAKE THE GRID REAL ON THE WEB (the load-bearing engineering)
`grid_tokens.py` emits this whole scaffold correctly; the rules below are why it's built the way it is.

### 2.1 One source of truth
Put every grid parameter in `:root` CSS variables — `--cols, --gutter, --margin, --bl (baseline), --lh (leading=3×bl), --maxw`. **Content and the overlay both read these same variables.** Never hand-author the overlay separately or it will drift.

### 2.2 The overlay MUST live in the SAME content box as the content  ← #1 bug
Failure mode: content sits in a centered `max-width` container while the overlay is a **full-width sibling** of the section. On any viewport wider than `--maxw`, the centered content and the full-width overlay no longer share column positions → "slapped on top / misaligned."
**Fix:** put `.guides` *inside* the same `.wrap`, and draw the column guides with `left/right = var(--margin)` and the **same** `repeat(var(--cols),1fr)` + `column-gap:var(--gutter)`. Then the overlay columns **are** the content columns at every width. Add left/right margin lines at `var(--margin)`.

### 2.3 Place every element by column LINE via subgrid bands
Don't eyeball spans. Each horizontal **band** spans all columns and re-exposes them:
```css
.band{grid-column:1 / -1; display:grid; grid-template-columns:subgrid; column-gap:var(--gutter); align-items:start;}
@supports not (grid-template-columns:subgrid){ .band{grid-template-columns:repeat(var(--cols),1fr);} }
```
Children place with `grid-column: <startline> / <endline>` (e.g. `1 / 6`, `6 / 13`). Every headline, paragraph, photo, caption now snaps to identical lines.

### 2.4 Lock vertical rhythm to the baseline
- Leading = `--lh` (e.g. 24px = 3×8). **Every line-height a multiple of the baseline, in px (not unitless) for display type** — unitless line-heights on large type push the box off the grid.
- Every margin/padding a multiple of the baseline. Spread top/bottom padding a multiple too, so content starts on a line.
- **Media heights = multiples of the leading** (e.g. 240/360/432/480px) so a photo's top AND bottom both land on lines.
- Hairline rules sit inside a baseline-height band, not free-floating.

### 2.5 The toggle (sizzle within the sizzle)
A control (button **+ `G` key**) toggles `body.grid-on`; overlay fades 0→1. Overlay draws: translucent **numbered column fields**, the **baseline** (major line every `--lh`, faint minor every `--bl`), and **margin lines**. Showing the real grid the page is built on IS the demo.

### 2.6 OPTICAL ALIGNMENT — display ink, not its box  ← the subtle bug
A 180px headline whose layout box is exactly on line 1 still looks misaligned against body text, because the letterform's **ink** is inset by its **left side-bearing**. Cure at runtime:
```js
// after document.fonts.ready and on resize:
var cvs=document.createElement('canvas'),ctx=cvs.getContext('2d');
document.querySelectorAll('.masthead,.numeral,.shead h2,.h2b').forEach(function(el){
  el.style.marginLeft='0px';
  var cs=getComputedStyle(el),ch=(el.textContent||'').trim()[0]; if(!ch) return;
  if(cs.textTransform==='uppercase') ch=ch.toUpperCase();
  ctx.font=cs.fontStyle+' '+cs.fontWeight+' '+cs.fontSize+' '+cs.fontFamily; ctx.textAlign='left';
  var abl=ctx.measureText(ch).actualBoundingBoxLeft;     // +ve = ink overhangs left of box
  if(isFinite(abl)) el.style.marginLeft=abl.toFixed(2)+'px'; // shift box so INK lands on the line
});
```
Apply to the masthead, big numerals, and section headlines. It scales with fluid type (re-runs on resize) and uses the **actually-loaded** font, so it's correct in the user's browser.
**CRITICAL measurement caveat:** side-bearing is **font-specific**. If you measure with the wrong font you get the wrong nudge. Headless/sandbox Chrome usually lacks the webfont, so canvas falls back to a different grotesque (measured **−16px on the fallback vs −7px on real Inter** for the same `H`). To verify optics offline you must **embed the real webfont** via `@font-face` (local TTF). In production the runtime JS measures the loaded font and is correct.


## PART 3 — VERIFY (don't trust, measure)  → `verify_grid.js`
Render with headless Chrome (Puppeteer) and assert, at **several widths including > and < `--maxw`** (to catch centered-container drift, e.g. 1440 / 1180 / 900):
1. **Column adherence** — every placed `.band > *` left snaps to a column START and right to a column END (~0px). **Exclude the optically-aligned display elements** from this box check (their box is intentionally side-bearing-offset; they're validated in step 4). **Gotcha:** build BOTH the column-start set and the column-end set — a grid item spanning "to line N" ends at the *far* side of the gutter, so single-edge math falsely reports a one-gutter error.
2. **Overlay match** — each `.guides .col` rect equals the computed column rect (~0px).
3. **Baseline** — text tops modulo the baseline ≈ 0 (tolerance ≈ half a baseline; the box-top is a proxy — the leading does the real work).
4. **Optical ink** — each display element's ink-left (box − `actualBoundingBoxLeft`, real font) equals **its own** column line (nearest column-start to its box), not always line 1.

Sandbox Chrome flags that work: `--headless=new --no-sandbox --disable-gpu --disable-dbus --use-gl=angle --use-angle=swiftshader`. `file://` works for non-ES-module pages; the CLI `--screenshot` can hang on tall pages — drive via Puppeteer and screenshot per viewport. Read PNGs back with the image-capable Read tool to eyeball a **zoom crop of the top-left corner** (masthead vs body vs column line) — the fastest human check.

A clean run looks like: `col=0px overlay=0px baseline≤4px ink=0px` → `GRID VERIFY: PASS`.


## PART 4 — CRAFT DEFAULTS (so it looks excellent, not just aligned)
- **Palette:** white `#fff`, ink `#111`, one accent (Swiss red `#e4002b`). No warm-cream Claude look; no blue/purple gradients.
- **Type:** a real grotesque webfont (Inter / Helvetica Now / Archivo) for display + body; a **mono** (Space Mono / IBM Plex Mono) for folios, captions, grid annotations — reinforces the technical register. Non-Latin via Noto Sans JP etc.
- **Hierarchy** through scale + weight + white space, not color. Treat key data as **large numerals**. Kicker labels in mono caps. Per-spread folios.
- **Real photography.** Ground real subjects in real photos (`SearchImages`). **Host each image via `PublishFilePublicly` and embed the `pub.hyperagent.com` URL** — a `PublishWebpage` artifact runs in a sandboxed iframe that can't authenticate thread-scoped `/api/files/...` URLs (broken-image trap).
- **Type fidelity if you ever rasterize art** (cairosvg / headless screenshots / image-gen reference): a `Helvetica`/`Arial` CSS stack silently falls back to **Noto Sans** (reads like Calibri). Render in **Liberation Sans** or an embedded Helvetica/Arimo TTF before trusting it. (Same trap as the optical-measurement caveat: wrong font in → wrong result out.)
- **Spread model:** full-width sections, each its own per-spread `.grid` + `.guides`, consistent margins/folios.


## PART 5 — WORKFLOW
1. Pick the subject; gather real photos; host them publicly.
2. Generate the scaffold: `python3 grid_tokens.py` (or `--scaffold` for a full page; `--cols/--baseline/--gutter/--margin/--maxw/--accent` to taste; it warns if gutter/margin aren't baseline multiples).
3. Build spreads as **subgrid bands**; place everything by **column line**; lock spacing/line-heights/media heights to the **baseline**.
4. Add the overlay (same content box) + toggle + optical-alignment JS (already in the scaffold; point its selector list at your display elements).
5. Publish, then **verify**: `CHROME=… PUP=… node verify_grid.js <file-or-url> --widths=1440,1180,900`. Eyeball a top-left zoom crop. Fix, republish.

## SCRIPTS
- **`grid_tokens.py`** — deterministic scaffold generator. Emits the `:root` tokens, `.grid`/`.band` (subgrid) scaffold, `.guides` overlay CSS, toggle JS, and the optical-alignment JS — all wired to one source of truth. `--scaffold` emits a full minimal HTML page. No network/credentials.
- **`verify_grid.js`** — Puppeteer harness implementing all four checks above with the corrected both-edges column math, the optical-exclusion, per-element column-line ink targeting, and PASS/FAIL output at multiple widths. Env: `CHROME` (chrome binary), `PUP` (puppeteer-core module path).

## CREED
A grid you can't toggle on and measure is a mood board, not a system. Build it from one source of truth, prove it at 0px, and align the **ink**.
