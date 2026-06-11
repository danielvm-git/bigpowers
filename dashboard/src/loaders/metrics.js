/**
 * computeEpicMetrics(cycleTimes)
 * Groups cycle times by epic prefix (e.g. e01 from e01s01)
 * Returns Map of epicId to { avgCycleMin, totalBcps, avgBcpPerHour }
 */
function computeEpicMetrics(cycleTimes) {
  if (!cycleTimes || cycleTimes.length === 0) {
    return new Map();
  }

  const epicMap = new Map();
  for (const story of cycleTimes) {
    // Extract epic prefix: e01s01 -> e01
    const epicId = story.id ? story.id.replace(/s\d+$/, '') : null;
    if (!epicId) continue;

    if (!epicMap.has(epicId)) {
      epicMap.set(epicId, { stories: [] });
    }
    epicMap.get(epicId).stories.push(story);
  }

  const result = new Map();
  for (const [epicId, data] of epicMap) {
    const stories = data.stories;
    const totalBcps = stories.reduce((sum, s) => sum + (s.bcps || 0), 0);
    const totalMin = stories.reduce((sum, s) => sum + (s.cycleMin || 0), 0);
    const avgCycleMin = stories.length > 0 ? totalMin / stories.length : 0;
    const avgBcpPerHour = totalMin > 0 ? (totalBcps * 60) / totalMin : 0;

    result.set(epicId, {
      avgCycleMin,
      totalBcps,
      avgBcpPerHour
    });
  }

  return result;
}

/**
 * computeProjectMetrics(cycleTimes)
 * Returns { totalBcps, totalMin, avgBcpPerHour } or null if no data
 */
function computeProjectMetrics(cycleTimes) {
  if (!cycleTimes || cycleTimes.length === 0) {
    return null;
  }

  const totalBcps = cycleTimes.reduce((sum, s) => sum + (s.bcps || 0), 0);
  const totalMin = cycleTimes.reduce((sum, s) => sum + (s.cycleMin || 0), 0);
  const avgBcpPerHour = totalMin > 0 ? (totalBcps * 60) / totalMin : 0;

  return {
    totalBcps,
    totalMin,
    avgBcpPerHour
  };
}

/**
 * computeCurrentVelocity(cycleTimes, windowStories=3)
 * Rolling average of last N stories
 * Returns { avgBcpPerHour, avgCycleMin } or null if no data
 */
function computeCurrentVelocity(cycleTimes, windowStories = 3) {
  if (!cycleTimes || cycleTimes.length === 0) {
    return null;
  }

  const window = Math.min(windowStories, cycleTimes.length);
  const recentStories = cycleTimes.slice(-window);

  const totalBcps = recentStories.reduce((sum, s) => sum + (s.bcps || 0), 0);
  const totalMin = recentStories.reduce((sum, s) => sum + (s.cycleMin || 0), 0);
  const avgCycleMin = recentStories.length > 0 ? totalMin / recentStories.length : 0;
  const avgBcpPerHour = totalMin > 0 ? (totalBcps * 60) / totalMin : 0;

  return {
    avgBcpPerHour,
    avgCycleMin
  };
}

module.exports = {
  computeEpicMetrics,
  computeProjectMetrics,
  computeCurrentVelocity
};
