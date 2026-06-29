function toPx(v) { if (!v) return 0; const m = v.match(/^([\d.]+)(px|rem|em)$/); if (!m) return 0; return parseFloat(m[1]) * (m[2] === 'rem' || m[2] === 'em' ? 16 : 1); }
function tGcd(nums, tol = 0.5) { if (!nums.length) return null; let r = nums[0]; for (let i = 1; i < nums.length; i++) { let a = Math.abs(r), b = Math.abs(nums[i]); while (b > tol) { const t = b; b = a % b; a = t; } r = a; } return r; }
function collect(css, counts) { if (!css) return; for (const p of css.split(/\s+/)) { const v = toPx(p); if (v > 0) counts.set(v, (counts.get(v) || 0) + 1); } }

export function classifySpacing(styles) { const u = []; const s = {}; const counts = new Map();
  for (const el of styles) { collect(el.padding, counts); collect(el.margin, counts); if (el.gap) collect(el.gap, counts); }
  const freq = new Map(); for (const [v, c] of counts) { if (c >= 3) freq.set(v, c); }
  if (freq.size < 3) u.push('Fewer than 3 spacing values.');
  const nums = [...freq.keys()].map(toPx).filter(v => v > 0); const g = tGcd(nums, 0.5);
  if (!g || g < 2) { const sorted = [...freq.entries()].sort((a,b) => b[1] - a[1]); s.unit = sorted.length ? `${toPx(sorted[0][0])}px` : '8px'; return { spacing: s, uncertain: u }; }
  s.unit = `${g}px`; const half = g / 2; if (nums.filter(v => Math.abs(v - half) < 0.5).length >= 3) s.half = `${half}px`;
  s.sm = `${g * 2}px`; s.md = `${g * 4}px`; s.lg = `${g * 8}px`; if (nums.some(v => v >= g * 16)) s.xl = `${g * 16}px`;
  return { spacing: s, uncertain: u };
}
