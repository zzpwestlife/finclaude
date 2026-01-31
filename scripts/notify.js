#!/usr/bin/env node
/**
 * 系统通知脚本
 * 用于 Claude Code 的钩子通知
 * 
 * Usage: node notify.js --title "Title" --message "Message"
 */

const { exec } = require('child_process');

// 解析命令行参数
const args = process.argv.slice(2);
let title = 'Claude Code';
let message = 'Notification';

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--title' && args[i + 1]) {
    title = args[i + 1];
    i++;
  } else if (args[i] === '--message' && args[i + 1]) {
    message = args[i + 1];
    i++;
  }
}

// 转义双引号
const safeTitle = title.replace(/"/g, '\\"');
const safeMessage = message.replace(/"/g, '\\"');

// 发送通知 (macOS)
const command = `osascript -e 'display notification "${safeMessage}" with title "${safeTitle}"'`;

exec(command, (error) => {
  if (error) {
    console.error('发送通知失败:', error);
    process.exit(1);
  }
  console.log(`通知已发送: [${title}] ${message}`);
});
