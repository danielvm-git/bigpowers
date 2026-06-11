const fs = require('fs');
const path = require('path');
const chalk = require('chalk');

function renderFilesystem(box, projectRoot) {
  if (!box || typeof box.setContent !== 'function') {
    return;
  }

  const specsPath = path.join(projectRoot, 'specs');

  if (!fs.existsSync(specsPath)) {
    box.setContent(chalk.dim('{center}specs/ not found{/center}'));
    return;
  }

  const now = Date.now();
  const lines = [];
  lines.push('{bold}{cyan}Filesystem{/cyan}{/bold}');

  let fileCount = 0;

  try {
    const entries = fs.readdirSync(specsPath, { withFileTypes: true });

    // Count files for badge
    function countFiles(dir, depth = 0) {
      if (depth > 1) return 0;
      let count = 0;
      try {
        const dirEntries = fs.readdirSync(dir, { withFileTypes: true });
        dirEntries.forEach((entry) => {
          if (entry.isFile()) count++;
          else if (entry.isDirectory() && depth < 1) {
            count += countFiles(path.join(dir, entry.name), depth + 1);
          }
        });
      } catch (e) {
        // ignore
      }
      return count;
    }

    fileCount = countFiles(specsPath);
    lines.push(`{dim}[${fileCount} files]{/dim}`);
    lines.push('');

    // Build tree
    function buildTree(dir, prefix = '', depth = 0) {
      if (depth > 1) return;
      try {
        const entries = fs.readdirSync(dir, { withFileTypes: true });
        entries.forEach((entry, index) => {
          const isLast = index === entries.length - 1;
          const connector = isLast ? '└─ ' : '├─ ';
          const fullPath = path.join(dir, entry.name);

          let displayName = entry.name;

          if (entry.isDirectory()) {
            displayName = chalk.blue(displayName);
            lines.push(prefix + connector + displayName);

            if (depth < 1) {
              const childPrefix =
                prefix + (isLast ? '   ' : '│  ');
              buildTree(fullPath, childPrefix, depth + 1);
            }
          } else if (entry.isFile()) {
            // Check if modified in last 60 seconds
            const stat = fs.statSync(fullPath);
            const mtime = stat.mtimeMs;
            const age = now - mtime;

            if (age < 60000) {
              displayName = chalk.yellow(displayName + ' ★');
            }

            lines.push(prefix + connector + displayName);
          }
        });
      } catch (e) {
        // ignore
      }
    }

    buildTree(specsPath);
  } catch (err) {
    lines.push(chalk.dim('Error reading specs/'));
  }

  box.setContent(lines.join('\n'));
}

module.exports = { renderFilesystem };
