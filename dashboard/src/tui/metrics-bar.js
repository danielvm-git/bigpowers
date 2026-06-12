function renderMetricsBar(box, projectMetrics, stateData, epics, cycleTimes, executionStatus) {
  if (!box || typeof box.setContent !== 'function') {
    return;
  }

  const epicList = epics && Array.isArray(epics) ? epics : [];
  const statusMap = executionStatus?.epics || new Map();

  // Compute totals and completed counts dynamically from execution-status.yaml
  let totalStories = 0;
  let targetBcps = 0;
  let doneStories = 0;
  let deliveredBcps = 0;
  let doneEpics = 0;

  epicList.forEach(epic => {
    let epicDone = true;
    let hasStories = false;
    if (epic.stories && Array.isArray(epic.stories)) {
      epic.stories.forEach(s => {
        hasStories = true;
        totalStories++;
        targetBcps += s.bcps || 0;
        if (statusMap.get(s.id) === 'done') {
          doneStories++;
          deliveredBcps += s.bcps || 0;
        } else {
          epicDone = false;
        }
      });
    }
    if (hasStories && epicDone) {
      doneEpics++;
    }
  });

  const totalEpics = epicList.length;
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
    `{gray-fg}BCPs:{/gray-fg} {yellow-fg}${deliveredBcps}{/yellow-fg}{gray-fg}/${targetBcps}{/gray-fg}` +
    `  {gray-fg}│{/gray-fg}  {gray-fg}Cycle:{/gray-fg} ${cycleDisplay}` +
    `  {gray-fg}│{/gray-fg}  {gray-fg}BCP/hr:{/gray-fg} {${bphColor}-fg}${bphDisplay}{/${bphColor}-fg}` +
    `  {gray-fg}│{/gray-fg}  {gray-fg}v{/gray-fg}{green-fg}${version}{/green-fg}` +
    `  {gray-fg}branch:{/gray-fg} {green-fg}${branch}{/green-fg}`;

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
    ? `{gray-fg}${activeEpic}{/gray-fg} {gray-fg}›{/gray-fg} {cyan-fg}${activeStory}{/cyan-fg} {gray-fg}—{/gray-fg} ${stepName}`
    : `{gray-fg}flow:{/gray-fg} ${activeFlow}  {gray-fg}next:{/gray-fg} {cyan-fg}${stateData?.epicCycle?.next_skill ?? 'survey-context'}{/cyan-fg}`;
  const stepLine =
    `{gray-fg}step {/gray-fg}{cyan-fg}${doneStories}{/cyan-fg}{gray-fg}/${totalStories}{/gray-fg}` +
    `  {gray-fg}—{/gray-fg}  ${statusWord}` +
    `  {gray-fg}—{/gray-fg}  ${storyDesc}`;

  // ── Line 3: stats row ──
  const statsLine =
    `{gray-fg}[{/gray-fg} epics {green-fg}${doneEpics}${doneEpics > 0 ? '' : ''}{/green-fg}{gray-fg}/${totalEpics} ]{/gray-fg}` +
    `   {gray-fg}[{/gray-fg} stories {cyan-fg}${doneStories}{/cyan-fg}{gray-fg}/${totalStories} ]{/gray-fg}` +
    `   {gray-fg}[{/gray-fg} BCPs {yellow-fg}${deliveredBcps}{/yellow-fg}{gray-fg}/${targetBcps} ]{/gray-fg}` +
    `   {gray-fg}[{/gray-fg} cycle ${cycleDisplay}{gray-fg} ]{/gray-fg}` +
    `   {gray-fg}[{/gray-fg} BCP/hr {${bphColor}-fg}${bphDisplay}{/${bphColor}-fg}{gray-fg} ]{/gray-fg}` +
    `   {gray-fg}[{/gray-fg} v{green-fg}${version}{/green-fg}{gray-fg} ]{/gray-fg}`;

  box.setContent([statusLine, stepLine, statsLine].join('\n'));
}

module.exports = { renderMetricsBar };
