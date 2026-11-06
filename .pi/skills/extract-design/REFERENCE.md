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
