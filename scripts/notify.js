#!/usr/bin/env node
const { execSync } = require('child_process');
const path = require('path');
const os = require('os');

// Parse args: --title "Title" --message "Message"
const args = process.argv.slice(2);
let title = 'Claude Code';
let message = 'Notification';

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--title' && args[i+1]) {
    title = args[i+1];
    i++;
  } else if (args[i] === '--message' && args[i+1]) {
    message = args[i+1];
    i++;
  }
}

const notifySystemPath = path.join(os.homedir(), 'claude-code-notification', 'notify-system.js');

try {
  console.log(`Sending notification: ${title} - ${message}`);
  // Call notify-system.js with message
  // Combine title and message for the system notification
  execSync(`node "${notifySystemPath}" --message "${title}: ${message}"`, { stdio: 'inherit' });
} catch (e) {
  console.error('Failed to send notification:', e.message);
}
