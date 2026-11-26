function extract(st) { const t = {}; if (st.backgroundColor && st.backgroundColor !== 'rgba(0, 0, 0, 0)') t.backgroundColor = st.backgroundColor; if (st.color && st.color !== 'rgba(0, 0, 0, 0)') t.textColor = st.color; if (st.borderRadius && st.borderRadius !== '0px') t.rounded = st.borderRadius; if (st.padding && st.padding !== '0px') { const p = st.padding.split(/\s+/); t.padding = p.length === 2 && p[0] === p[1] ? p[0] : st.padding; } if (st.height > 0) t.height = `${Math.round(st.height)}px`; return t; }
export async function detectComponents(styles, page = null) { const u = []; const comp = {}; const pat = [];
  const btnCands = styles.filter(s => { if (!s.width && !s.height) return false; return s.isButton || (s.width < 300 && s.height < 64 && s.height > 20 && s.backgroundColor && s.backgroundColor !== 'rgba(0, 0, 0, 0)' && s.borderRadius && s.borderRadius !== '0px' && s.text.length > 0 && s.text.length < 50); });
  const uqBtns = new Map(); for (const c of btnCands) { const k = `${c.backgroundColor}|${c.color}|${c.borderRadius}`; if (!uqBtns.has(k)) uqBtns.set(k, c); }
  const btns = [...uqBtns.values()]; if (btns.length) { comp['button-primary'] = extract(btns[0]); pat.push('button-primary'); if (btns.length > 1) { comp['button-secondary'] = extract(btns[1]); pat.push('button-secondary'); } }
  const cardCands = styles.filter(s => s.backgroundColor && s.backgroundColor !== 'rgba(0, 0, 0, 0)' && s.borderRadius && s.borderRadius !== '0px' && s.padding && s.padding !== '0px' && (s.width > 200 || s.height > 100));
  const uqCards = new Map(); for (const c of cardCands) { const k = `${c.backgroundColor}|${c.borderRadius}|${c.padding}`; if (!uqCards.has(k)) uqCards.set(k, c); }
  const cards = [...uqCards.values()]; if (cards.length) { comp['card-standard'] = extract(cards[0]); pat.push('card-standard'); if (cards.length > 1) { comp['card-elevated'] = extract(cards[1]); pat.push('card-elevated'); } }
  const inputs = styles.filter(s => s.isInput); if (inputs.length) { comp['input-field'] = extract(inputs[0]); pat.push('input-field'); }
  if (!Object.keys(comp).length) u.push('No components detected.');
  return { components: comp, detectedPatterns: pat, uncertain: u };
}
