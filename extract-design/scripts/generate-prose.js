import { AGENT_NOTE_LOW_CONFIDENCE } from './lib/constants.js';
export function generateProse(ctx) {
  const { name, colors, typography, spacing, rounded, components, hints, detectedPatterns } = ctx;
  const glass = hints?.glassDetected, dark = hints?.dominantColorFamily === 'dark', swiss = (hints?.styleSignals||[]).includes('swiss');
  let personality = 'modern and functional';
  if (glass && dark) personality = 'ethereal and depth-driven, using glassmorphism for layered space';
  else if (swiss) personality = 'architectural and editorial, rooted in International Typographic Style';
  else if (dark) personality = 'dark, sophisticated, and focused';

  const secs = [];
  secs.push(`## Overview\n\n${AGENT_NOTE_LOW_CONFIDENCE}\n\n${name} is a ${personality} design system.${glass ? ' The UI relies on frosted glass surfaces and blurred backgrounds to create physical depth through transparency.' : ''}${hints?.fontCount===1?' It uses a single type family.':''}`);

  let cl = ['## Colors',''];
  for (const [k,v] of Object.entries(colors||{})) { if (k==='surface') cl.push(`**Surface (${v}):** Foundational background.`); else if (k==='on-surface') cl.push(`**On Surface (${v}):** Primary text.`); else if (k==='tertiary') cl.push(`**Tertiary (${v}):** Primary accent for CTAs.`); else if (k==='error') cl.push(`**Error (${v}):** Destructive actions.`); else if (k.includes('container')) cl.push(`**${k} (${v}):** Elevated surface.`); else cl.push(`**${k} (${v}):** Used throughout.`); }
  cl.push('','Maintain WCAG AA contrast (4.5:1).'); secs.push(cl.join('\n'));

  let tl = ['## Typography',''];
  for (const [k,v] of Object.entries(typography||{})) tl.push(`**${k}:** ${v.fontFamily} at ${v.fontSize}${v.fontWeight!=='400'?`, weight ${v.fontWeight}`:''}.`);
  secs.push(tl.join('\n'));

  if (spacing?.unit) secs.push(`## Layout\n\nLayout follows a ${spacing.unit} base grid${spacing.half?` with a ${spacing.half} half-step`:''}. Components use containment principles.`);
  secs.push(`## Elevation & Depth\n\n${glass?'Depth is achieved through glassmorphism — frosted surfaces with backdrop blur.':'A flat design with hierarchy via typography, spacing, and color contrast.'}`);
  const re = Object.entries(rounded||{}).filter(([k])=>k!=='none');
  secs.push(`## Shapes\n\n${re.length?`Elements use rounded corners (${re.map(([,v])=>v).join(', ')}).`:'Sharp corners — engineered aesthetic.'}`);

  let cpl = ['## Components','',AGENT_NOTE_LOW_CONFIDENCE,''];
  if (detectedPatterns?.includes('button-primary')) cpl.push('**Buttons:** Primary buttons use accent color.','');
  if (detectedPatterns?.includes('card-standard')) cpl.push('**Cards:** Containers with rounded corners group content.','');
  if (detectedPatterns?.includes('input-field')) cpl.push('**Inputs:** Distinct background separates editable areas.','');
  secs.push(cpl.join('\n'));

  const dos = ['Maintain WCAG AA contrast','Use consistent spacing','Keep typography hierarchy clear','Treat interactive elements consistently'];
  const donts = ["Don't mix rounded and sharp corners","Don't use more than two font weights per screen"];
  if (glass) { dos.push('Use backdrop-filter on elevated surfaces'); donts.push("Don't use solid backgrounds on cards"); }
  if (dark) donts.push("Don't introduce light backgrounds");
  secs.push(`## Do's and Don'ts\n\n${AGENT_NOTE_LOW_CONFIDENCE}\n\n${dos.map(d=>'- '+d).join('\n')}\n${donts.map(d=>'- '+d).join('\n')}`);
  return secs.join('\n\n');
}
