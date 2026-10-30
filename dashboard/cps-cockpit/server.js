#!/usr/bin/env node
// CPS Manager Cockpit — local live dashboard over specs/ + git, organised by the
// CI&T Production System (CPSBok) phases, practices and Monitoring & Control KPIs.
// Usage: node dashboard/cps-cockpit/server.js [--port 4317] [--root <repo>]
'use strict';

const fs = require('fs');
const path = require('path');
const http = require('http');
const { execFileSync } = require('child_process');

const args = process.argv.slice(2);
const argVal = (flag, def) => {
  const i = args.indexOf(flag);
  return i >= 0 && args[i + 1] ? args[i + 1] : def;
};
const ROOT = path.resolve(argVal('--root', path.join(__dirname, '..', '..')));
const PORT = Number(argVal('--port', process.env.PORT || 4317));
const SPECS = path.join(ROOT, 'specs');

const yaml = require(require.resolve('js-yaml', { paths: [ROOT, __dirname] }));

// ---------- readers ----------
function readYaml(rel) {
  try {
    return yaml.load(fs.readFileSync(path.join(ROOT, rel), 'utf8')) || {};
  } catch {
    return null;
  }
}
function readJson(rel) {
  try {
    return JSON.parse(fs.readFileSync(path.join(ROOT, rel), 'utf8'));
  } catch {
    return null;
  }
}
function exists(rel) {
  return fs.existsSync(path.join(ROOT, rel));
}
function mtime(rel) {
  try {
    return fs.statSync(path.join(ROOT, rel)).mtime.toISOString();
  } catch {
    return null;
  }
}
function countFiles(rel, re) {
  try {
    return fs.readdirSync(path.join(ROOT, rel)).filter((f) => re.test(f)).length;
  } catch {
    return 0;
  }
}
function git(...a) {
  try {
    return execFileSync('git', a, { cwd: ROOT, encoding: 'utf8', maxBuffer: 32 << 20 }).trim();
  } catch {
    return '';
  }
}

// ---------- git model ----------
function gitModel() {
  const raw = git('log', '--since=180.days', '--format=%H%x1f%cI%x1f%s%x1f%an');
  const commits = raw
    ? raw.split('\n').map((l) => {
        const [hash, date, subject, author] = l.split('\x1f');
        const m = /^(\w+)(\([^)]*\))?!?:/.exec(subject || '');
        return { hash: hash.slice(0, 8), date, subject, author, type: m ? m[1] : 'other' };
      })
    : [];
  const tagsRaw = git('for-each-ref', 'refs/tags', '--sort=-creatordate', '--count=40',
    '--format=%(refname:short)%1f%(creatordate:iso-strict)');
  const tags = tagsRaw
    ? tagsRaw.split('\n').map((l) => {
        const [name, date] = l.split('\x1f');
        return { name, date };
      })
    : [];
  return { head: git('rev-parse', '--short', 'HEAD'), branch: git('rev-parse', '--abbrev-ref', 'HEAD'), commits, tags };
}

// epic completion date ≈ newest commit whose subject names the epic id;
// a renumbered epic matches its new id from the renumber date on and its former id before it
function epicDoneDates(epics) {
  const raw = git('log', '--format=%cI%x1f%s');
  const out = {};
  if (!raw) return out;
  const lines = raw.split('\n').map((l) => l.split('\x1f'));
  const idRe = (id) => new RegExp(`\\b${id}(s\\d+)?\\b`, 'i');
  for (const e of epics) {
    const now = idRe(e.id);
    const before = e.formerly ? idRe(e.formerly) : null;
    const hit = lines.find(([d, s]) => (!e.renumberedOn || d >= e.renumberedOn ? now : before)?.test(s || ''));
    if (hit) out[e.id] = hit[0];
  }
  return out;
}

