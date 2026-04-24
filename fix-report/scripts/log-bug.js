/**
 * Helper script to format a bug log entry as a CSV row.
 * Usage: node log-bug.js <json_data>
 */

const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
if (args.length === 0) {
  console.error('Usage: node log-bug.js \'<json_data>\'');
  process.exit(1);
}

try {
  const data = JSON.parse(args[0]);
  const columns = [
    'bug_id', 'date', 'severity', 'priority', 'scope', 'error_message',
    'location', 'root_cause', 'trigger', 'files_changed', 'approach',
    'risk_level', 'breaking_change', 'prevention_mechanism', 'prevention_details',
    'new_tests', 'updated_tests', 'total_tests', 'type_check', 'lint',
    'commit_type', 'release_type', 'commit_message', 'github_issue', 'follow_ups'
  ];

  const row = columns.map(col => {
    let val = data[col] || '';
    if (typeof val === 'string') {
      val = val.replace(/\n/g, ' | ').replace(/"/g, '""');
    }
    return `"${val}"`;
  }).join(',');

  console.log(row);
} catch (e) {
  console.error('Failed to parse JSON or format row:', e.message);
  process.exit(1);
}
