#!/bin/bash

# FinClaude 一键安装脚本
# 适用于 macOS / Linux

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查 Node.js
print_info "检查 Node.js 环境..."
if command_exists node; then
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -ge 18 ]; then
        print_success "Node.js $(node --version) 已安装"
    else
        print_error "Node.js 版本需要 >= 18，当前版本: $(node --version)"
        print_info "请访问 https://nodejs.org/ 下载最新版本"
        exit 1
    fi
else
    print_error "Node.js 未安装"
    print_info "请访问 https://nodejs.org/ 下载并安装"
    exit 1
fi

# 检查 Python (用于 pipx)
print_info "检查 Python 环境..."
if command_exists python3; then
    print_success "Python3 已安装"
else
    print_warning "Python3 未安装，跳过 pipx 安装（可手动安装 SuperClaude）"
fi

# 检查 Claude Code
print_info "检查 Claude Code..."
if command_exists claude; then
    print_success "Claude Code 已安装"
else
    print_error "Claude Code 未安装"
    print_info "请运行: npm install -g @anthropic-ai/claude-code"
    exit 1
fi

# 设置安装路径
FINCLAUDE_HOME="${HOME}/finclaude"
NOTIFICATION_HOME="${HOME}/claude-code-notification"

echo ""
print_info "========================================"
print_info "  FinClaude 安装向导"
print_info "========================================"
echo ""

# 确认安装路径
read -p "安装路径 [$FINCLAUDE_HOME]: " input_path
FINCLAUDE_HOME="${input_path:-$FINCLAUDE_HOME}"

read -p "通知系统路径 [$NOTIFICATION_HOME]: " input_notify
NOTIFICATION_HOME="${input_notify:-$NOTIFICATION_HOME}"

echo ""
print_info "安装路径: $FINCLAUDE_HOME"
print_info "通知系统: $NOTIFICATION_HOME"
echo ""

# 步骤 1: 创建目录结构
print_info "步骤 1/8: 创建目录结构..."
mkdir -p "$FINCLAUDE_HOME"/{bin,config,scripts}
mkdir -p ~/.claude
mkdir -p ~/.finclaude
print_success "目录结构创建完成"

# 步骤 2: 安装 ccstatusline
print_info "步骤 2/8: 安装 ccstatusline..."
if command_exists ccstatusline; then
    print_warning "ccstatusline 已安装，跳过"
else
    npm install -g ccstatusline
    print_success "ccstatusline 安装完成"
fi

# 步骤 3: 安装 SuperClaude
print_info "步骤 3/8: 安装 SuperClaude..."
if command_exists superclaude; then
    print_warning "SuperClaude 已安装，跳过"
else
    if command_exists pipx; then
        pipx install superclaude
        superclaude install
        print_success "SuperClaude 安装完成"
    else
        print_warning "pipx 未安装，跳过 SuperClaude 安装"
        print_info "可稍后手动安装: pipx install superclaude"
    fi
fi

# 步骤 4: 克隆通知系统
print_info "步骤 4/8: 安装通知系统..."
if [ -d "$NOTIFICATION_HOME" ]; then
    print_warning "通知系统目录已存在，跳过克隆"
    cd "$NOTIFICATION_HOME"
    git pull 2>/dev/null || print_warning "更新失败，使用现有版本"
else
    git clone https://github.com/zzpwestlife/claude-code-notification.git "$NOTIFICATION_HOME"
    cd "$NOTIFICATION_HOME"
    npm install
    print_success "通知系统安装完成"
fi

# 步骤 5: 复制配置文件
print_info "步骤 5/8: 配置 Claude Code..."

# 创建 settings.json
cat > ~/.claude/settings.json << 'EOF'
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
EOF

