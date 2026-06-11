#!/usr/bin/env node

const path = require('path');

// Parse command-line arguments
const args = process.argv.slice(2);
let showHelp = false;
let useWeb = false;
let port = 7742;
let projectRoot = process.cwd();

for (let i = 0; i < args.length; i++) {
  const arg = args[i];
  if (arg === '--help' || arg === '-h') {
    showHelp = true;
  } else if (arg === '--web') {
    useWeb = true;
  } else if (arg === '--port') {
    if (i + 1 < args.length) {
      const portNum = parseInt(args[i + 1], 10);
      if (!isNaN(portNum) && portNum > 0 && portNum < 65536) {
        port = portNum;
        i++;
      } else {
        console.error('Error: --port requires a valid port number (1-65535)');
        process.exit(1);
      }
    } else {
      console.error('Error: --port requires a port number');
      process.exit(1);
    }
  } else if (arg === '--project') {
    if (i + 1 < args.length) {
      projectRoot = args[i + 1];
      i++;
    } else {
      console.error('Error: --project requires a path');
      process.exit(1);
    }
  } else {
    console.error(`Error: unknown flag "${arg}"`);
    process.exit(1);
  }
}

if (showHelp) {
  console.log(`
Dashboard - Visualize and manage your project

Usage: dashboard [OPTIONS]

Options:
  --help, -h           Show this help message and exit
  --web                Start the web server (default: TUI mode)
  --port PORT          Set the server port (default: 7742)
  --project PATH       Set the project root path (default: current directory)

Examples:
  dashboard                              # Start in TUI mode
  dashboard --web                        # Start web server on port 7742
  dashboard --web --port 3000            # Start web server on port 3000
  dashboard --web --project /path/to/project
  dashboard --help                       # Show this message
`);
  process.exit(0);
}

// Resolve the project root to an absolute path
const resolvedProjectRoot = path.resolve(projectRoot);

if (useWeb) {
  // Start the web server
  try {
    const { createServer } = require('../src/web/server');
    const server = createServer(resolvedProjectRoot, port);
    server.listen(port, () => {
      console.log(`Dashboard: http://localhost:${port}`);
      console.log('Press Ctrl-C to stop.');
    });
  } catch (error) {
    console.error('Error starting web server:', error.message);
    process.exit(1);
  }
} else {
  // Start the TUI
  try {
    const { start } = require('../src/tui/index');
    start(resolvedProjectRoot);
  } catch (error) {
    console.error('Error starting TUI:', error.message);
    process.exit(1);
  }
}
