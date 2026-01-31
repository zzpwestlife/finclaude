# FinClaude 工作流指南

## 概述

FinClaude 采用 **"规划 → 开发 → 审查 → 提交"** 的标准化工作流，专为金融级项目设计。

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│  规划   │ → │  开发   │ → │  审查   │ → │  提交   │
│  (Plan) │    │  (Dev)  │    │(Review) │    │(Commit) │
└─────────┘    └─────────┘    └─────────┘    └─────────┘
   SuperClaude   Superpowers    code-simplifier   Guard
   /sc:research  TDD 强制        + /sc:review      + Notify
   /sc:architect
```

## 阶段详解

### 阶段 1: 规划 (Plan)

**命令**: `fin plan "描述"`

**工具**: SuperClaude (`/sc:research` + `/sc:architect`)

**输出**:

- `PLANNING.md` - 项目规划文档
- `RESEARCH.md` - 技术调研结果
- 架构设计文档

**适用场景**:

- 新项目启动
- 重大功能设计
- 技术选型决策
- 遗留系统重构规划

**示例**:

```bash
fin plan "支付网关重构方案"
# 输出包含：
# - 现有架构分析
# - 候选技术方案对比
# - 推荐架构设计
# - 风险评估
# - 实施路线图
```

---

### 阶段 2: 开发 (Dev)

**命令**: `fin dev "描述"`

**工具**: Superpowers (`/superpowers:write-plan` + `/superpowers:execute-plan`)

**流程**:

```
RED: 编写测试 → 确认测试失败
GREEN: 编写最少代码 → 确认测试通过
REFACTOR: 优化代码 → 确认测试仍通过
COMMIT: 原子提交
```

**特点**:

- 强制 TDD（不写测试不让过）
- 自动删除测试前写的代码
- 两阶段审查（规格符合性 + 代码质量）

**示例**:

```bash
fin dev "实现转账功能"
# 自动执行：
# 1. 生成实施计划
# 2. 编写单元测试
# 3. 实现功能代码
# 4. 运行测试（RED → GREEN）
# 5. 重构优化
# 6. 原子提交
```

---

### 阶段 3: 审查 (Review)

**命令**: `fin review`

**工具**: code-simplifier + SuperClaude (`/sc:review`)

**流程**:

1. **代码简化** - code-simplifier 统一风格
2. **逻辑审查** - SuperClaude 检查业务逻辑

**检查项**:

- 命名规范
- 代码结构
- 重复代码
- 业务逻辑正确性
- 边界 case 处理

**示例**:

```bash
fin review
# 输出包含：
# - 代码风格问题
# - 潜在 Bug
# - 优化建议
# - 安全风险提示
```

---

### 阶段 4: 提交 (Commit)

**命令**: `git commit`

**工具**: guard.js (Pre-commit Hook)

**自动检查**:

1. ✅ 测试覆盖率 ≥ 80%
2. ✅ 安全审计 - 无高危漏洞
3. ✅ 代码简化完成
4. ✅ 复杂度 ≤ 10

**失败处理**:

```
❌ 测试覆盖率 72% (要求 ≥ 80%)
   建议：补充边界 case 测试

强制提交：git commit --no-verify
```

**成功后**:

```
✅ 金融级质量门禁通过
📱 飞书通知已发送
```

---

## 完整示例

### 场景：开发转账功能

```bash
# ========== 阶段 1: 规划 ==========
$ fin plan "转账功能技术方案"

🎯 FinClaude 规划阶段
📋 描述: 转账功能技术方案
🔧 工具: SuperClaude

执行中...
────────────────────────────────────────────────────────
[Claude Code] /sc:research "转账功能技术方案"
[Claude Code] /sc:architect "转账功能技术方案"

✅ 输出文件:
   - PLANNING.md
   - RESEARCH.md
   - 架构设计文档

# ========== 阶段 2: 开发 ==========
$ fin dev "实现转账功能"

💻 FinClaude 开发阶段
📋 描述: 实现转账功能
🔧 工具: Superpowers (TDD 强制)

