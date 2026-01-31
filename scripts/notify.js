#!/usr/bin/env node
/**
 * 系统通知脚本
 * 用于 Claude Code 的钩子通知
 * 支持 macOS 本地通知和飞书 Webhook 通知
 * 
 * Usage: node notify.js --title "Title" --message "Message"
 * Env: 在项目根目录 .env 文件中配置 FEISHU_WEBHOOK=https://open.feishu.cn/...
 */

const { exec } = require('child_process');
const https = require('https');
const fs = require('fs');
const path = require('path');
const url = require('url');

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

// 1. 发送 macOS 本地通知
function sendLocalNotification() {
  const safeTitle = title.replace(/"/g, '\\"');
  const safeMessage = message.replace(/"/g, '\\"');
  const command = `osascript -e 'display notification "${safeMessage}" with title "${safeTitle}"'`;

  exec(command, (error) => {
    if (error) {
      console.error('Local notification failed:', error.message);
    } else {
      console.log(`Local notification sent: [${title}] ${message}`);
    }
  });
}

// 简单加载 .env 文件
function loadEnv() {
  try {
    const envPath = path.join(__dirname, '../.env');
    if (fs.existsSync(envPath)) {
      const content = fs.readFileSync(envPath, 'utf-8');
      content.split('\n').forEach(line => {
        const match = line.match(/^\s*([\w_]+)\s*=\s*(.*)?\s*$/);
        if (match) {
          const key = match[1];
          let value = match[2] || '';
          // 去除引号
          if (value.length > 0 && value.charAt(0) === '"' && value.charAt(value.length - 1) === '"') {
            value = value.substring(1, value.length - 1);
          }
          if (!process.env[key]) {
            process.env[key] = value;
          }
        }
      });
    }
  } catch (e) {
    // 忽略错误
  }
}

// 2. 发送飞书通知
function sendFeishuNotification() {
  loadEnv();
  const webhookUrl = process.env.FEISHU_WEBHOOK || process.env.FEISHU_WEBHOOK_URL;
  
  if (!webhookUrl || webhookUrl.includes('xxxxxx') || webhookUrl.includes('YOUR_WEBHOOK_HERE')) {
    console.log('Skipping Feishu notification: FEISHU_WEBHOOK(_URL) not set or invalid in .env');
    return;
  }

  const payload = JSON.stringify({
    msg_type: "text",
    content: {
      text: `【${title}】\n${message}\nTime: ${new Date().toLocaleString()}`
    }
  });

  const parsedUrl = url.parse(webhookUrl);
  const options = {
    hostname: parsedUrl.hostname,
    path: parsedUrl.path,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(payload)
    }
  };

  const req = https.request(options, (res) => {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      console.log('Feishu notification sent successfully.');
    } else {
      console.error(`Feishu notification failed with status: ${res.statusCode}`);
    }
  });

  req.on('error', (e) => {
    console.error(`Feishu notification error: ${e.message}`);
  });

  req.write(payload);
  req.end();
}

// 执行
sendLocalNotification();
sendFeishuNotification();
