function renderMetricsBar(box, projectMetrics, stateData, epics, cycleTimes) {
  if (!box || typeof box.setContent !== 'function') {
    return;
  }

  const ct = cycleTimes || [];
  const epicList = epics && Array.isArray(epics) ? epics : [];

  // Compute totals
  let totalStories = 0;
  let targetBcps = 0;
  epicList.forEach(epic => {
    if (epic.stories && Array.isArray(epic.stories)) {
      totalStories += epic.stories.length;
      epic.stories.forEach(s => { targetBcps += s.bcps || 0; });
    }
  });

  const doneStories = ct.length;
  const totalEpics = epicList.length;
  const doneStoryIds = new Set(ct.map(c => c.id));
  const doneEpics = epicList.filter(e =>
    e.stories && e.stories.length > 0 && e.stories.every(s => doneStoryIds.has(s.id))
  ).length;

  const deliveredBcps = projectMetrics?.totalBcps ?? 0;
  const totalMin = projectMetrics?.totalMin ?? 0;
  const avgBcpPerHour = projectMetrics?.avgBcpPerHour;
  const version = stateData?.release?.target_version ?? '—';
  const branch = stateData?.gitBranch ?? 'main';

  // BCP/hr color threshold
  let bphColor = 'white';
  if (typeof avgBcpPerHour === 'number') {
    if (avgBcpPerHour >= 2.0) bphColor = 'green';
    else if (avgBcpPerHour >= 1.0) bphColor = 'yellow';
    else bphColor = 'red';
  }
  const bphDisplay = typeof avgBcpPerHour === 'number' ? avgBcpPerHour.toFixed(2) : '—';
  const cycleDisplay = totalMin > 0 ? `${totalMin}m` : '—';

  // ── Line 1: status bar ──
  const statusLine =
    `{dim}BCPs:{/dim} {yellow-fg}${deliveredBcps}{/yellow-fg}{dim}/${targetBcps}{/dim}` +
    `  {dim}│{/dim}  {dim}Cycle:{/dim} ${cycleDisplay}` +
    `  {dim}│{/dim}  {dim}BCP/hr:{/dim} {${bphColor}-fg}${bphDisplay}{/${bphColor}-fg}` +
    `  {dim}│{/dim}  {dim}v{/dim}{green-fg}${version}{/green-fg}` +
    `{|}  {dim}branch:{/dim} {green-fg}${branch}{/green-fg}  `;

  // ── Line 2: step info ──
  const currentStep = stateData?.epicCycle?.current_step;
  const activeStory = stateData?.activeStory ?? '—';
  const activeEpic = stateData?.activeEpic ?? '—';
  const activeFlow = stateData?.activeFlow ?? '—';

  const STEP_NAMES = ['survey-context','plan-work','kickoff-branch','develop-tdd','verify-work','audit-code','commit-message','release-branch'];
  const stepName = typeof currentStep === 'number' ? (STEP_NAMES[currentStep] ?? '—') : (currentStep ?? '—');
  const isActive = stepName !== '—' && activeStory !== '—';
  const statusWord = isActive
    ? `{yellow-fg}running{/yellow-fg}`
    : `{green-fg}ready{/green-fg}`;
  const storyDesc = isActive
    ? `{dim}${activeEpic}{/dim} {dim}›{/dim} {cyan-fg}${activeStory}{/cyan-fg} {dim}—{/dim} ${stepName}`
    : `{dim}flow:{/dim} ${activeFlow}  {dim}next:{/dim} {cyan-fg}${stateData?.epicCycle?.next_skill ?? 'survey-context'}{/cyan-fg}`;
  const stepLine =
    `{dim}step {/dim}{cyan-fg}${doneStories}{/cyan-fg}{dim}/${totalStories}{/dim}` +
    `  {dim}—{/dim}  ${statusWord}` +
    `  {dim}—{/dim}  ${storyDesc}`;

  // ── Line 3: stats row ──
  const statsLine =
    `{dim}[{/dim} epics {green-fg}${doneEpics}${doneEpics > 0 ? '' : ''}{/green-fg}{dim}/${totalEpics} ]{/dim}` +
    `   {dim}[{/dim} stories {cyan-fg}${doneStories}{/cyan-fg}{dim}/${totalStories} ]{/dim}` +
    `   {dim}[{/dim} BCPs {yellow-fg}${deliveredBcps}{/yellow-fg}{dim}/${targetBcps} ]{/dim}` +
    `   {dim}[{/dim} cycle ${cycleDisplay}{dim} ]{/dim}` +
    `   {dim}[{/dim} BCP/hr {${bphColor}-fg}${bphDisplay}{/${bphColor}-fg}{dim} ]{/dim}` +
    `   {dim}[{/dim} v{green-fg}${version}{/green-fg}{dim} ]{/dim}`;

  box.setContent([statusLine, stepLine, statsLine].join('\n'));
}

module.exports = { renderMetricsBar };
