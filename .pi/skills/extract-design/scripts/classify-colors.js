function norm(c) { if (!c || c === 'transparent' || c === 'rgba(0, 0, 0, 0)') return null; return c.trim(); }
function lum(c) { const m = c.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/); if (!m) return 0.5; const s = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); return 0.2126 * s(parseInt(m[1]) / 255) + 0.7152 * s(parseInt(m[2]) / 255) + 0.0722 * s(parseInt(m[3]) / 255); }
function isNeutral(c) { const m = c.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/); if (!m) return false; return Math.max(Math.abs(parseInt(m[1]) - parseInt(m[2])), Math.abs(parseInt(m[2]) - parseInt(m[3])), Math.abs(parseInt(m[1]) - parseInt(m[3]))) < 30; }

export function classifyColors(styles, mode = 'light') {
  const u = []; const colors = {}; const stats = new Map();
  for (const el of styles) {
    for (const [prop, usage] of [['backgroundColor','bg'],['color','text'],['borderColor','border']]) {
      const k = norm(el[prop]); if (!k) continue;
      const s = stats.get(k) || { usage: new Set(), area: 0, count: 0 }; s.usage.add(usage); if (prop === 'backgroundColor') s.area += (el.width||0)*(el.height||0); s.count++; stats.set(k, s);
    }
  }
  const neutrals = [], accents = [];
  for (const [c, s] of stats) { if (isNeutral(c)) neutrals.push({ color: c, ...s, luminance: lum(c) }); else accents.push({ color: c, ...s }); }
  neutrals.sort((a,b) => b.area - a.area); accents.sort((a,b) => b.count - a.count);
  if (neutrals.length) { colors.surface = neutrals[0].color; colors.background = neutrals[0].color; const txt = [...stats.entries()].filter(([,s]) => s.usage.has('text')).sort((a,b) => b[1].count - a[1].count); if (txt.length) colors['on-surface'] = txt[0][0]; }
  const containers = neutrals.slice(1); if (containers.length) { const isDark = mode === 'dark'; containers.sort((a,b) => isDark ? b.luminance - a.luminance : a.luminance - b.luminance); const maxC = Math.min(containers.length >= 5 ? 5 : 3, containers.length); const lvls = ['surface-container-lowest','surface-container-low','surface-container','surface-container-high','surface-container-highest']; for (let i = 0; i < maxC; i++) colors[lvls[i]] = containers[i].color; }
  if (accents.length) { colors.tertiary = accents[0].color; if (accents.length > 1) colors.secondary = accents[1].color; const err = accents.find(a => { const m = a.color.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/); return m && parseInt(m[1]) > 180 && parseInt(m[2]) < 100 && parseInt(m[3]) < 100; }); if (err) colors.error = err.color; }
  if (Object.keys(colors).length < 2) u.push('Fewer than 2 colors extracted.');
  return { colors, uncertain: u };
}