// ---------- CPS practice evidence ----------
function practices(ctx) {
  const ok = (cond, evidence) => ({ status: cond ? 'ok' : 'missing', evidence });
  const manual = (evidence) => ({ status: 'manual', evidence });
  const P = (n, name, r) => ({ n, name, ...r });
  const { open, rp, receipts, bugsOpen, state, tags } = ctx;
  const adr = countFiles('specs/adr', /\.md$/);
  const verif = countFiles('specs/verifications', /.*/);
  const openWithTasks = open.filter((e) => e.storiesWithTasks > 0).length;
  const wsjfCount = (rp.epics || []).filter((e) => e.wsjf != null).length;
  const unestimated = open.filter((e) => !e.bcps).length;
  const wip = open.filter((e) => e.status === 'in_progress' || e.status === 'in-progress').length;
  const daysRelease = tags[0] ? (Date.now() - Date.parse(tags[0].date)) / 864e5 : null;
  const rpAge = (Date.now() - Date.parse(mtime('specs/release-plan.yaml') || 0)) / 864e5;
  return {
    setup: [
      P(4, 'Develop Vision', ok(exists('specs/product/VISION_LATEST.yaml'), 'specs/product/VISION_LATEST.yaml')),
      P(5, 'Plan Setup', ok(exists('specs/product/SCOPE_LATEST.yaml'), 'specs/product/SCOPE_LATEST.yaml')),
      P(6, 'Obtain Client Commitment', manual('Acordo com cliente / PO fora do repositório')),
      P(7, 'Build Correct Teams', manual(exists('CONTRIBUTORS.md') ? 'CONTRIBUTORS.md (solo dev + agentes)' : 'fora do repositório')),
      P(8, 'Empower Team & Client', ok(exists('CONVENTIONS.md') && exists('CLAUDE.md'), 'CLAUDE.md + CONVENTIONS.md')),
      P(9, 'PO Coaching (Setup)', manual('Sessões de coaching do PO')),
      P(10, 'Develop Product Backlog', ok((rp.epics || []).length > 0, `${(rp.epics || []).length} épicos em release-plan.yaml`)),
      P(11, 'Model Business Processes', ok(exists('specs/workflows'), 'specs/workflows/')),
      P(12, 'Perform Value Engineering', ok(wsjfCount > 0, `${wsjfCount} épicos com WSJF`)),
      P(13, 'Evaluate Inputs (Setup)', ok(exists('specs/PLAN-AUDIT_LATEST.md'), 'specs/PLAN-AUDIT_LATEST.md')),
    ],
    flow: [
      P(14, 'Develop Architecture Package', ok(exists('specs/tech-architecture/tech-stack.md') && adr > 0, `tech-stack.md + ${adr} ADRs`)),
      P(15, 'Install Technical Capacity', ok(exists('SKILL-INDEX.md'), 'SKILL-INDEX.md (catálogo de skills)')),
      P(16, 'Perform Backlog Refinement', open.length === 0 ? ok(true, 'sem épicos abertos') :
        { status: openWithTasks ? 'partial' : 'missing', evidence: `${openWithTasks}/${open.length} épicos abertos com tasks.yaml` }),
      P(17, 'Perform Value Governance', ok(wsjfCount > 0, 'WSJF + rationale por épico')),
      P(18, 'Plan Delivery Capacity', { status: unestimated ? 'partial' : 'ok', evidence: unestimated ? `${unestimated} épicos abertos sem BCP` : 'todos os épicos abertos estimados em BCP' }),
      P(19, 'Perform Monitoring & Control', ok(exists('specs/metrics/cycle-times.yaml'), 'este cockpit + metrics/cycle-times.yaml')),
      P(20, 'Expectations Management', ok(exists('CHANGELOG.md'), 'CHANGELOG.md')),
      P(21, 'Review Roadmap', { status: rpAge <= 30 ? 'ok' : 'partial', evidence: `release-plan.yaml atualizado há ${Math.round(rpAge)} dias` }),
      P(22, 'Impediment Management', { status: bugsOpen.length ? 'partial' : 'ok', evidence: `${bugsOpen.length} impedimentos abertos no registry` }),
      P(23, 'Ensure Execution of Rituals', ok(!!(state.handoff && state.handoff.context), 'handoff em state.yaml (session-state)')),
      P(24, 'Control Progress/Stability/Quality', ok(!!receipts, 'specs/receipts.json')),
      P(25, 'Continuous Improvement', ok(countFiles('specs', /^STOCKTAKE/) > 0, 'STOCKTAKE-*.md')),
      P(26, 'One Piece Flow', { status: wip <= 1 ? 'ok' : 'partial', evidence: `WIP = ${wip} épico(s) em andamento` }),
      P(27, 'Burn Quality In', ok(exists('.github/workflows/test-build-release.yml'), 'CI test-build-release + hooks')),
      P(28, 'Continuous Homologation', ok(verif > 0, `${verif} itens em specs/verifications`)),
      P(29, 'PO Coaching (Flow)', manual('Coaching contínuo do PO')),
      P(30, 'Evaluate Inputs (Flow)', ok(exists('specs/IMPACT_LATEST.md'), 'specs/IMPACT_LATEST.md')),
    ],
    activation: [
      P(31, 'Plan Production Entry', ok(!!(rp.release && rp.release.semantic_release), 'semantic-release configurado')),
      P(32, 'Impediments (Activation)', { status: bugsOpen.some((b) => /release|ci|npm|install/i.test(b.scope || '')) ? 'partial' : 'ok', evidence: 'bugs de release/instalação abertos' }),
      P(33, 'Expectations (Activation)', ok(exists('CHANGELOG.md'), 'release notes / CHANGELOG')),
      P(34, 'Late Homologation', ok(!!(receipts && receipts.golden_suite), 'golden suite')),
      P(35, 'Support Production Entry', { status: daysRelease == null ? 'missing' : daysRelease <= 14 ? 'ok' : 'partial', evidence: tags[0] ? `último release ${tags[0].name}` : 'sem tags' }),
      P(36, 'Perform Change Management', ok(exists('specs/migrations'), 'specs/migrations/')),
      P(37, 'Evaluate Inputs (Activation)', ok(!!(state.release && state.release.ci_verified), 'release.ci_verified em state.yaml')),
    ],
  };
}

