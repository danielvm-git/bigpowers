function renderMetricsBar(box, projectMetrics, stateData) {
  if (!box || typeof box.setContent !== 'function') {
    return;
  }

  const totalBcps = projectMetrics?.totalBcps ?? '-';
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

  const line = `BCPs: ${totalBcps} | Cycle: ${avgCycleTime} | {${bcpHrColor}}BCP/hr: ${bcpHrDisplay}{/${bcpHrColor}} | v${version}`;

  box.setContent(line);
}

module.exports = { renderMetricsBar };