执行中...
────────────────────────────────────────────────────────
[Claude Code] /superpowers:write-plan "实现转账功能"
[Claude Code] /superpowers:execute-plan

✅ TDD 流程:
   1. RED: 编写测试 (3 个测试用例)
   2. GREEN: 实现功能 (转账逻辑)
   3. REFACTOR: 优化代码
   4. COMMIT: 原子提交

✅ 测试通过: 3/3
✅ 覆盖率: 87%

# ========== 阶段 3: 审查 ==========
$ fin review

🔍 FinClaude 代码审查

1️⃣ 代码简化...
────────────────────────────────────────────────────────
✅ 代码简化完成
   - 统一命名风格
   - 删除重复代码
   - 优化嵌套结构

2️⃣ SuperClaude 代码审查...
────────────────────────────────────────────────────────
✅ 审查通过
   - 业务逻辑正确
   - 边界 case 处理完善
   - 无安全风险

# ========== 阶段 4: 提交 ==========
$ git add .
$ git commit -m "feat: 实现转账功能"

════════════════════════════════════════════════════════
  FinClaude 金融级质量门禁
════════════════════════════════════════════════════════

[FINCLAUDE] 检查测试覆盖率 (要求 ≥ 80%)...
  覆盖率详情:
    Statements: 89%
    Branches:   85%
    Functions:  92%
    Lines:      87%

[PASS] 测试覆盖率: 87% (≥ 80%)

[FINCLAUDE] 检查安全漏洞...
[PASS] 安全审计通过

[FINCLAUDE] 运行代码简化...
[PASS] 代码简化完成

════════════════════════════════════════════════════════
  ✅ 金融级质量门禁通过
════════════════════════════════════════════════════════

[master 3a4f5d2] feat: 实现转账功能
 3 files changed, 120 insertions(+)

📱 飞书通知已发送
```

---

## 通知示例

### 任务完成通知

```
🎉 Claude 任务完成

📁 项目: payment-gateway
⏱️ 耗时: 45分钟
💰 费用: $0.85
📊 测试: 15/15 通过（覆盖率 87%）
✅ 质量门禁: 通过

提交: 3a4f5d2 feat: 实现转账功能
```

### 失败通知

```
⚠️ Claude 任务异常

📁 项目: payment-gateway
❌ 错误: 测试覆盖率 72%（要求 ≥ 80%）
🔧 建议: 补充边界 case 测试

查看详情: npm test -- --coverage
```

---

## 最佳实践

### 1. 新项目启动

```bash
# Day 1: 规划
fin plan "项目技术方案"

# Day 2-3: 核心功能开发
fin dev "用户认证模块"
fin dev "支付核心逻辑"

# Day 4: 代码审查
fin review

# Day 5: 提交
# 质量门禁自动检查 → 飞书通知
```

### 2. 日常开发

```bash
# 小功能开发
fin dev "添加手续费计算"

# Bug 修复
fin dev "修复转账金额精度问题"

# 代码审查
fin review

# 提交
git commit -m "fix: 修复转账金额精度问题"
```

### 3. 遗留项目维护

```bash
# 先使用 SuperClaude 理解代码
/sc:research "分析现有支付系统架构"

# 规划重构
fin plan "支付系统重构方案"

# 逐步重构
fin dev "重构支付核心逻辑"

# 审查
fin review
```

---

## 常见问题

### Q: 可以不使用 TDD 吗？

A: 对于金融项目，强烈建议保持 TDD。如果确实需要跳过：

- 使用 `git commit --no-verify` 绕过门禁
- 或在 `~/.finclaude/.env` 中降低覆盖率阈值

### Q: 如何调整覆盖率阈值？

A: 编辑 `~/.finclaude/.env`：

```env
COVERAGE_THRESHOLD=70  # 调整为 70%
```

### Q: 通知不工作怎么办？

A: 检查步骤：

1. `fin doctor` - 检查环境
2. `cat ~/.finclaude/.env` - 确认 Webhook 配置
3. `fin notify "测试"` - 手动测试通知

### Q: 如何禁用某个检查？

A: 修改 `~/.claude/settings.json`，删除对应的 hook。
