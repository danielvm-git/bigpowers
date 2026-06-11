const STEP_NAMES = [
  'survey-context', 'plan-work', 'kickoff-branch', 'develop-tdd',
  'verify-work', 'audit-code', 'commit-message', 'release-branch'
];
const STEP_ABBR = ['sur', 'pla', 'kic', 'tdd', 'ver', 'aud', 'com', 'rel'];

function renderStateYaml(box, stateData) {
  if (!box || typeof box.setContent !== 'function') {
    return;
  }

  if (!stateData) {
    box.setContent('{center}{dim}state.yaml not found{/dim}{/center}');
    return;
  }

  const rawStep = stateData.epicCycle?.current_step;
  const currentIdx = typeof rawStep === 'number' ? rawStep : STEP_NAMES.indexOf(rawStep);
  const stepName = currentIdx >= 0 ? STEP_NAMES[currentIdx] : (rawStep ?? '—');
  const nextSkill = stateData.epicCycle?.next_skill ?? stateData.handoff?.next_skill ?? '—';

  const fields = [
    { key: 'active_flow',         value: stateData.activeFlow,    color: 'cyan' },
    { key: 'active_epic',         value: stateData.activeEpic,    color: 't' },
    { key: 'active_story',        value: stateData.activeStory,   color: 't' },
    { key: 'current_step',        value: stepName,                color: currentIdx >= 0 ? 'yellow' : 'dim' },
    { key: 'next_skill',          value: nextSkill,               color: 'green' },
    { key: 'git.branch',          value: stateData.gitBranch,     color: 'green' },
    { key: 'metrics.story_start', value: stateData.metrics?.story_start, color: 'dim' },
  ];

  const lines = fields.map(({ key, value }) => {
    const v = value ?? '—';
    const isDash = v === '—';
    let colored;
    if (isDash) {
      colored = `{dim}${v}{/dim}`;
    } else if (fields.find(f => f.key === key)?.color === 'cyan') {
      colored = `{cyan-fg}${v}{/cyan-fg}`;
    } else if (fields.find(f => f.key === key)?.color === 'green') {
      colored = `{green-fg}${v}{/green-fg}`;
    } else if (fields.find(f => f.key === key)?.color === 'yellow') {
      colored = `{yellow-fg}${v}{/yellow-fg}`;
    } else if (fields.find(f => f.key === key)?.color === 'dim') {
      colored = `{dim}${v}{/dim}`;
    } else {
      colored = v;
    }
    return `{dim}${key}:{/dim} ${colored}`;
  });

  // Stage tracker strip
  const tracker = STEP_ABBR.map((abbr, i) => {
    if (i < currentIdx) return `{green-fg}${abbr}{/green-fg}`;
    if (i === currentIdx) return `{cyan-fg}{bold}${abbr}{/bold}{/cyan-fg}`;
    return `{dim}${abbr}{/dim}`;
  }).join(' {dim}·{/dim} ');

  lines.push('');
  lines.push(tracker);

  box.setContent(lines.join('\n'));
}

module.exports = { renderStateYaml };
