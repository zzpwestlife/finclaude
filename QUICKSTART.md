# FinClaude 快速开始指南

## 一键安装

```bash
# 1. 克隆仓库
git clone https://github.com/zzpwestlife/finclaude.git ~/finclaude
cd ~/finclaude

# 2. 运行安装脚本
chmod +x install.sh
./install.sh

# 3. 配置飞书 Webhook
# 编辑 ~/.finclaude/.env，填入你的飞书机器人 Webhook URL
```

## 配置飞书机器人

1. 打开飞书群聊 → 点击右上角 **设置**
2. 选择 **群机器人** → **添加机器人**
3. 选择 **自定义机器人**，复制 Webhook 地址
4. 编辑 `~/.finclaude/.env`：

```env
FEISHU_WEBHOOK_URL=https://open.feishu.cn/open-apis/bot/v2/hook/xxxxxx
```

## 常用命令

```bash
# 诊断环境
fin doctor

# 规划阶段
fin plan "支付网关重构方案"

# 开发阶段（TDD 强制）
fin dev "实现转账功能"

# 代码审查
fin review

# 手动发送通知
fin notify "任务完成"

# 查看状态
fin status
```

## 完整工作流示例

```bash
# 1. 启动项目（SuperClaude 规划）
fin plan "电商支付系统技术方案"
# 输出：PLANNING.md + 架构设计

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

## 质量门禁规则

提交前自动检查：
- ✅ 测试覆盖率 ≥ 80%
- ✅ 安全审计 - 无高危漏洞
- ✅ 代码简化
- ✅ 复杂度检查（≤ 10）

## 故障排查

### 通知不触发

```bash
# 检查 Webhook 配置
cat ~/.finclaude/.env | grep FEISHU

# 手动测试通知
fin notify "测试消息"
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

## 更新

使用 `fin update` 命令一键更新所有组件（包括 FinClaude 自身、ccstatusline、SuperClaude 和通知系统）：

```bash
fin update
```

注意：MCP 插件（superpowers, code-simplifier）需要按照 `fin update` 的提示在 Claude Code 中手动更新。