// ---------- main model ----------
function median(a) {
  if (!a.length) return null;
  const s = [...a].sort((x, y) => x - y);
  const m = s.length >> 1;
  return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2;
}
function pct(a, p) {
  if (!a.length) return null;
  const s = [...a].sort((x, y) => x - y);
  return s[Math.min(s.length - 1, Math.ceil((p / 100) * s.length) - 1)];
}
function weekKey(d) {
  const t = new Date(d);
  const day = (t.getUTCDay() + 6) % 7;
  t.setUTCDate(t.getUTCDate() - day);
  return t.toISOString().slice(0, 10);
}
const isDone = (s) => ['done', 'passing', 'released', 'fixed', 'resolved', 'closed'].includes(String(s || '').toLowerCase());

function buildModel() {
  const state = readYaml('specs/state.yaml') || {};
  const rp = readYaml('specs/release-plan.yaml') || {};
  const ex = readYaml('specs/execution-status.yaml') || {};
  const bugsReg = readYaml('specs/bugs/registry.yaml') || {};
  const cycle = readYaml('specs/metrics/cycle-times.yaml') || {};
  const receipts = readJson('specs/receipts.json');
  const pkg = readJson('package.json') || {};
  const g = gitModel();

  // epics: merge release-plan + execution-status + capsule epic.yaml
  const exEpics = ex.epics || {};
  const rpById = Object.fromEntries((rp.epics || []).map((e) => [e.id, e]));
  const ids = new Set([...Object.keys(exEpics), ...Object.keys(rpById)]);
  const renumbered = ((rp.renumbered || {}).map || []).filter((r) => r && r.from && r.to);
  const renumberedTo = Object.fromEntries(renumbered.map((r) => [r.from, r]));
  const renumberedFrom = Object.fromEntries(renumbered.map((r) => [r.to, r]));
  const epics = [...ids].map((id) => {
    const r = rpById[id] || {};
    const x = exEpics[id] || {};
    const status = r.status || x.status || (ex.development_status || {})[id] || 'unknown';
    let stories = [];
    let storiesWithTasks = 0;
    let projected = 0;
    const dir = r.capsule_dir ? path.join('specs', r.capsule_dir) : null;
    if (dir && !isDone(status)) {
      const cap = readYaml(path.join(dir, 'epic.yaml'));
      if (cap && cap.bcps_projected) projected = cap.bcps_projected;
      if (cap && Array.isArray(cap.stories)) {
        stories = cap.stories.map((s) => ({ id: s.id, title: s.title, status: s.status || 'todo', bcps: s.bcps ?? s.size ?? null }));
        storiesWithTasks = stories.filter((s) => exists(path.join(dir, `${s.id}-tasks.yaml`))).length;
      }
    }
    return {
      id, title: r.title || x.title || id, status, wsjf: r.wsjf ?? null,
      formerly: renumberedFrom[id]?.from || null, renumberedOn: renumberedFrom[id] ? String(renumberedFrom[id].date) : null,
      bcps: r.bcps || x.total_bcps || projected || 0, projected: !r.bcps && !x.total_bcps && !!projected, rationale: r.wsjf_rationale || '', stories, storiesWithTasks,
    };
  }).sort((a, b) => Number(a.id.slice(1)) - Number(b.id.slice(1)));

  const open = epics.filter((e) => !isDone(e.status));
  const done = epics.filter((e) => isDone(e.status));

  // scope map: every epic number from e01 to the highest, gaps resolved to the epic that absorbed them
  const absorbedBy = {};
  for (const e of rp.epics || []) {
    const txt = `${e.wsjf_rationale || ''} ${e.notes || ''} ${e.source || ''}`;
    for (const m of txt.matchAll(/[Ff]ormer(?:ly)?[^.;]*/g)) {
      for (const id of m[0].match(/\be\d{2}\b/g) || []) if (id !== e.id && !absorbedBy[id]) absorbedBy[id] = e.id;
    }
  }
  const byId = Object.fromEntries(epics.map((e) => [e.id, e]));
  const maxN = Math.max(0, ...epics.map((e) => Number(e.id.slice(1))), ...(rp.build_order || []).map((id) => Number(id.slice(1))));
  const inOrder = new Set(rp.build_order || []);
  const scopeMap = Array.from({ length: maxN }, (_, i) => {
    const id = `e${String(i + 1).padStart(2, '0')}`;
    const e = byId[id];
    if (!e) {
      const rn = renumberedTo[id];
      return { id, gap: true, absorbedBy: absorbedBy[id] || null, renumberedTo: rn ? rn.to : null, renumberedOn: rn ? String(rn.date) : null };
    }
    return { id, status: e.status, done: isDone(e.status), bcps: e.bcps, projected: e.projected, wsjf: e.wsjf, inOrder: inOrder.has(id), formerly: e.formerly };
  });
  const exStories = Object.entries(ex.stories || {}).map(([id, s]) => ({ id, ...s }));
  const storiesDone = exStories.filter((s) => isDone(s.status)).length;
  const bcpDone = done.reduce((a, e) => a + (e.bcps || 0), 0);
  const bcpOpen = open.reduce((a, e) => a + (e.bcps || 0), 0);

  // flow metrics from cycle-times
  const entries = (cycle.stories || []).filter((s) => s && typeof s === 'object');
  const storyEntries = entries.filter((s) => /^e\d+s\d+$/.test(s.id || ''));
  const cycleMins = storyEntries.map((s) => s.cycle_minutes).filter((n) => typeof n === 'number');
  const measuredMins = storyEntries.filter((s) => s.source === 'measured').map((s) => s.cycle_minutes).filter(Number.isFinite);
  const leadMins = entries.map((s) => s.lead_time_minutes).filter((n) => typeof n === 'number');
  const sources = {};
  for (const s of entries) sources[s.source || 'unknown'] = (sources[s.source || 'unknown'] || 0) + 1;

  // burn-up / velocity derived from epic completion dates in git
  const doneDates = epicDoneDates(done);
  const weeks = [];
  const now = new Date();
  for (let i = 25; i >= 0; i--) weeks.push(weekKey(new Date(now - i * 7 * 864e5)));
  const bcpByWeek = Object.fromEntries(weeks.map((w) => [w, 0]));
  const epicsByWeek = Object.fromEntries(weeks.map((w) => [w, []]));
  const burn = [];
  for (const e of done) {
    const d = doneDates[e.id];
    if (!d) continue;
    burn.push({ date: d, bcps: e.bcps || 0, id: e.id });
    const w = weekKey(d);
    if (w in bcpByWeek) {
      bcpByWeek[w] += e.bcps || 0;
      epicsByWeek[w].push(e.id);
    }
  }
  burn.sort((a, b) => a.date.localeCompare(b.date));
  let cum = 0;
  const burnup = burn.map((b) => ({ date: b.date, id: b.id, cum: (cum += b.bcps) }));

  // git throughput
  const commitsByWeek = Object.fromEntries(weeks.map((w) => [w, { feat: 0, fix: 0, other: 0, release: 0 }]));
  for (const c of g.commits) {
    const w = weekKey(c.date);
    if (!(w in commitsByWeek)) continue;
    if (/^chore\(release\)/.test(c.subject)) commitsByWeek[w].release++;
    else if (c.type === 'feat') commitsByWeek[w].feat++;
    else if (c.type === 'fix') commitsByWeek[w].fix++;
    else commitsByWeek[w].other++;
  }
  const last4 = weeks.slice(-4);
  const releases30 = g.tags.filter((t) => Date.now() - Date.parse(t.date) <= 30 * 864e5).length;
  const ff30 = g.commits.filter((c) => Date.now() - Date.parse(c.date) <= 30 * 864e5 && ['feat', 'fix'].includes(c.type));
  const fixRatio = ff30.length ? ff30.filter((c) => c.type === 'fix').length / ff30.length : null;

  // impediments
  const bugs = (bugsReg.bugs || []).map((b) => ({ id: b.id, status: b.status, severity: b.severity, scope: b.scope, title: b.title }));
  const bugsOpen = bugs.filter((b) => !isDone(b.status));
  const sev = { critical: 0, high: 0, medium: 0, low: 0 };
  for (const b of bugs) if (b.severity in sev) sev[b.severity]++;

  // freshness
  const sources_mtime = {};
  for (const f of ['specs/state.yaml', 'specs/release-plan.yaml', 'specs/execution-status.yaml', 'specs/bugs/registry.yaml', 'specs/metrics/cycle-times.yaml', 'specs/receipts.json']) {
    sources_mtime[f] = mtime(f);
  }

  // RAG health per CPS control dimension (ch. 19)
  const daysSinceRelease = g.tags[0] ? (Date.now() - Date.parse(g.tags[0].date)) / 864e5 : null;
  const recAgeDays = receipts && receipts.compliance ? (Date.now() - Date.parse(receipts.compliance.generated_at)) / 864e5 : null;
  const trace = receipts && receipts.traceability ? receipts.traceability.value.coverage_pct : null;
  const golden = receipts && receipts.golden_suite ? receipts.golden_suite.value : null;
  const compliance = receipts && receipts.compliance ? receipts.compliance.value : null;
  const alerts = [];
  const add = (level, area, msg, practice) => alerts.push({ level, area, msg, practice });
  for (const b of bugsOpen) add(b.severity === 'critical' ? 'red' : b.severity === 'high' ? 'amber' : 'info', 'Impedimentos', `${b.id} (${b.severity}) — ${b.title}`, 22);
  if (golden && golden.pass_rate < 1) add('red', 'Qualidade', `Golden suite em ${(golden.pass_rate * 100).toFixed(0)}%`, 27);
  if (compliance != null && compliance < 100) add('amber', 'Qualidade', `Compliance ${compliance}%`, 24);
  if (trace != null && trace < 95) add(trace < 80 ? 'red' : 'amber', 'Qualidade', `Rastreabilidade ${trace}% (${receipts.traceability.value.total_stories - receipts.traceability.value.linked_stories} histórias sem link)`, 24);
  if (recAgeDays != null && recAgeDays > 30) add('amber', 'Dados', `receipts.json com ${Math.round(recAgeDays)} dias — métricas de qualidade desatualizadas`, 19);
  if (daysSinceRelease != null && daysSinceRelease > 14) add(daysSinceRelease > 30 ? 'red' : 'amber', 'Fluxo', `${Math.round(daysSinceRelease)} dias desde o último release`, 35);
  const unest = open.filter((e) => !e.bcps);
  const proj = open.filter((e) => e.projected);
  if (proj.length) add('info', 'Escopo', `${proj.length} épico(s) com BCP apenas projetado (${proj.map((e) => e.id).join(', ')})`, 18);
  if (unest.length) add('amber', 'Escopo', `${unest.length} épicos abertos sem estimativa BCP (${unest.map((e) => e.id).join(', ')})`, 18);
  const backfilled = (sources.backfilled || 0) / Math.max(1, entries.length);
  if (backfilled > 0.5) add('amber', 'Dados', `${Math.round(backfilled * 100)}% dos registros de cycle time são backfilled — velocidade pouco confiável`, 19);
  const drift = open.filter((e) => e.stories.length && e.stories.every((s) => isDone(s.status)));
  if (drift.length) add('amber', 'Escopo', `Drift de status: ${drift.map((e) => e.id).join(', ')} com todas as histórias concluídas mas épico ainda aberto`, 21);
  const vel4 = weeks.slice(-4).reduce((a, w) => a + bcpByWeek[w], 0);
  const lastBurn = burnup[burnup.length - 1];
  if (!vel4 && open.length) add('amber', 'Fluxo', `0 BCP entregue nas últimas 4 semanas${lastBurn ? ` — último épico ${lastBurn.id} em ${lastBurn.date.slice(0, 10)}` : ''}`, 18);
  if (!state.active_epic && open.length) add('info', 'Fluxo', `Nenhum épico ativo; ${open.length} no backlog aguardando puxada (pull)`, 26);
  if (state.release && state.release.ci_verified === false) add('red', 'Estabilidade', 'CI não verificado no último release', 24);

  const worst = (area) => {
    const lv = alerts.filter((a) => a.area === area).map((a) => a.level);
    return lv.includes('red') ? 'red' : lv.includes('amber') ? 'amber' : 'green';
  };
  const dims = ['Escopo', 'Fluxo', 'Qualidade', 'Estabilidade', 'Impedimentos', 'Dados'].map((a) => ({ area: a, rag: worst(a) }));
  const overall = dims.some((d) => d.rag === 'red') ? 'red' : dims.filter((d) => d.rag === 'amber').length >= 2 ? 'amber' : 'green';

  // CPS phase
  let phase = 'flow';
  if (!exists('specs/product/VISION_LATEST.yaml') || !(rp.epics || []).length) phase = 'setup';
  else if (/release|activation/i.test(String(state.active_flow || '')) || (rp.release && rp.release.status === 'releasing')) phase = 'activation';

  const velWeeks = last4.map((w) => bcpByWeek[w]);
  return {
    generated_at: new Date().toISOString(),
    root: ROOT,
    project: { name: pkg.name, version: (rp.release && rp.release.version) || pkg.version, codename: rp.release && rp.release.codename, next: rp.release && rp.release.next_release, release_status: rp.release && rp.release.status },
    phase,
    state: { active_flow: state.active_flow, active_epic: state.active_epic, active_story: state.active_story, bug_id: state.bug_id, handoff: state.handoff || {}, release: state.release || {} },
    health: { overall, dims },
    kpis: {
      epics_total: epics.length, epics_done: done.length, epics_open: open.length,
      stories_total: exStories.length, stories_done: storiesDone,
      bcp_done: bcpDone, bcp_open: bcpOpen,
      velocity_4w: velWeeks.reduce((a, b) => a + b, 0) / 4,
      cycle_p50: median(cycleMins), cycle_p85: pct(cycleMins, 85), cycle_measured_p50: median(measuredMins),
      lead_p50: median(leadMins),
      bugs_open: bugsOpen.length, bugs_total: bugs.length,
      days_since_release: daysSinceRelease, releases_30d: releases30, fix_ratio_30d: fixRatio,
      compliance, golden, trace, receipts_age_days: recAgeDays,
    },
    sources, sources_mtime,
    weeks, bcpByWeek, epicsByWeek, commitsByWeek, burnup,
    scope_total: bcpDone + bcpOpen,
    epics: epics.map(({ rationale, ...e }) => ({ ...e, rationale: String(rationale).slice(0, 220) })),
    build_order: rp.build_order || [],
    scope_map: scopeMap,
    bugs, bugsOpen, severity: sev,
    alerts,
    practices: practices({ open, rp, receipts, bugsOpen, state, tags: g.tags }),
    git: { head: g.head, branch: g.branch, tags: g.tags.slice(0, 10), recent: g.commits.slice(0, 25) },
  };
}

