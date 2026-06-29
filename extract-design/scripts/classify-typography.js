function px(v) { if (!v) return 0; const n = parseFloat(v); return isNaN(n) ? 0 : n; }
export function classifyTypography(styles) { const u = []; const t = {}; const txt = styles.filter(s => s.text && s.text.length > 0 && s.fontSize); const clusters = new Map();
  for (const el of txt) { const s = Math.round(px(el.fontSize)); if (!s) continue; if (!clusters.has(s)) clusters.set(s, { fontFamily: el.fontFamily, fontWeight: el.fontWeight, lineHeight: el.lineHeight, letterSpacing: el.letterSpacing, tag: el.tag, count: 0 }); clusters.get(s).count++; }
  const sorted = [...clusters.entries()].sort((a,b) => b[0] - a[0]); if (!sorted.length) { u.push('No typography detected.'); return { typography: {}, uncertain: u }; }
  let di = 0, hi = 0, bi = 0;
  for (const [sz, cl] of sorted) { const hd = /^h[1-6]$/.test(cl.tag) || sz >= 32; let n; if (sz >= 64 && di === 0) { n = 'display-lg'; di++; } else if (hd && sz >= 40) { n = hi === 0 ? 'headline-lg' : 'headline-md'; hi++; } else if (hd && sz >= 28) { n = hi <= 1 ? 'headline-md' : 'headline-sm'; hi++; } else if (hd) { n = 'title-lg'; } else if (sz <= 18 && bi === 0) { n = 'body-lg'; bi++; } else if (sz <= 18) { n = 'body-md'; bi++; } else if (sz <= 14) { n = 'label-md'; } else { n = 'body-sm'; }
    t[n] = { fontFamily: cl.fontFamily, fontSize: `${sz}px`, fontWeight: String(cl.fontWeight || '400') }; if (cl.lineHeight && cl.lineHeight !== 'normal') t[n].lineHeight = cl.lineHeight; if (cl.letterSpacing && cl.letterSpacing !== 'normal' && cl.letterSpacing !== '0px') t[n].letterSpacing = cl.letterSpacing; }
  return { typography: t, uncertain: u };
}
