#!/usr/bin/env node
// extract-design — entry point
// Orchestrates: Puppeteer → token classification → prose → DESIGN.md → lint → handoff

import { existsSync, renameSync, copyFileSync, unlinkSync } from 'node:fs';
import { basename, resolve } from 'node:path';
import { log } from './lib/logging.js';
import { BrowserExtractor } from './lib/browser.js';
import { DesignValidator } from './lib/validator.js';
import { classifyColors } from './classify-colors.js';
import { classifyTypography } from './classify-typography.js';
import { classifySpacing } from './classify-spacing.js';
import { classifyRounded } from './classify-rounded.js';
import { detectComponents } from './detect-components.js';
import { generateProse } from './generate-prose.js';
import { writeDESIGNmd } from './write-designd.js';
import { writeGrillMeHandoff } from './lib/state.js';
import { COVERAGE_MINIMUMS, OUTPUT_PATH } from './lib/constants.js';

function parseArgs(argv) {
  const a = { lintOnly: false };
  for (let i = 2; i < argv.length; i++) {
    if (argv[i] === '--source' && argv[i + 1]) a.source = argv[++i];
    else if (argv[i] === '--name' && argv[i + 1]) a.name = argv[++i];
    else if (argv[i] === '--lint-only') a.lintOnly = true;
  }
  return a;
}

function buildHints(styles, colors, components) {
  const glass = styles.some(s => s.backdropFilter && s.backdropFilter !== 'none');
  const darkBg = styles.some(s => {
    if (s.tag !== 'body') return false;
    const m = s.backgroundColor?.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
    return m && parseInt(m[1]) + parseInt(m[2]) + parseInt(m[3]) < 100;
  });
  const ss = [];
  if (glass) ss.push('glassmorphism');
  if (darkBg) ss.push('dark');
  const hasGrot = styles.some(s => {
    const ff = (s.fontFamily || '').toLowerCase();
    return ff.includes('inter') || ff.includes('helvetica') || ff.includes('grotesk') || ff.includes('archivo');
  });
  if (hasGrot && Object.keys(colors).length <= 8 && !glass) ss.push('swiss');
  const ff = new Set(styles.map(s => s.fontFamily).filter(Boolean));
  return {
    dominantColorFamily: darkBg ? 'dark' : 'light',
    styleSignals: ss.length ? ss : ['minimalist'],
    fontCount: ff.size,
    glassDetected: glass,
    elevationStrategy: glass ? 'glass' : 'flat',
  };
}

/**
 * Check if the extraction returned usable data.
 */
function validateExtraction(light) {
  const styles = light?.styles || [];
  const hasStyledElements = styles.filter(s => {
    const hasBg = s.backgroundColor && s.backgroundColor !== 'rgba(0, 0, 0, 0)';
    const hasText = s.fontFamily && s.fontSize;
    return (s.width > 0 || s.height > 0) && (hasBg || hasText);
  }).length;

  if (styles.length === 0) {
    return {
      tier: 'Tier 2 — Degraded',
      message: 'No styled elements found. The prototype may be empty, JS-rendered (SPA shell), or contain no CSS.',
      fix: 'Verify the HTML file contains visible styled elements. For SPAs, use a published URL with server-side rendering.',
    };
  }

  if (hasStyledElements === 0) {
    return {
      tier: 'Tier 2 — Degraded',
      message: `${styles.length} elements found but none have visible styles (all inherit/browser defaults).`,
      fix: 'Add explicit CSS rules to the prototype before extraction.',
    };
  }

  return null; // OK
}

