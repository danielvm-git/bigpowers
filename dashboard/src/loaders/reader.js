const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

/**
 * readStateYaml(projectRoot)
 * Reads specs/state.yaml and returns an object with mapped fields
 * Returns null if file doesn't exist
 */
function readStateYaml(projectRoot) {
  try {
    const filePath = path.join(projectRoot, 'specs', 'state.yaml');
    if (!fs.existsSync(filePath)) {
      return null;
    }
    const content = fs.readFileSync(filePath, 'utf8');
    const data = yaml.load(content);
    return {
      activeFlow: data.active_flow || null,
      activeEpic: data.active_epic_id || null,
      activeStory: data.active_story_id || null,
      epicCycle: data.epic_cycle || {},
      gitBranch: data.git?.branch || null,
      metrics: data.metrics || null,
      release: data.release || {},
      handoff: data.handoff || {}
    };
  } catch (err) {
    return null;
  }
}

/**
 * readExecutionStatus(projectRoot)
 * Reads specs/execution-status.yaml and returns { epics: Map }
 * Map keys are story/epic IDs, values are status strings
 * Returns null if file doesn't exist
 */
function readExecutionStatus(projectRoot) {
  try {
    const filePath = path.join(projectRoot, 'specs', 'execution-status.yaml');
    if (!fs.existsSync(filePath)) {
      return null;
    }
    const content = fs.readFileSync(filePath, 'utf8');
    const data = yaml.load(content);
    const statusMap = new Map();
    const devStatus = data.development_status || {};
    for (const [key, value] of Object.entries(devStatus)) {
      statusMap.set(key, value);
    }
    return { epics: statusMap };
  } catch (err) {
    return null;
  }
}

/**
 * readEpicShards(projectRoot)
 * Reads all files in specs/epics/*.yaml
 * Returns array of { id, title, stories } objects or null
 */
function readEpicShards(projectRoot) {
  try {
    const epicsDir = path.join(projectRoot, 'specs', 'epics');
    if (!fs.existsSync(epicsDir)) {
      return null;
    }
    const epics = [];

    function scanDir(dirPath) {
      if (!fs.existsSync(dirPath)) return;
      const entries = fs.readdirSync(dirPath);
      for (const entry of entries) {
        const entryPath = path.join(dirPath, entry);
        const stat = fs.statSync(entryPath);
        if (stat.isDirectory()) {
          if (entry === 'archive') {
            scanDir(entryPath);
          } else {
            const possibleYaml = path.join(entryPath, 'epic.yaml');
            if (fs.existsSync(possibleYaml)) {
              loadYaml(possibleYaml);
            }
          }
        } else if (stat.isFile() && entry.endsWith('.yaml')) {
          loadYaml(entryPath);
        }
      }
    }

    function loadYaml(yamlPath) {
      const content = fs.readFileSync(yamlPath, 'utf8');
      const data = yaml.load(content);
      epics.push({
        id: data.id || data.epic || null,
        title: data.title || data.name || null,
        stories: data.stories || []
      });
    }

    scanDir(epicsDir);

    // Sort epics by ID numerically/alphabetically
    epics.sort((a, b) => {
      const idA = a.id || '';
      const idB = b.id || '';
      return idA.localeCompare(idB, undefined, { numeric: true, sensitivity: 'base' });
    });

    return epics.length > 0 ? epics : null;
  } catch (err) {
    return null;
  }
}

/**
 * readCycleTimes(projectRoot)
 * Reads specs/metrics/cycle-times.yaml stories array
 * Returns array of { id, bcps, start, end, cycleMin, bcpPerHour } or null
 */
function readCycleTimes(projectRoot) {
  try {
    const filePath = path.join(projectRoot, 'specs', 'metrics', 'cycle-times.yaml');
    if (!fs.existsSync(filePath)) {
      return null;
    }
    const content = fs.readFileSync(filePath, 'utf8');
    const data = yaml.load(content);
    const stories = data.stories || [];
    return stories.map(s => ({
      id: s.id || null,
      epic: s.epic || null,
      bcps: s.bcps || 0,
      start: s.start || null,
      end: s.end || null,
      cycleMin: s.cycle_minutes || 0,
      bcpPerHour: s.bcp_per_hour || 0
    }));
  } catch (err) {
    return null;
  }
}

module.exports = {
  readStateYaml,
  readExecutionStatus,
  readEpicShards,
  readCycleTimes
};
