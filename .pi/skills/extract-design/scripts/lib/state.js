import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import { log } from './logging.js';
const STATE_PATH = 'specs/state.yaml';

export function writeGrillMeHandoff(ctx = {}) {
  const ul = (ctx.uncertainDecisions || []).map(d => `  - ${d}`).join('\n');
  const hb = ['handoff:','  last_step_completed: >',`    extract-design completed. DESIGN_LATEST.md written with ${ctx.tokenCount || '?'} tokens, ${ctx.componentCount || '?'} components.`,`    ${ctx.uncertainCount || 0} uncertain decisions flagged.`,'  required_reading:','    - specs/tech-architecture/DESIGN_LATEST.md','  next_skill: grill-me'];
  if (ul) { hb.push('  uncertain_decisions:'); hb.push(ul); }
  try {
    const d = dirname(STATE_PATH); if (!existsSync(d)) mkdirSync(d, { recursive: true });
    let c = existsSync(STATE_PATH) ? readFileSync(STATE_PATH, 'utf8') : '';
    if (!c.includes('next_skill:')) { c = c.trimEnd() + '\n' + hb.join('\n') + '\n'; writeFileSync(STATE_PATH, c, 'utf8'); log.info('handoff-written', { nextSkill: 'grill-me' }); }
  } catch (e) { log.warn('handoff-failed', { error: e.message }); }
}
