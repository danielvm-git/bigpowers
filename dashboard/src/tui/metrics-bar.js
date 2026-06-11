function renderMetricsBar(box, projectMetrics, stateData, epics) {
  if (!box || typeof box.setContent !== 'function') {
    return;
  }

  // Count epics and stories
  let epicCount = 0;
  let storyCount = 0;
  let targetBcps = 0;

  if (epics && Array.isArray(epics)) {
    epicCount = epics.length;
    epics.forEach(epic => {
      if (epic.stories && Array.isArray(epic.stories)) {
        storyCount += epic.stories.length;
        epic.stories.forEach(story => {
          targetBcps += story.bcps || 0;
        });
      }
    });
  }

  const deliveredBcps = projectMetrics?.totalBcps ?? '-';
  const totalMin = projectMetrics?.totalMin ?? '-';
  const avgBcpPerHour = projectMetrics?.avgBcpPerHour ?? '-';
  const version = stateData?.release?.target_version ?? '-';

  let bcpHrColor = 'white';
  if (typeof avgBcpPerHour === 'number') {
    if (avgBcpPerHour >= 2.0) {
      bcpHrColor = 'green';
    } else if (avgBcpPerHour >= 1.0) {
      bcpHrColor = 'yellow';
    } else {
      bcpHrColor = 'red';
    }
  }

  const avgCycleTime = totalMin === '-' ? '-' : `${totalMin}m`;
  const bcpHrDisplay = typeof avgBcpPerHour === 'number' ? avgBcpPerHour.toFixed(2) : avgBcpPerHour;

  const line = `epics: ${epicCount} | stories: ${storyCount} | BCPs: ${deliveredBcps}/${targetBcps} | cycle: ${avgCycleTime} | {${bcpHrColor}}BCP/hr: ${bcpHrDisplay}{/${bcpHrColor}} | v${version}`;

  box.setContent(line);
}

module.exports = { renderMetricsBar };
