function parseR(v) { if (!v || v === '0px' || v === '0') return 0; const m = v.match(/^([\d.]+)(px|rem)$/); return m ? parseFloat(m[1]) * (m[2] === 'rem' ? 16 : 1) : (parseFloat(v) || 0); }
export function classifyRounded(styles) { const u = []; const r = {}; const cnt = new Map();
  for (const el of styles) { const px = parseR(el.borderRadius); cnt.set(px, (cnt.get(px) || 0) + 1); }
  const freq = [...cnt.entries()].filter(([,c]) => c >= 2).map(([px]) => px).sort((a,b) => a - b);
  if (!freq.length) { r.none = '0px'; return { rounded: r, uncertain: [] }; }
  r.none = '0px'; const reg = freq.filter(v => v < 9998 && v > 0); const full = freq.find(v => v >= 9998);
  if (full) r.full = `${full}px`; if (reg.length === 1) r.sm = `${reg[0]}px`;
  else if (reg.length >= 2) { r.sm = `${reg[0]}px`; r.md = `${reg[1]}px`; } if (reg.length >= 3) r.lg = `${reg[2]}px`;
  return { rounded: r, uncertain: u };
}
