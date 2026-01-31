#!/bin/bash

# FinClaude 一键安装脚本
# 适用于 macOS / Linux

set -e

# 开始时间
START_SECONDS=$(date +%s)

# 保存脚本所在目录 (源码目录)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
get_time() {
    date "+%H:%M:%S"
}

print_info() {
    echo -e "${BLUE}[INFO] [$(get_time)]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS] [$(get_time)]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING] [$(get_time)]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR] [$(get_time)]${NC} $1"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 安全的 Git 操作函数
git_safe_pull() {
    if ! git pull; then
        print_warning "Git pull 失败，尝试切换到 HTTP/1.1 协议重试..."
        git config http.version HTTP/1.1
        if ! git pull; then
            print_warning "Git 更新失败，跳过更新，使用现有版本"
            return 1
        fi
    fi
    return 0
}

git_safe_clone() {
    local url="$1"
    local dir="$2"
    if ! git clone "$url" "$dir"; then
        print_warning "Git clone 失败，尝试切换到 HTTP/1.1 协议重试..."
        if ! git clone -c http.version=HTTP/1.1 "$url" "$dir"; then
            print_error "Git 克隆失败，请检查网络连接"
            return 1
        fi
    fi
    return 0
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
mkdir -p "$FINCLAUDE_HOME"/{bin,config,scripts,agents,commands/fin}
mkdir -p ~/.claude/{agents,commands/fin}
mkdir -p ~/.finclaude
print_success "目录结构创建完成"

# 步骤 2: 安装 ccstatusline
print_info "步骤 2/8: 安装 ccstatusline..."
if command_exists ccstatusline; then
    print_warning "ccstatusline 已安装，跳过"
else
    npm install -g ccstatusline --registry=https://registry.npmjs.org/
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
    print_info "正在更新代码..."
    git_safe_pull
    print_info "正在安装/更新依赖..."
    npm install
    print_success "通知系统更新完成"
else
    git_safe_clone https://github.com/zzpwestlife/claude-code-notification.git "$NOTIFICATION_HOME"
    cd "$NOTIFICATION_HOME"
    npm install
    print_success "通知系统安装完成"
fi

# 步骤 5: 复制配置文件
print_info "步骤 5/8: 配置 Claude Code..."

# 部署 Slash Commands 和 Agents
print_info "部署 FinClaude V2 核心组件..."

# 部署 Agents
if [ -d "$SCRIPT_DIR/agents" ]; then
    print_info "正在部署 Agents..."
    cp -r "$SCRIPT_DIR/agents/"* ~/.claude/agents/ 2>/dev/null || print_warning "无法写入 ~/.claude/agents (可能是权限问题)"
    
    # 备份到 FINCLAUDE_HOME
    if [ "$SCRIPT_DIR" != "$FINCLAUDE_HOME" ]; then
        cp -r "$SCRIPT_DIR/agents/"* "$FINCLAUDE_HOME/agents/" 2>/dev/null || true
    fi
    print_success "Agents 部署尝试完成"
fi

# 部署 Commands
if [ -d "$SCRIPT_DIR/commands/fin" ]; then
    print_info "正在部署 Slash Commands..."
    cp -r "$SCRIPT_DIR/commands/fin/"* ~/.claude/commands/fin/ 2>/dev/null || print_warning "无法写入 ~/.claude/commands (可能是权限问题)"
    
    # 备份到 FINCLAUDE_HOME
    if [ "$SCRIPT_DIR" != "$FINCLAUDE_HOME" ]; then
        cp -r "$SCRIPT_DIR/commands/fin/"* "$FINCLAUDE_HOME/commands/fin/" 2>/dev/null || true
    fi
    print_success "Slash Commands 部署尝试完成"
fi

# 配置 settings.json (合并模式)
TEMP_SETTINGS="/tmp/finclaude_settings_new.json"
cat > "$TEMP_SETTINGS" << 'EOF'
{
  "statusLine": {
    "type": "command",
    "command": "ccstatusline --theme powerline --warn-cost 0.5",
    "refreshInterval": 5000
  },
  "autoApprove": {
    "readFiles": true,
    "editFiles": false,
    "executeCommands": ["npm test", "git status", "git diff"]
  },
  "hooks": {
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "node ~/finclaude/scripts/guard.js"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "node ~/claude-code-notification/notify-system.js"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "permission_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "node ~/finclaude/scripts/notify.js --title 'Claude Code' --message '需要权限审批'"
          }
        ]
      },
      {
        "matcher": "idle_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "node ~/finclaude/scripts/notify.js --title 'Claude Code' --message '等待你的输入'"
          }
        ]
      }
    ]
  },
  "preferredModel": "claude-sonnet-4-5-20251022"
}
EOF