// ---------- server + live push ----------
let model = buildModel();
const clients = new Set();
let timer = null;
function refresh(reason) {
  clearTimeout(timer);
  timer = setTimeout(() => {
    try {
      model = buildModel();
      model.reason = reason;
      const msg = `data: ${JSON.stringify(model)}\n\n`;
      for (const res of clients) res.write(msg);
      console.log(`[cockpit] ${new Date().toLocaleTimeString()} atualizado (${reason})`);
    } catch (e) {
      console.error('[cockpit] erro ao recalcular:', e.message);
    }
  }, 300);
}

try {
  fs.watch(SPECS, { recursive: true }, (_ev, f) => f && !/\.swp$|~$/.test(f) && refresh(`specs/${f}`));
} catch (e) {
  console.warn('[cockpit] fs.watch indisponível, usando apenas polling:', e.message);
}
let lastHead = model.git.head;
setInterval(() => {
  const h = git('rev-parse', '--short', 'HEAD');
  if (h && h !== lastHead) {
    lastHead = h;
    refresh(`git HEAD ${h}`);
  }
}, 5000);
setInterval(() => refresh('poll'), 60000);

const INDEX = path.join(__dirname, 'index.html');
http
  .createServer((req, res) => {
    if (req.url === '/events') {
      res.writeHead(200, { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache', Connection: 'keep-alive' });
      res.write(`data: ${JSON.stringify(model)}\n\n`);
      clients.add(res);
      const ka = setInterval(() => res.write(': ka\n\n'), 25000);
      req.on('close', () => {
        clearInterval(ka);
        clients.delete(res);
      });
      return;
    }
    if (req.url === '/api/model') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      return res.end(JSON.stringify(model));
    }
    if (req.url === '/' || req.url.startsWith('/?')) {
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      return fs.createReadStream(INDEX).pipe(res);
    }
    res.writeHead(404);
    res.end('not found');
  })
  .listen(PORT, '127.0.0.1', () => {
    console.log(`[cockpit] CPS Manager Cockpit em http://localhost:${PORT}  (root: ${ROOT})`);
  });
