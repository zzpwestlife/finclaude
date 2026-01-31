# 问题分析
当前 FinClaude 项目存在以下问题：
* **过度复杂的文档**：README.md (330行)、WORKFLOW.md (360行)、QUICKSTART.md (124行) 内容重复且冗长
* **双重架构**：同时维护 V1 (bin/fin shell脚本) 和 V2 (slash commands) 两套系统，造成混乱
* **外部依赖过多**：依赖 SuperClaude、Superpowers、code-simplifier、ccstatusline、claude-code-notification 等多个外部项目
* **过度工程化**：质量门禁 (guard.js) 包含测试覆盖率、安全审计、复杂度检查等多项检查，但实际上 Claude Code 已有内置能力
* **通知系统冗余**：依赖外部 claude-code-notification 项目，增加维护复杂度
* **安装脚本复杂**：install.sh 有 200+ 行，处理多个外部系统的安装
* **配置文件冗余**：hooks 配置指向多个不存在或未必需的脚本
# 简化目标
将 FinClaude 简化为一个轻量级、专注的 Claude Code 扩展：
1. **保留核心价值**：Slash Commands (plan/dev/review) + 专用 Agents
2. **移除外部依赖**：去除对 SuperClaude、Superpowers、ccstatusline、外部通知系统的依赖
3. **统一架构**：只保留 V2 (Slash Commands)，移除 V1 (shell 脚本)
4. **精简文档**：合并重复内容，保留一个简洁的 README
5. **简化配置**：移除不必要的 hooks 和质量门禁
# 简化方案
## 1. 精简目录结构
保留：
```warp-runnable-command
finclaude/
├── README.md              # 合并后的唯一文档
├── LICENSE
├── .gitignore
├── agents/                # V2 核心：专用 Agents
│   ├── fin-planner.md
│   ├── fin-developer.md
│   └── fin-reviewer.md
├── commands/fin/          # V2 核心：Slash Commands
│   ├── plan.md
│   ├── dev.md
│   └── review.md
└── install.sh             # 精简的安装脚本
```
删除：
* `bin/fin` - V1 shell 脚本，已被 V2 替代
* `scripts/notify.js` - 外部通知依赖，非核心功能
* `scripts/guard.js` - 质量门禁，过度工程化
* `config/settings.json` - 包含过多外部依赖的配置
* `config/.env.example` - 通知系统配置，已移除
* `docs/` - 设计文档，对用户非必需
* `WORKFLOW.md` - 内容冗长，可合并到 README
* `QUICKSTART.md` - 与 README 重复
* `Makefile` - 简化后不再需要
* `package.json` - 不是 npm 包，无需此文件
## 2. 精简 Agents 和 Commands
保持现有 agents/*.md 和 commands/fin/*.md 的核心逻辑，但需要：
* 移除对 SuperClaude (/sc:*) 的引用
* 移除对 Superpowers 的引用
* 移除对 code-simplifier 的依赖
* 简化为使用 Claude Code 原生能力
修改点：
### agents/fin-planner.md
* 保持核心「金融级规划」理念
* 使用原生 Read/Write/Grep 工具
### agents/fin-developer.md
* 保持 TDD 理念，但不强依赖 Superpowers
* 使用原生测试命令 (根据项目自动检测)
### agents/fin-reviewer.md
* 移除 code-simplifier 依赖
* 使用 Claude 原生代码审查能力
### commands/fin/*.md
* 移除对外部工具的引用
* 保持 argument-hint 和 agent 绑定
## 3. 精简 install.sh
新的安装脚本只需要：
1. 检查 Claude Code 是否安装
2. 复制 agents/*.md 到 ~/.claude/agents/
3. 复制 commands/fin/*.md 到 ~/.claude/commands/fin/
4. 输出成功信息
移除：
* ccstatusline 安装
* SuperClaude 安装
* 通知系统克隆
* settings.json 配置
* .env 配置
* pipx/python 检查
约 50 行即可完成。
## 4. 合并精简文档
创建新的 README.md，包含：
1. **项目简介** (2-3 段)
    * FinClaude 是什么：Claude Code 的金融级开发扩展
    * 核心理念：Plan → Dev (TDD) → Review
2. **快速开始** (5-10 行命令)
    * git clone + ./install.sh
    * 使用示例：/fin:plan、/fin:dev、/fin:review
3. **命令参考** (列表)
    * /fin:plan - 架构规划
    * /fin:dev - TDD 开发
    * /fin:review - 代码审查
4. **工作流示例** (一个完整例子)
    * 从规划到开发到审查的完整流程
5. **卸载** (1-2 行)
    * 删除 ~/.claude/agents/fin-* 和 ~/.claude/commands/fin/
目标：README 控制在 100-150 行以内。
## 5. 清理配置依赖
移除：
* `config/settings.json` - 包含大量外部工具配置
* `config/.env.example` - 通知系统配置
用户可以根据自己的需求自定义 Claude Code 配置，不强制特定配置。
# 实施步骤
## Step 1: 删除冗余文件
删除以下文件和目录：
* bin/
* scripts/
* config/
* docs/
* Makefile
* package.json
* WORKFLOW.md
* QUICKSTART.md
## Step 2: 精简 Agents
编辑 agents/*.md，移除外部工具依赖：
* fin-planner.md：保持核心逻辑，无需修改
* fin-developer.md：移除 Superpowers 引用
* fin-reviewer.md：移除 code-simplifier 引用
## Step 3: 精简 Commands
编辑 commands/fin/*.md，简化工具列表：
* 只保留 Claude Code 原生工具
* 移除 MCP 工具引用 (mcp__context7__*)
## Step 4: 重写 install.sh
创建新的精简版 install.sh：
* 检查 Claude Code
* 复制文件到 ~/.claude/
* 显示使用说明
## Step 5: 重写 README.md
合并 README + QUICKSTART + WORKFLOW 的精华内容：
* 简介 (what/why)
* 安装 (1-2 步)
* 使用 (3 个命令)
* 示例 (1 个完整流程)
* 卸载
## Step 6: 测试验证
* 运行 ./install.sh
* 在 Claude Code 中测试 /fin:plan、/fin:dev、/fin:review
* 确认无外部依赖报错
# 预期效果
简化后的项目：
* **文件数量**：从 25+ 个减少到约 10 个
* **代码行数**：从 1500+ 行减少到约 500 行
* **外部依赖**：从 6 个减少到 0 个
* **安装时间**：从 5-10 分钟减少到 10 秒
* **维护成本**：大幅降低
* **用户理解成本**：从需要理解多个工具到只需理解 3 个 slash commands
核心价值保持不变：
* ✅ 金融级规划理念
* ✅ TDD 开发流程
* ✅ 代码审查规范
* ✅ Claude Code 原生集成