if [ -f ~/.claude/settings.json ]; then
    print_info "检测到现有配置文件，正在合并..."
    node -e "
    const fs = require('fs');
    const target = process.env.HOME + '/.claude/settings.json';
    const source = '$TEMP_SETTINGS';
    try {
        const current = JSON.parse(fs.readFileSync(target, 'utf8'));
        const newConfig = JSON.parse(fs.readFileSync(source, 'utf8'));
        const merged = { ...current, ...newConfig };
        fs.writeFileSync(target, JSON.stringify(merged, null, 2));
        console.log('配置合并完成');
    } catch (e) {
        console.error('合并失败:', e);
        process.exit(1);
    }
    "
    rm "$TEMP_SETTINGS"
else
    print_info "创建新的配置文件..."
    mkdir -p ~/.claude
    mv "$TEMP_SETTINGS" ~/.claude/settings.json
fi

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
    
    echo "🎯 FinClaude 规划阶段 (V2)"
    echo "ℹ️  建议直接在 Claude Code 中使用: /fin:plan '$description'"
    echo ""
    
    if [ -z "$description" ]; then
        echo "请输入规划描述:"
        read -r description
    fi

    # 尝试调用新版 Slash Command
    claude -p "/fin:plan '$description'"
}

cmd_dev() {
    local description="$1"
    
    echo "💻 FinClaude 开发阶段 (V2)"
    echo "ℹ️  建议直接在 Claude Code 中使用: /fin:dev '$description'"
    echo ""

    if [ -z "$description" ]; then
        echo "请输入开发任务描述:"
        read -r description
    fi
    
    claude -p "/fin:dev '$description'"
}

cmd_review() {
    echo "🔍 FinClaude 代码审查 (V2)"
    echo "ℹ️  建议直接在 Claude Code 中使用: /fin:review"
    echo ""
    
    claude -p "/fin:review"
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
        # 优先检查全局配置 ~/.finclaude/.env
        if [ -f ~/.finclaude/.env ]; then
            if grep -q "FEISHU_WEBHOOK_URL" ~/.finclaude/.env 2>/dev/null; then
                 # 检查是否是默认值
                 if grep -q "hook/xxxxxx" ~/.finclaude/.env; then
                     echo "   ⚠️  飞书配置: 请修改默认 Webhook URL"
                     echo "      文件位置: ~/.finclaude/.env"
                     ((issues++))
                 else
                     echo "   ✅ 飞书配置: 已配置 (~/.finclaude/.env)"
                 fi
            else
                echo "   ⚠️  飞书配置: 未找到 FEISHU_WEBHOOK_URL"
                echo "      文件位置: ~/.finclaude/.env"
                ((issues++))
            fi
        elif [ -f ~/claude-code-notification/.env ]; then
            echo "   ✅ 飞书配置: 已配置 (本地兼容模式)"
        else
            echo "   ⚠️  飞书配置: 未找到配置文件"
            echo "      请创建或编辑: ~/.finclaude/.env"
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
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
else
    SHELL_RC="$HOME/.bash_profile"
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

# 计算耗时
END_SECONDS=$(date +%s)
DURATION=$((END_SECONDS - START_SECONDS))
DURATION_MIN=$((DURATION / 60))
DURATION_SEC=$((DURATION % 60))

echo ""
print_success "========================================"
print_success "  FinClaude 安装完成"
print_success "========================================"
echo ""
print_info "总耗时: ${DURATION_MIN}分 ${DURATION_SEC}秒"
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

# 创建 notify.js
cat > ~/finclaude/scripts/notify.js << 'JS_EOF'
#!/usr/bin/env node
const { execSync } = require('child_process');
const path = require('path');
const os = require('os');

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
  execSync(`node "${notifySystemPath}" --message "${title}: ${message}"`, { stdio: 'inherit' });
} catch (e) {
  // ignore
}
JS_EOF

# 设置权限
chmod +x ~/finclaude/scripts/*.js
