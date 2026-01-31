# FinClaude - 金融级 Claude Code 统一入口

> 专为金融项目设计的 Claude Code 工具链整合方案，强制 TDD + 质量门禁 + 飞书通知

## 特性概览

- **统一入口**：`fin` 命令简化所有操作
- **强制质量门禁**：测试覆盖率 ≥ 80% + 安全审计
- **飞书通知**：任务完成自动推送（基于 ccdd 微改版）
- **双轨制工作流**：SuperClaude 规划 + Superpowers TDD 执行
- **实时状态监控**：ccstatusline 显示 Token/费用/上下文

## 快速开始（一键配置）

```bash
# 1. 克隆配置仓库
git clone https://github.com/your-org/finclaude.git ~/finclaude
cd ~/finclaude

# 2. 运行一键安装脚本
chmod +x install.sh
./install.sh

# 3. 配置飞书 Webhook
# 编辑 ~/.finclaude/.env，填入你的飞书机器人 Webhook URL
```

## 手动安装步骤

### 1. 安装依赖工具

```bash
# 安装 ccstatusline（终端状态栏）
npm install -g ccstatusline

# 安装 SuperClaude
pipx install superclaude
superclaude install

# 安装 Superpowers（Claude Code 插件）
# 在 Claude Code 中执行：
# /plugin marketplace add obra/superpowers-marketplace
# /plugin install superpowers@superpowers-marketplace

# 安装 code-simplifier
# 在 Claude Code 中执行：
# /plugin install code-simplifier
```

### 2. 安装通知系统

FinClaude 内置了通知系统，支持在以下场景发送通知：
- 任务完成（Session 结束）
- 需要权限审批（Permission Prompt）
- 等待用户输入（Idle Prompt）

配置步骤：

```bash
# 1. 复制环境配置模板
cp .env.example .env

# 2. 编辑 .env 配置飞书 Webhook
# FEISHU_WEBHOOK_URL=https://open.feishu.cn/open-apis/bot/v2/hook/xxxxxx
```

支持的通知渠道：
1. **macOS 本地通知**：直接在桌面右上角弹窗。
2. **飞书群机器人**：配置 Webhook 后，消息会同步推送到飞书群。

### 3. 配置 Claude Code

```bash
# 创建配置目录
mkdir -p ~/.finclaude

# 复制配置文件
cp ~/finclaude/config/settings.json ~/.claude/settings.json
cp ~/finclaude/config/hooks.json ~/.claude/hooks.json

# 设置环境变量
echo 'export FINCLAUDE_HOME="$HOME/finclaude"' >> ~/.zshrc
echo 'export PATH="$FINCLAUDE_HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## 使用指南

### 基础命令

```bash
# 规划阶段 - 技术调研 + 架构设计
fin plan "支付网关重构方案"

# 开发阶段 - TDD 强制开发
fin dev "实现转账功能"

# 代码审查 - 简化 + 审查
fin review

# 手动触发通知
fin notify "自定义消息"
```

### 工作流示例

```bash
# 1. 启动项目（SuperClaude 规划）
fin plan "电商支付系统技术方案"
# 输出：PLANNING.md + 架构设计文档

# 2. 开发功能（Superpowers TDD 执行）
fin dev "实现订单支付接口"
# 强制：RED → GREEN → REFACTOR

# 3. 代码审查
fin review
# 自动：code-simplifier 清理 + SuperClaude 审查

# 4. 提交（质量门禁自动检查）
git add .
git commit -m "feat: 实现订单支付接口"
# Pre-commit hook 自动检查覆盖率 ≥ 80%

# 5. 任务完成通知（自动触发）
# 飞书收到："Claude 任务完成 - 订单支付接口开发"
```

## 配置文件说明

### ~/.finclaude/.env

```env
# 飞书机器人配置（必选）
FEISHU_WEBHOOK_URL=https://open.feishu.cn/open-apis/bot/v2/hook/xxxxxx

# Telegram 配置（可选）
TELEGRAM_BOT_TOKEN=your_token
TELEGRAM_CHAT_ID=your_chat_id

# 静默时段（可选）
SILENT_HOURS_START=22:00
SILENT_HOURS_END=09:00

# 通知模板（可选）
NOTIFY_TEMPLATE=financial
```

### ~/.claude/settings.json

```json
{
  "statusLine": {
    "type": "command",
    "command": "ccstatusline --theme powerline --warn-cost 0.5",
    "refreshInterval": 5000
  },
  "permissions": {
    "allow": [
      {"command": "npm test", "when": "always"},
      {"command": "git commit", "when": "after_confirmation"}
    ],
    "deny": [
      {"command": "git push", "when": "coverage < 80"}
    ]
  },
  "hooks": {
    "PreStop": [
      {
        "type": "command",
        "command": "node ~/finclaude/scripts/guard.js"
      }
    ],
    "Stop": [
      {
        "type": "command",
        "command": "node ~/claude-code-notification/notify-system.js"
      }
    ]
  }
}
```

## 质量门禁规则

### 提交前自动检查

1. **测试覆盖率** ≥ 80%
2. **安全审计** - 无高危漏洞
3. **代码简化** - code-simplifier 自动清理
4. **复杂度检查** - Cyclomatic Complexity ≤ 10

### 失败处理

```
❌ 测试未通过或覆盖率不足 80%，禁止提交
❌ 发现高危安全漏洞，请修复后提交
✅ 金融级质量门禁通过
```

## 通知模板

### 任务完成通知

```
🎉 Claude 任务完成

📁 项目：payment-gateway
⏱️ 耗时：45分钟
💰 费用：$0.85
📊 测试：15/15 通过（覆盖率 87%）
✅ 质量门禁：通过
```

### 失败通知

```
⚠️ Claude 任务异常

📁 项目：payment-gateway
❌ 错误：测试覆盖率 72%（要求 ≥ 80%）
🔧 建议：补充边界 case 测试
```

## 故障排查

### 通知不触发

```bash
# 检查 Webhook 配置
cat ~/.finclaude/.env | grep FEISHU

# 手动测试通知
node ~/claude-code-notification/notify-system.js --message "测试消息"
```

### 质量门禁失败

```bash
# 查看详细报告
npm test -- --coverage --verbose

# 跳过门禁（不推荐）
git commit --no-verify -m "your message"
```

### ccstatusline 不显示

```bash
# 检查安装
which ccstatusline

# 手动运行测试
ccstatusline --theme powerline
```

## 更新日志

### v1.0.0
- 初始版本
- 集成 SuperClaude + Superpowers + ccdd
- 金融级质量门禁
- 飞书通知支持

## License

MIT