async function main() {
  const args = parseArgs(process.argv);
  const start = Date.now();

  // --- Lint-only mode ---
  if (args.lintOnly) {
    if (!existsSync(OUTPUT_PATH)) {
      log.user(`Error: DESIGN_LATEST.md not found at ${OUTPUT_PATH}. Run without --lint-only first.`);
      process.exit(1);
    }
    const v = new DesignValidator();
    const r = v.lint(OUTPUT_PATH);
    log.user(formatLint(r));
    process.exit(r.summary.errors > 0 ? 1 : 0);
  }

  // --- Validate inputs ---
  if (!args.source) {
    log.user('Usage: node extract-design/scripts/extract.js --source <file|url> [--name "Name"] [--lint-only]');
    process.exit(1);
  }

  const name = args.name || basename(args.source, '.html');

  // --- Check if this is an update (existing DESIGN_LATEST.md) ---
  const isUpdate = existsSync(OUTPUT_PATH);
  const oldSnapshotPath = isUpdate ? `${OUTPUT_PATH}.pre-update` : null;

  if (isUpdate) {
    copyFileSync(OUTPUT_PATH, oldSnapshotPath);
    log.info('update-detected', { existingPath: OUTPUT_PATH, snapshot: oldSnapshotPath });
  }

  // --- Launch Puppeteer ---
  let pm;
  try { pm = await import('puppeteer-core'); } catch { try { pm = await import('puppeteer'); } catch {} }

  if (!pm) {
    log.user('Error: Puppeteer not found. Install with: npm install puppeteer');
    log.user('Or if you have Chrome installed: npm install puppeteer-core');
    process.exit(1);
  }

  const extractor = new BrowserExtractor({ puppeteer: pm.default || pm });
  let extraction;
  try {
    extraction = await extractor.extract(args.source);
  } catch (err) {
    log.user(`\nFATAL — Extraction failed:\n  ${err.message}`);
    log.user('\nTroubleshooting:');
    log.user('  • Verify the source is accessible (URL reachable, file exists)');
    log.user('  • For SPAs, try a server-rendered or published URL');
    log.user('  • Check that Chrome/Chromium is installed (npm install puppeteer)');
    process.exit(1);
  }

  const styles = extraction.light.styles || [];

  // --- Validate extraction quality ---
  const validation = validateExtraction(extraction.light);
  if (validation) {
    log.user(`\n${validation.tier}`);
    log.user(`  ${validation.message}`);
    log.user(`  Fix: ${validation.fix}`);
  }

  // --- Classify tokens ---
  const cr = classifyColors(styles, 'light');
  const tr = classifyTypography(styles);
  const sr = classifySpacing(styles);
  const rr = classifyRounded(styles);
  const compR = await detectComponents(styles, null);

  // --- Detect pseudo-state variants (while browser is open) ---
  let pseudoVariants = {};
  try {
    const compArr = Object.entries(compR.components).map(([name, tokens]) => ({
      componentName: name,
      backgroundColor: tokens.backgroundColor,
      textColor: tokens.textColor,
      width: parseInt(tokens.width) || 0,
      height: parseInt(tokens.height) || 0,
    })).filter(c => c.backgroundColor);

    if (compArr.length > 0) {
      pseudoVariants = await extractor.detectPseudoStates(compArr);
      Object.assign(compR.components, pseudoVariants);
      if (Object.keys(pseudoVariants).length > 0) {
        log.info('pseudo-variants-detected', { variantCount: Object.keys(pseudoVariants).length });
      }
    }
  } catch (err) {
    log.warn('pseudo-states-skipped', { error: err.message });
  }

  // --- Font warnings ---
  const fontWarnings = extraction.fontWarnings || [];

  // --- Aggregate uncertain decisions ---
  const allU = [
    ...cr.uncertain, ...tr.uncertain, ...sr.uncertain, ...rr.uncertain, ...compR.uncertain, ...fontWarnings,
  ];

  const degraded = Object.keys(cr.colors).length < COVERAGE_MINIMUMS.MIN_COLORS ||
                   Object.keys(tr.typography).length < COVERAGE_MINIMUMS.MIN_TYPOGRAPHY_LEVELS;

  const hints = buildHints(styles, cr.colors, compR.components);

  const prose = generateProse({
    name, colors: cr.colors, typography: tr.typography,
    spacing: sr.spacing, rounded: rr.rounded,
    components: compR.components, hints,
    detectedPatterns: compR.detectedPatterns,
  });

  // --- Dark mode ---
  let cd;
  if (extraction.dark?.styles) {
    const dr = classifyColors(extraction.dark.styles, 'dark');
    if (Object.keys(dr.colors).length) cd = dr.colors;
  }

  // --- Write DESIGN.md ---
  writeDESIGNmd({
    name, colors: cr.colors, typography: tr.typography,
    spacing: sr.spacing, rounded: rr.rounded,
    components: compR.components, prose, colorsDark: cd,
  });

  // --- Diff on update ---
  let diffResult = null;
  if (isUpdate && oldSnapshotPath && existsSync(oldSnapshotPath)) {
    const validator = new DesignValidator();
    try {
      diffResult = validator.diff(oldSnapshotPath, OUTPUT_PATH);
    } catch {
      // Diff unavailable — skip
    }
    // Clean up snapshot
    try { unlinkSync(oldSnapshotPath); } catch {}
  }

  // --- Lint ---
  const validator = new DesignValidator();
  let lr;
  try { lr = validator.lint(OUTPUT_PATH); } catch {}

  // --- Terminal summary ---
  const elapsed = ((Date.now() - start) / 1000).toFixed(1);
  log.user(`\n=== extract-design complete ===`);
  log.user(`Design: ${name}  |  Output: ${OUTPUT_PATH}`);
  log.user(`Colors: ${Object.keys(cr.colors).length}  Typo: ${Object.keys(tr.typography).length}  Spacing: ${Object.keys(sr.spacing).length}  Rounded: ${Object.keys(rr.rounded).length}  Components: ${Object.keys(compR.components).length}`);
  if (Object.keys(pseudoVariants).length > 0) log.user(`Pseudo-states: ${Object.keys(pseudoVariants).length} variants detected`);
  if (cd) log.user(`Dark mode: ${Object.keys(cd).length} colors (differs from light)`);

  if (isUpdate && diffResult && !diffResult.skipped) {
    log.user(`\n--- Diff (update) ---`);
    log.user(formatDiff(diffResult));
  }

  if (validation) log.user(`\n⚠️  ${validation.tier}: ${validation.message}`);

  if (fontWarnings.length) {
    log.user(`\n⚠️  Font declaration mismatches:`);
    fontWarnings.forEach(w => log.user(`  • ${w}`));
  }

  if (allU.length) {
    log.user(`\n⚠️  ${allU.length} uncertain decisions — run grill-me to validate:`);
    allU.slice(0, 5).forEach(d => log.user(`  • ${d}`));
    if (allU.length > 5) log.user(`  ... and ${allU.length - 5} more`);
  }

  if (lr && !lr.skipped) log.user(`\n${formatLint(lr)}`);
  else log.user('\nValidation skipped (@google/design.md not available).');

  log.user(`\nDuration: ${elapsed}s  |  Next: grill-me`);

  // --- Handoff ---
  writeGrillMeHandoff({
    tokenCount: Object.keys(cr.colors).length + Object.keys(tr.typography).length,
    componentCount: Object.keys(compR.components).length,
    uncertainCount: allU.length,
    uncertainDecisions: allU.slice(0, 10),
  });

  log.info('extraction-complete', {
    totalDurationMs: Date.now() - start,
    outputPath: OUTPUT_PATH,
  });

  process.exit(degraded ? 2 : 0);
}

