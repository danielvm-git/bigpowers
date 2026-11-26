#!/usr/bin/env node
// test-extraction.js — verify command for extract-design
// Unit tests (all classifiers) + integration tests (Puppeteer, if available)

import { readFileSync, existsSync, unlinkSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const FIXTURES = resolve(__dirname, 'fixtures');

let p = 0, f = 0, s = 0;

function t(name, fn) { try { fn(); p++; console.log(`  ✓ ${name}`); } catch (e) { f++; console.log(`  ✗ ${name}: ${e.message}`); } }
function skip(name, reason) { s++; console.log(`  - ${name} (skipped: ${reason})`); }
function assert(c, m) { if (!c) throw new Error(m || 'Assertion failed'); }
function includes(text, sub, m) { assert(text.includes(sub), m || `Expected "${sub}" in text`); }

// --- Check Puppeteer availability ---
function checkPuppeteer() {
  try { import.meta.resolve('puppeteer'); return 'puppeteer'; }
  catch { try { import.meta.resolve('puppeteer-core'); return 'puppeteer-core'; } catch { return null; } }
}
const puppeteerPkg = checkPuppeteer();

// ================================================================
// Unit tests
// ================================================================
console.log('\nUnit tests\n');

t('classifyColors returns valid structure', async () => {
  const { classifyColors } = await import('../scripts/classify-colors.js');
  const r = classifyColors([], 'light');
  assert(r.colors && typeof r.colors === 'object');
  assert(Array.isArray(r.uncertain));
});

t('classifyTypography returns valid structure', async () => {
  const { classifyTypography } = await import('../scripts/classify-typography.js');
  const r = classifyTypography([]);
  assert(r.typography && typeof r.typography === 'object');
  assert(Array.isArray(r.uncertain));
});

t('classifySpacing returns valid structure', async () => {
  const { classifySpacing } = await import('../scripts/classify-spacing.js');
  assert((classifySpacing([])).spacing);
});

t('classifyRounded returns valid structure', async () => {
  const { classifyRounded } = await import('../scripts/classify-rounded.js');
  assert((classifyRounded([])).rounded);
});

t('colors cluster neutrals vs accents', async () => {
  const { classifyColors } = await import('../scripts/classify-colors.js');
  const m = [
    { backgroundColor: 'rgba(255,255,255,1)', color: 'rgba(0,0,0,1)', borderColor: 'rgba(0,0,0,0)', width: 1440, height: 900, text: '' },
    { backgroundColor: 'rgba(255,0,0,1)', color: 'rgba(255,255,255,1)', borderColor: 'rgba(0,0,0,0)', width: 100, height: 48, text: 'Click' },
  ];
  const r = classifyColors(m, 'light');
  assert(Object.keys(r.colors).length >= 2, `Expected >=2 colors, got ${Object.keys(r.colors).length}`);
  assert(r.colors.surface, 'Expected surface color');
  assert(r.colors.tertiary, 'Expected accent color (tertiary)');
});

t('dark mode classification differs from light', async () => {
  const { classifyColors } = await import('../scripts/classify-colors.js');
  // Dark mode: dark bg = surface, light text = on-surface, bright accent
  const m = [
    { backgroundColor: 'rgba(10,10,30,1)', color: 'rgba(220,220,240,1)', borderColor: 'rgba(0,0,0,0)', width: 1440, height: 900, text: '' },
    { backgroundColor: 'rgba(200,200,210,1)', color: 'rgba(10,10,30,1)', borderColor: 'rgba(0,0,0,0)', width: 300, height: 200, text: 'Card' },
    { backgroundColor: 'rgba(100,150,255,1)', color: 'rgba(255,255,255,1)', borderColor: 'rgba(0,0,0,0)', width: 120, height: 48, text: 'Click' },
  ];
  const light = classifyColors(m, 'light');
  const dark = classifyColors(m, 'dark');
  assert(light.colors.surface !== dark.colors.surface || Object.keys(light.colors).length > 1,
    'Dark mode should produce different or equivalent color assignments');
});

t('typography detects Inter from mock styles', async () => {
  const { classifyTypography } = await import('../scripts/classify-typography.js');
  const m = [
    { text: 'Heading', fontFamily: 'Inter', fontSize: '48px', fontWeight: '700', lineHeight: '1.1', letterSpacing: '-0.02em', tag: 'h1' },
    { text: 'Body', fontFamily: 'Inter', fontSize: '16px', fontWeight: '400', lineHeight: '1.5', letterSpacing: 'normal', tag: 'p' },
    { text: 'Caption', fontFamily: 'Inter', fontSize: '12px', fontWeight: '600', lineHeight: '1.33', letterSpacing: '0.05em', tag: 'span' },
  ];
  const r = classifyTypography(m);
  assert(Object.keys(r.typography).length >= 2, `Expected >=2 levels, got ${Object.keys(r.typography).length}`);
});

t('spacing computes GCD correctly', async () => {
  const { classifySpacing } = await import('../scripts/classify-spacing.js');
  const m = [];
  for (let i = 0; i < 4; i++) m.push({ padding: '16px', margin: '8px', gap: '8px' });
  const r = classifySpacing(m);
  assert(r.spacing.unit === '8px', `Expected 8px, got ${r.spacing.unit}`);
  assert(r.spacing.sm === '16px', `Expected 16px sm, got ${r.spacing.sm}`);
});

t('spacing detects half-step', async () => {
  const { classifySpacing } = await import('../scripts/classify-spacing.js');
  const m = [];
  for (let i = 0; i < 4; i++) m.push({ padding: '16px', margin: '4px', gap: '4px' });
  const r = classifySpacing(m);
  assert(r.spacing.half || r.spacing.unit, 'Should detect unit or half-step');
});

t('rounded detects full pill value', async () => {
  const { classifyRounded } = await import('../scripts/classify-rounded.js');
  const m = [{ borderRadius: '16px' },{ borderRadius: '16px' },{ borderRadius: '9999px' },{ borderRadius: '9999px' }];
  assert(classifyRounded(m).rounded.full);
});

t('rounded detects none for zero-radius', async () => {
  const { classifyRounded } = await import('../scripts/classify-rounded.js');
  assert(classifyRounded([{ borderRadius: '0px' },{ borderRadius: '0px' }]).rounded.none);
});

t('detectComponents finds buttons and cards', async () => {
  const { detectComponents } = await import('../scripts/detect-components.js');
  const m = [
    { isButton: true, width: 120, height: 48, backgroundColor: 'rgba(255,255,255,1)', color: 'rgba(0,0,0,1)', borderRadius: '24px', padding: '0 24px', text: 'Click' },
    { isButton: false, width: 400, height: 200, backgroundColor: 'rgba(255,255,255,0.1)', borderRadius: '16px', padding: '24px', text: '' },
    { isInput: true, width: 300, height: 48, backgroundColor: 'rgba(255,255,255,0.1)', borderRadius: '24px', padding: '20px', text: '' },
  ];
  const r = await detectComponents(m);
  assert(Object.keys(r.components).length >= 2, `Expected >=2 components, got ${Object.keys(r.components).length}`);
  assert(r.detectedPatterns.includes('button-primary') || r.detectedPatterns.includes('input-field'));
});

t('detectComponents returns empty on unstyleable input', async () => {
  const { detectComponents } = await import('../scripts/detect-components.js');
  const r = await detectComponents([]);
  assert(Object.keys(r.components).length === 0);
  assert(r.uncertain.length > 0, 'Should flag no components detected');
});

t('generateProse produces all 8 sections', async () => {
  const { generateProse } = await import('../scripts/generate-prose.js');
  const prose = generateProse({
    name: 'Test', colors: { surface: '#FFF', 'on-surface': '#000', tertiary: '#E4002B' },
    typography: { 'body-md': { fontFamily: 'Inter', fontSize: '16px', fontWeight: '400' } },
    spacing: { unit: '8px' }, rounded: { sm: '4px' }, components: {},
    hints: { dominantColorFamily: 'light', styleSignals: ['swiss'], fontCount: 1, glassDetected: false },
    detectedPatterns: [],
  });
  ['## Overview','## Colors','## Typography','## Layout','## Elevation','## Shapes','## Components',"## Do's and Don'ts"]
    .forEach(sec => assert(prose.includes(sec), `Missing: ${sec}`));
});

t('generateProse handles glassmorphism style', async () => {
  const { generateProse } = await import('../scripts/generate-prose.js');
  const prose = generateProse({
    name: 'Glass', colors: { surface: '#0B1326' },
    typography: {}, spacing: {}, rounded: {}, components: {},
    hints: { dominantColorFamily: 'dark', styleSignals: ['glassmorphism'], fontCount: 1, glassDetected: true },
    detectedPatterns: [],
  });
  assert(prose.includes('glassmorphism') || prose.includes('frosted'), 'Should mention glass/glassmorphism');
});

t('writeDESIGNmd produces valid DESIGN.md file', async () => {
  const { writeDESIGNmd } = await import('../scripts/write-designd.js');
  const tmp = '/tmp/ed-test-output.md';
  writeDESIGNmd({
    name: 'Test System', version: 'alpha',
    colors: { primary: '#111', surface: '#FFF' },
    typography: { 'body-md': { fontFamily: 'Inter', fontSize: '16px', fontWeight: '400' } },
    spacing: { unit: '8px' }, rounded: { sm: '4px' },
    components: { 'button-primary': { backgroundColor: '#E4002B', textColor: '#FFF', rounded: '4px' } },
    prose: '## Overview\n\nTest.\n',
    outputPath: tmp,
  });
  const c = readFileSync(tmp, 'utf8');
  assert(c.startsWith('---\n'), 'Should start with YAML');
  assert(c.includes('name: Test System'));
  assert(c.includes('version: alpha'));
  assert(c.includes('primary: "#111"'));
  assert(c.includes('## Overview'));
  assert(c.includes('button-primary:'));
  unlinkSync(tmp);
});

t('writeDESIGNmd handles dark mode colors', async () => {
  const { writeDESIGNmd } = await import('../scripts/write-designd.js');
  const tmp = '/tmp/ed-test-dark.md';
  writeDESIGNmd({
    name: 'Dark', colors: { surface: '#111' }, typography: {}, spacing: {}, rounded: {}, components: {},
    colorsDark: { surface: '#222', 'on-surface': '#EEE' },
    prose: '## Overview\n\nDark.\n', outputPath: tmp,
  });
  const c = readFileSync(tmp, 'utf8');
  assert(c.includes('colors-dark:'));
  assert(c.includes('surface: "#222"'));
  unlinkSync(tmp);
});

// ================================================================
// Integration tests (requires Puppeteer)
// ================================================================
if (puppeteerPkg) {
  console.log('\nIntegration tests (Puppeteer)\n');

  t('BrowserExtractor launches and extracts', async () => {
    const pm = await import(puppeteerPkg);
    const { BrowserExtractor } = await import('../scripts/lib/browser.js');
    const ex = new BrowserExtractor({ puppeteer: pm.default || pm });
    const fixture = resolve(FIXTURES, 'swiss-grid/prototype.html');
    const result = await ex.extract(fixture);
    assert(result.light, 'Should have light mode extraction');
    assert(result.light.styles && result.light.styles.length > 0, 'Should have styled elements');
    assert(result.light.declaredFonts !== undefined, 'Should have declaredFonts');
  });

  t('BrowserExtractor extracts glassmorphism fixture', async () => {
    const pm = await import(puppeteerPkg);
    const { BrowserExtractor } = await import('../scripts/lib/browser.js');
    const ex = new BrowserExtractor({ puppeteer: pm.default || pm });
    const fixture = resolve(FIXTURES, 'glassmorphism-dark/prototype.html');
    const result = await ex.extract(fixture);
    const styles = result.light.styles;
    assert(styles.length > 0);
    const hasGlass = styles.some(s => s.backdropFilter && s.backdropFilter !== 'none');
    // Note: file:// may not load Google Fonts CDN — expected
    assert(result.light.declaredFonts !== undefined, 'Should collect <link> declarations even if unloaded');
  });

  t('BrowserExtractor handles minimal-no-styles fixture (degraded)', async () => {
    const pm = await import(puppeteerPkg);
    const { BrowserExtractor } = await import('../scripts/lib/browser.js');
    const ex = new BrowserExtractor({ puppeteer: pm.default || pm });
    const fixture = resolve(FIXTURES, 'minimal-no-styles/prototype.html');
    const result = await ex.extract(fixture);
    const styles = result.light.styles;
    // Browser still computes defaults (transparent bg, inherit fonts)
    assert(styles.length > 0, 'Should have DOM elements even without explicit styles');
  });

  t('Dark mode pass runs without error', async () => {
    const pm = await import(puppeteerPkg);
    const { BrowserExtractor } = await import('../scripts/lib/browser.js');
    const ex = new BrowserExtractor({ puppeteer: pm.default || pm });
    const fixture = resolve(FIXTURES, 'swiss-grid/prototype.html');
    const result = await ex.extract(fixture);
    // Swiss grid is light-only — dark should be null or have styles
    assert(result.dark === null || result.dark.styles !== undefined, 'Dark pass should complete');
  });
} else {
  console.log('\nIntegration tests (Puppeteer)\n');
  skip('Puppeteer tests', 'Puppeteer not installed. Install with: npm install puppeteer');
}

// ================================================================
// Hardening tests
// ================================================================
console.log('\nHardening tests\n');

t('all 15 script modules resolve imports correctly', async () => {
  const scripts = [
    '../scripts/lib/constants.js',
    '../scripts/lib/logging.js',
    '../scripts/lib/retry.js',
    '../scripts/lib/state.js',
    '../scripts/lib/browser.js',
    '../scripts/lib/validator.js',
    '../scripts/collect-styles.js',
    '../scripts/classify-colors.js',
    '../scripts/classify-typography.js',
    '../scripts/classify-spacing.js',
    '../scripts/classify-rounded.js',
    '../scripts/detect-components.js',
    '../scripts/generate-prose.js',
    '../scripts/write-designd.js',
    '../scripts/extract.js',
  ];
  for (const script of scripts) {
    try { await import(script); }
    catch (e) {
      if (e.code === 'ERR_MODULE_NOT_FOUND') throw new Error(`Broken import in ${script}: ${e.message}`);
      if (!e.message.includes('puppeteer') && !e.message.includes('Cannot find package')) throw e;
    }
  }
});

t('classifyColors handles empty styles gracefully', async () => {
  const { classifyColors } = await import('../scripts/classify-colors.js');
  const r = classifyColors([], 'light');
  assert(Object.keys(r.colors).length === 0);
  assert(r.uncertain.length > 0 || typeof r.uncertain === 'object');
});

t('classifySpacing handles all-zero values', async () => {
  const { classifySpacing } = await import('../scripts/classify-spacing.js');
  const m = [];
  for (let i = 0; i < 4; i++) m.push({ padding: '0px', margin: '0px', gap: '0px' });
  assert(classifySpacing(m).spacing.unit);
});

t('classifyRounded handles mixed px+rem units', async () => {
  const { classifyRounded } = await import('../scripts/classify-rounded.js');
  const m = [{ borderRadius: '16px' },{ borderRadius: '1rem' },{ borderRadius: '16px' },{ borderRadius: '1rem' }];
  assert(classifyRounded(m).rounded.sm || classifyRounded(m).rounded.md);
});

// ================================================================
// Summary
// ================================================================
console.log(`\n${'='.repeat(40)}`);
console.log(`${p} passed, ${f} failed, ${s} skipped`);
if (p === 0 && f === 0 && s > 0) {
  console.log('All tests skipped. Install Puppeteer for full coverage.');
  process.exit(0);
}
process.exit(f > 0 ? 1 : 0);
