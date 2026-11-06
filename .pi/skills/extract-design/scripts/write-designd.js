import { writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { dirname } from 'node:path';
import { OUTPUT_PATH } from './lib/constants.js';

export function writeDESIGNmd({ name, version = 'alpha', colors, typography, spacing, rounded, components, prose, colorsDark, outputPath = OUTPUT_PATH }) {
  const y = []; y.push(`version: ${version}`, `name: ${name}`);
  if (colors && Object.keys(colors).length) { y.push('colors:'); for (const [k,v] of Object.entries(colors)) y.push(`  ${k}: "${v}"`); }
  if (colorsDark && Object.keys(colorsDark).length) { y.push('colors-dark:'); for (const [k,v] of Object.entries(colorsDark)) y.push(`  ${k}: "${v}"`); }
  if (typography && Object.keys(typography).length) { y.push('typography:'); for (const [k,v] of Object.entries(typography)) { y.push(`  ${k}:`); for (const [p,val] of Object.entries(v)) { if (val !== undefined && val !== null && val !== '') { const q = String(val).startsWith('#')||String(val).startsWith('rgba')?`"${val}"`:val; y.push(`    ${p}: ${q}`); } } } }
  if (spacing && Object.keys(spacing).length) { y.push('spacing:'); for (const [k,v] of Object.entries(spacing)) y.push(`  ${k}: "${v}"`); }
  if (rounded && Object.keys(rounded).length) { y.push('rounded:'); for (const [k,v] of Object.entries(rounded)) y.push(`  ${k}: "${v}"`); }
  if (components && Object.keys(components).length) { y.push('components:'); for (const [k,v] of Object.entries(components)) { y.push(`  ${k}:`); for (const [p,val] of Object.entries(v)) { if (val !== undefined && val !== null && val !== '') { const q = String(val).startsWith('#')||String(val).startsWith('rgba')?`"${val}"`:val; y.push(`    ${p}: ${q}`); } } } }
  const content = `---\n${y.join('\n')}\n---\n\n${prose}\n`;
  const d = dirname(outputPath); if (!existsSync(d)) mkdirSync(d, { recursive: true });
  writeFileSync(outputPath, content, 'utf8'); return outputPath;
}