function formatLint(r) {
  if (r.skipped) return 'Lint skipped.';
  return `Lint: ${r.summary.errors} errors, ${r.summary.warnings} warnings, ${r.summary.info} info`;
}

function formatDiff(dr) {
  const lines = [];
  if (dr.tokens?.colors) {
    const c = dr.tokens.colors;
    if (c.added?.length) lines.push(`  Colors added: ${c.added.join(', ')}`);
    if (c.removed?.length) lines.push(`  Colors removed: ${c.removed.join(', ')}`);
    if (c.modified?.length) lines.push(`  Colors modified: ${c.modified.join(', ')}`);
  }
  if (dr.tokens?.typography) {
    const t = dr.tokens.typography;
    if (t.added?.length) lines.push(`  Typography added: ${t.added.join(', ')}`);
    if (t.removed?.length) lines.push(`  Typography removed: ${t.removed.join(', ')}`);
    if (t.modified?.length) lines.push(`  Typography modified: ${t.modified.join(', ')}`);
  }
  if (dr.regression) lines.push('  ⚠️  REGRESSION detected — more errors in new version.');
  return lines.length ? lines.join('\n') : '  No token-level changes detected.';
}

main().catch(err => {
  log.user(`\nFATAL — Unexpected error:\n  ${err.message}`);
  log.error('unhandled', { error: err.message, stack: err.stack });
  process.exit(1);
});