# 创建 guard.js
mkdir -p ~/finclaude/scripts
cat > ~/finclaude/scripts/guard.js << 'EOF'
#!/usr/bin/env node
/**
 * FinClaude 金融级质量门禁
 * 提交前强制检查
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const RED = '\x1b[31m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const NC = '\x1b[0m';

function logInfo(msg) {
  console.log(`${YELLOW}[FINCLAUDE]${NC} ${msg}`);
}

function logSuccess(msg) {
  console.log(`${GREEN}[PASS]${NC} ${msg}`);
}

function logError(msg) {
  console.log(`${RED}[FAIL]${NC} ${msg}`);
}

function checkTestCoverage() {
  logInfo('检查测试覆盖率 (要求 ≥ 80%)...');
  try {
    const output = execSync('npm test -- --coverage --coverageReporters=text-summary 2>&1', {
      encoding: 'utf-8',
      stdio: ['pipe', 'pipe', 'pipe']
    });
    
    // 解析覆盖率
    const linesMatch = output.match(/Lines\s*:\s*(\d+\.?\d*)%/);
    const coverage = linesMatch ? parseFloat(linesMatch[1]) : 0;
    
    if (coverage >= 80) {
      logSuccess(`测试覆盖率: ${coverage}%`);
      return true;
    } else {
      logError(`测试覆盖率: ${coverage}% (要求 ≥ 80%)`);
      return false;
    }
  } catch (e) {
    logError('测试执行失败');
    console.log(e.stdout || e.message);
    return false;
  }
}

function checkSecurityAudit() {
  logInfo('检查安全漏洞...');
  try {
    execSync('npm audit --audit-level=high', { stdio: 'inherit' });
    logSuccess('安全审计通过');
    return true;
  } catch (e) {
    logError('发现高危安全漏洞');
    console.log('运行 npm audit fix 修复');
    return false;
  }
}

function runCodeSimplifier() {
  logInfo('运行代码简化...');
  try {
    execSync('npx code-simplifier', { stdio: 'inherit' });
    logSuccess('代码简化完成');
    return true;
  } catch (e) {
    logWarning('代码简化未运行（可能未安装）');
    return true; // 非阻塞
  }
}

function logWarning(msg) {
  console.log(`${YELLOW}[WARN]${NC} ${msg}`);
}

// 主流程
console.log('\n========================================');
console.log('  FinClaude 金融级质量门禁');
console.log('========================================\n');

let passed = true;

try {
  // 检查是否有测试脚本
  const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf-8'));
  if (!packageJson.scripts || !packageJson.scripts.test) {
    logWarning('未找到 test 脚本，跳过测试检查');
  } else {
    passed = checkTestCoverage() && passed;
  }
} catch (e) {
  logWarning('无法读取 package.json，跳过测试检查');
}

passed = checkSecurityAudit() && passed;
runCodeSimplifier();

console.log('\n========================================');
if (passed) {
  console.log(`${GREEN}✅ 金融级质量门禁通过${NC}`);
  console.log('========================================\n');
  process.exit(0);
} else {
  console.log(`${RED}❌ 质量门禁检查失败${NC}`);
  console.log('请修复上述问题后重试');
  console.log('========================================\n');
  process.exit(1);
}
EOF

chmod +x ~/finclaude/scripts/guard.js

# 创建 fin 命令
mkdir -p ~/finclaude/bin
cat > ~/finclaude/bin/fin << 'EOF'
#!/bin/bash
# FinClaude 统一入口命令

FINCLAUDE_VERSION="1.0.0"

show_help() {
    cat << 'HELP'
FinClaude - 金融级 Claude Code 统一入口

用法:
  fin <command> [options]

命令:
  plan <description>    规划阶段：技术调研 + 架构设计
  dev <description>     开发阶段：TDD 强制开发
  review                代码审查：简化 + 审查
  notify <message>      手动触发飞书通知
  status                显示当前状态
  doctor                诊断环境配置
  help                  显示帮助信息

示例:
  fin plan "支付网关重构方案"
  fin dev "实现转账功能"
  fin review
  fin notify "自定义消息"

环境变量:
  FINCLAUDE_HOME        FinClaude 安装路径 (默认: ~/finclaude)
  FEISHU_WEBHOOK_URL    飞书机器人 Webhook URL
HELP
}

cmd_plan() {
    local description="$1"
    if [ -z "$description" ]; then
        echo "错误: 请提供规划描述"
        echo "用法: fin plan <description>"
        exit 1
    fi
    
    echo "🎯 FinClaude 规划阶段"
    echo "描述: $description"
    echo ""
    
    claude -p "/sc:research '$description' && /sc:architect '$description'"
}

cmd_dev() {
    local description="$1"
    if [ -z "$description" ]; then
        echo "错误: 请提供开发描述"
        echo "用法: fin dev <description>"
        exit 1
    fi
    
    echo "💻 FinClaude 开发阶段"
    echo "描述: $description"
    echo "模式: TDD 强制 (RED → GREEN → REFACTOR)"
    echo ""
    
    # 检查 Superpowers 是否安装
    if claude -p "/superpowers:write-plan --help" >/dev/null 2>&1; then
        echo "使用 Superpowers TDD 模式..."
        claude -p "/superpowers:write-plan '$description' && /superpowers:execute-plan"
    else
        echo "使用 SuperClaude 开发模式..."
        claude -p "/sc:implement '$description'"
    fi
}

cmd_review() {
    echo "🔍 FinClaude 代码审查"
    echo ""
    
    # 运行 code-simplifier
    echo "1. 代码简化..."
    npx code-simplifier 2>/dev/null || echo "   code-simplifier 未安装，跳过"
    
    echo ""
    echo "2. SuperClaude 代码审查..."
    claude -p "/sc:review"
}

cmd_notify() {
    local message="$1"
    if [ -z "$message" ]; then
        message="FinClaude 任务完成"
    fi
    
    echo "📱 发送通知: $message"
    node ~/claude-code-notification/notify-system.js --message "$message"
}

cmd_status() {
    echo "📊 FinClaude 状态"
    echo ""
    echo "安装路径: ${FINCLAUDE_HOME:-~/finclaude}"
    echo "通知系统: ~/claude-code-notification"
    echo ""
    echo "组件状态:"
    
    # 检查各组件
    command -v ccstatusline >/dev/null 2>&1 && echo "  ✅ ccstatusline" || echo "  ❌ ccstatusline"
    command -v superclaude >/dev/null 2>&1 && echo "  ✅ SuperClaude" || echo "  ❌ SuperClaude"
    command -v claude >/dev/null 2>&1 && echo "  ✅ Claude Code" || echo "  ❌ Claude Code"
    
    if [ -f ~/claude-code-notification/notify-system.js ]; then
        echo "  ✅ 通知系统"
    else
        echo "  ❌ 通知系统"
    fi
    
    echo ""
    echo "配置文件:"
    [ -f ~/.claude/settings.json ] && echo "  ✅ ~/.claude/settings.json" || echo "  ❌ ~/.claude/settings.json"
    [ -f ~/.finclaude/.env ] && echo "  ✅ ~/.finclaude/.env" || echo "  ❌ ~/.finclaude/.env (请配置飞书 Webhook)"
}

cmd_doctor() {
    echo "🔧 FinClaude 环境诊断"
    echo ""
    
    local issues=0
    
    # 检查 Node.js
    if command -v node >/dev/null 2>&1; then
        echo "✅ Node.js: $(node --version)"
    else
        echo "❌ Node.js: 未安装"
        ((issues++))
    fi
    
    # 检查 Claude Code
    if command -v claude >/dev/null 2>&1; then
        echo "✅ Claude Code: 已安装"
    else
        echo "❌ Claude Code: 未安装"
        echo "   安装命令: npm install -g @anthropic-ai/claude-code"
        ((issues++))
    fi
    
    # 检查 ccstatusline
    if command -v ccstatusline >/dev/null 2>&1; then
        echo "✅ ccstatusline: 已安装"
    else
        echo "❌ ccstatusline: 未安装"
        echo "   安装命令: npm install -g ccstatusline"
        ((issues++))
    fi
    
    # 检查通知系统
    if [ -f ~/claude-code-notification/notify-system.js ]; then
        echo "✅ 通知系统: 已安装"
        
        # 检查 .env
        if [ -f ~/claude-code-notification/.env ]; then
            if grep -q "FEISHU_WEBHOOK_URL" ~/claude-code-notification/.env; then
                echo "✅ 飞书配置: 已配置"
            else
                echo "⚠️  飞书配置: 未配置 Webhook URL"
                ((issues++))
            fi
        else
            echo "⚠️  飞书配置: 未创建 .env 文件"
            ((issues++))
        fi
    else
        echo "❌ 通知系统: 未安装"
        echo "   安装命令: git clone https://github.com/zzpwestlife/claude-code-notification.git ~/claude-code-notification"
        ((issues++))
    fi
    
    # 检查配置文件
    if [ -f ~/.claude/settings.json ]; then
        echo "✅ Claude 配置: 已配置"
    else
        echo "❌ Claude 配置: 未配置"
        ((issues++))
    fi
    
    echo ""
    if [ $issues -eq 0 ]; then
        echo "🎉 环境检查通过！FinClaude 已就绪"
    else
        echo "⚠️  发现 $issues 个问题，请根据提示修复"
    fi
}

# 主入口
case "${1:-}" in
    plan)
        shift
        cmd_plan "$@"
        ;;
    dev)
        shift
        cmd_dev "$@"
        ;;
    review)
        cmd_review
        ;;
    notify)
        shift
        cmd_notify "$@"
        ;;
    status)
        cmd_status
        ;;
    doctor)
        cmd_doctor
        ;;
    help|--help|-h)
        show_help
        ;;
    version|--version|-v)
        echo "FinClaude v$FINCLAUDE_VERSION"
        ;;
    *)
        echo "错误: 未知命令 '${1:-}'"
        echo ""
        show_help
        exit 1
        ;;
esac
EOF

chmod +x ~/finclaude/bin/fin

print_success "配置文件创建完成"

# 步骤 6: 创建环境变量模板
print_info "步骤 6/8: 创建环境变量模板..."

if [ ! -f ~/.finclaude/.env ]; then
cat > ~/.finclaude/.env << 'EOF'
# FinClaude 环境变量配置
# 请根据你的实际情况修改

# ============================================
# 飞书机器人配置（必选）
# ============================================
# 获取方式：
# 1. 在飞书群聊中添加自定义机器人
# 2. 复制 Webhook 地址
# 3. 粘贴到下方
FEISHU_WEBHOOK_URL=https://open.feishu.cn/open-apis/bot/v2/hook/xxxxxx

# ============================================
# Telegram 配置（可选）
# ============================================
# TELEGRAM_BOT_TOKEN=your_bot_token
# TELEGRAM_CHAT_ID=your_chat_id

# ============================================
# 通知设置（可选）
# ============================================
# 静默时段（24小时制）
SILENT_HOURS_START=22:00
SILENT_HOURS_END=09:00

# 通知模板类型
# 可选: default, financial, minimal
NOTIFY_TEMPLATE=financial

# ============================================
# 质量门禁设置（可选）
# ============================================
# 测试覆盖率阈值（%）
COVERAGE_THRESHOLD=80

# 复杂度阈值
COMPLEXITY_THRESHOLD=10
EOF
    print_warning "请编辑 ~/.finclaude/.env 配置飞书 Webhook"
else
    print_warning "环境变量文件已存在，跳过"
fi

# 步骤 7: 添加到 PATH
print_info "步骤 7/8: 配置环境变量..."

SHELL_RC=""
if [ -f ~/.zshrc ]; then
    SHELL_RC="~/.zshrc"
elif [ -f ~/.bashrc ]; then
    SHELL_RC="~/.bashrc"
else
    SHELL_RC="~/.bash_profile"
fi

# 检查是否已添加
if ! grep -q "FINCLAUDE_HOME" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# FinClaude 配置" >> "$SHELL_RC"
    echo 'export FINCLAUDE_HOME="$HOME/finclaude"' >> "$SHELL_RC"
    echo 'export PATH="$FINCLAUDE_HOME/bin:$PATH"' >> "$SHELL_RC"
    print_success "环境变量已添加到 $SHELL_RC"
else
    print_warning "环境变量已存在，跳过"
fi

# 步骤 8: 完成
print_info "步骤 8/8: 安装完成！"
echo ""

# 显示摘要
echo "========================================"
echo "  FinClaude 安装完成"
echo "========================================"
echo ""
echo "📁 安装路径: $FINCLAUDE_HOME"
echo "📱 通知系统: $NOTIFICATION_HOME"
echo ""
echo "✅ 已安装组件:"
echo "   - ccstatusline (终端状态栏)"
command -v superclaude >/dev/null 2>&1 && echo "   - SuperClaude (工作流框架)"
echo "   - 通知系统 (飞书推送)"
echo "   - 质量门禁脚本"
echo ""
echo "⚠️  待完成配置:"

if [ ! -f ~/.finclaude/.env ] || ! grep -q "FEISHU_WEBHOOK_URL" ~/.finclaude/.env 2>/dev/null; then
    echo "   1. 编辑 ~/.finclaude/.env，配置飞书 Webhook URL"
fi

echo ""
echo "🚀 快速开始:"
echo "   1. 运行 'source $SHELL_RC' 或重启终端"
echo "   2. 运行 'fin doctor' 检查环境"
echo "   3. 运行 'fin plan \"你的项目描述\"' 开始规划"
echo ""
echo "📖 查看文档: cat $FINCLAUDE_HOME/README.md"
echo ""

# 提示配置飞书
if [ ! -f ~/.finclaude/.env ] || ! grep -q "FEISHU_WEBHOOK_URL" ~/.finclaude/.env 2>/dev/null; then
    print_warning "飞书 Webhook 未配置！"
    echo ""
    echo "配置步骤:"
    echo "   1. 在飞书群聊中点击 '设置' → '群机器人' → '添加机器人'"
    echo "   2. 选择 '自定义机器人'，复制 Webhook 地址"
    echo "   3. 编辑 ~/.finclaude/.env，粘贴 Webhook URL"
    echo ""
fi

print_success "安装完成！"
