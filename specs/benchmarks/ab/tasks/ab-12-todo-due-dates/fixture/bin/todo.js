#!/usr/bin/env node
import { run, UsageError } from "../src/commands.js";

try {
  for (const line of run(process.argv.slice(2))) console.log(line);
} catch (err) {
  console.error(`todo: ${err.message}`);
  process.exit(err instanceof UsageError ? 2 : 1);
}
