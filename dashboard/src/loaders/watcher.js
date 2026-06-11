const EventEmitter = require('events');
const fs = require('fs');
const path = require('path');

let chokidar;
try {
  chokidar = require('chokidar');
} catch (err) {
  chokidar = null;
}

function watch(projectRoot) {
  const emitter = new EventEmitter();
  const debounceTimers = {};

  function notifyChange(file) {
    const key = file;
    if (debounceTimers[key]) {
      clearTimeout(debounceTimers[key]);
    }
    debounceTimers[key] = setTimeout(() => {
      emitter.emit('change', { file, data: null });
      delete debounceTimers[key];
    }, 300);
  }

  if (chokidar) {
    const filesToWatch = [
      path.join(projectRoot, 'specs/state.yaml'),
      path.join(projectRoot, 'specs/execution-status.yaml'),
      path.join(projectRoot, 'specs/metrics/cycle-times.yaml'),
      path.join(projectRoot, 'specs/epics')
    ];

    const watcher = chokidar.watch(filesToWatch, {
      persistent: true,
      awaitWriteFinish: {
        stabilityThreshold: 100,
        pollInterval: 100
      }
    });

    watcher.on('change', (file) => {
      notifyChange(file);
    });

    watcher.on('add', (file) => {
      notifyChange(file);
    });

    emitter.close = () => watcher.close();
  } else {
    const fileStats = {};
    const filesToWatch = [
      path.join(projectRoot, 'specs/state.yaml'),
      path.join(projectRoot, 'specs/execution-status.yaml'),
      path.join(projectRoot, 'specs/metrics/cycle-times.yaml')
    ];

    const pollInterval = setInterval(() => {
      filesToWatch.forEach((file) => {
        try {
          const stat = fs.statSync(file);
          const mtime = stat.mtime.getTime();

          if (!fileStats[file]) {
            fileStats[file] = mtime;
          } else if (fileStats[file] !== mtime) {
            fileStats[file] = mtime;
            notifyChange(file);
          }
        } catch (err) {
          // File doesn't exist yet or was deleted
          if (fileStats[file]) {
            delete fileStats[file];
            notifyChange(file);
          }
        }
      });

      // Check specs/epics directory
      const epicsDir = path.join(projectRoot, 'specs/epics');
      try {
        const entries = fs.readdirSync(epicsDir);
        entries.forEach((entry) => {
          const fullPath = path.join(epicsDir, entry);
          const stat = fs.statSync(fullPath);
          const mtime = stat.mtime.getTime();

          if (!fileStats[fullPath]) {
            fileStats[fullPath] = mtime;
          } else if (fileStats[fullPath] !== mtime) {
            fileStats[fullPath] = mtime;
            notifyChange(fullPath);
          }
        });
      } catch (err) {
        // epics directory doesn't exist yet
      }
    }, 200);

    emitter.close = () => clearInterval(pollInterval);
  }

  return emitter;
}

module.exports = { watch };
