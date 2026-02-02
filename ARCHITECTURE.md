# FinClaude V2 Architecture Design: Native Slash Commands & Subagents

## 1. Executive Summary

This document outlines the architectural redesign of FinClaude, moving from a shell-script wrapper (`bin/fin`) to a native Claude Code extension using Custom Slash Commands and Subagents. This shift leverages Claude Code's native capabilities—specifically `@` file referencing, direct context access, and modular agent routing—to provide a seamless, "financial-grade" development experience.

## 2. Problem Statement

The current `bin/fin` implementation is an external shell wrapper that:
1.  **Lacks Context Awareness**: Cannot easily access the current state of the IDE or conversation history without explicit arguments.
2.  **Limited `@` Support**: Users cannot naturally use `@file` or `@folder` references within the `fin` command arguments as they would in standard Claude commands.
3.  **Fragile Integration**: Relies on `claude -p` calls which start new sessions or context-switch heavily, breaking the flow.
4.  **Non-Standard Interface**: Users must switch between `fin` (shell) and standard Claude commands.

## 3. Proposed Solution

We will reimplement FinClaude's core functionality (`plan`, `dev`, `review`) as **Custom Slash Commands** (`/fin:plan`, `/fin:dev`, `/fin:review`) backed by specialized **Subagents** (`fin-planner`, `fin-developer`, `fin-reviewer`).

### 3.1 Core Components

| Feature | Old Implementation (`bin/fin`) | New Implementation (`commands/fin/*`) |
| :--- | :--- | :--- |
| **Plan** | `cmd_plan()` -> `/sc:research` | `/fin:plan` -> `agents/fin-planner` |
| **Dev** | `cmd_dev()` -> `/superpowers` | `/fin:dev` -> `agents/fin-developer` |
| **Review** | `cmd_review()` -> `npx ...` | `/fin:review` -> `agents/fin-reviewer` |
| **Context** | Passed as string args | Native `@` reference support |
| **Runtime** | External Shell | Native Claude Code Session |

## 4. Detailed Architecture

### 4.1 Directory Structure

The new architecture requires installing definitions into the user's `~/.claude` configuration directory.

```text
~/.claude/
├── commands/
│   └── fin/
│       ├── plan.md         # Defines /fin:plan
│       ├── dev.md          # Defines /fin:dev
│       └── review.md       # Defines /fin:review
└── agents/
    ├── fin-planner.md      # Planner Agent Definition
    ├── fin-developer.md    # Developer Agent Definition
    └── fin-reviewer.md     # Reviewer Agent Definition
```

### 4.2 Command Definitions (Slash Commands)

Each command will be defined as a Markdown file with YAML frontmatter, following the SuperClaude/Claude Code pattern.

**Example: `/fin:plan`**
- **Input**: User prompt + `@` references.
- **Action**: Validates environment -> Spawns `fin-planner` agent.
- **Context Handling**: Explicitly includes `<context_instruction>` to ingest `@` references.

### 4.3 Subagent Definitions

Agents are specialized personas with restricted tool sets and specific system prompts.

1.  **`fin-planner`**:
    - **Role**: Financial Architect.
    - **Capabilities**: Research, Architectural Design, Risk Assessment.
    - **Output**: `PLAN.md` with "Financial Grade" constraints (Security, Auditability).

2.  **`fin-developer`**:
    - **Role**: TDD Practitioner.
    - **Capabilities**: Write Tests -> Write Code -> Refactor.
    - **Constraints**: 100% Test Coverage for critical paths.

3.  **`fin-reviewer`**:
    - **Role**: Auditor.
    - **Capabilities**: Code Simplification (via tool), Security Scan, Logic Verification.
    - **Tools**: `code-simplifier` (MCP), `security-scan`.

## 5. Technical Implementation Specs

### 5.1 Slash Command Interface

| Command | Arguments | Description |
| :--- | :--- | :--- |
| `/fin:plan` | `[description] [@context]` | Generates architectural plan and risk analysis. |
| `/fin:dev` | `[task] [@context]` | Implements features using TDD loop. |
| `/fin:review` | `[scope]` | Performs code review and simplification. |

### 5.2 Context Integration (@ References)

Claude Code resolves `@` references (files, folders) client-side before sending the prompt to the agent.
- **Mechanism**: When a user types `/fin:plan "Fix bug" @src/main.py`, the agent receives:
    - System Prompt: Defined in `commands/fin/plan.md`.
    - User Message: "Fix bug" + [Content of src/main.py].
- **Benefit**: The agent has immediate access to the *exact* files the user cares about, without `Read` tool overhead.

### 5.3 Subagent Routing

The command file uses the `agent: fin-xxx` directive or explicit orchestration logic to hand off control.

```markdown
---
name: fin:plan
agent: fin-planner
---
<instruction>
Analyze the user request and attached context (@files).
Produce a compliant PLAN.md.
</instruction>
```

## 6. Migration & Compatibility

### 6.1 Compatibility Wrapper
We will update `bin/fin` to act as a legacy wrapper that delegates to the new slash commands if they are installed, or falls back to the old behavior (or prompts the user to upgrade).

**Updated `bin/fin` logic:**
```bash
cmd_plan() {
  # New way: Instruct user to use slash command or inject it
  echo "Use /fin:plan inside Claude Code for best results."
  claude -p "/fin:plan '$1'"
}
```

### 6.2 Rollback Plan
Since the new architecture is additive (adding files to `~/.claude`), rollback is simple:
1.  Delete `~/.claude/commands/fin/`.
2.  Delete `~/.claude/agents/fin-*.md`.
3.  Revert `bin/fin` script.

## 7. Performance & Security Assessment

### 7.1 Performance
- **Latency**: Reduced start-up time (no new process overhead for every step).
- **Token Usage**: More efficient. `@` references allow targeted context loading, preventing "context pollution" from reading entire directories.

### 7.2 Security
- **Sandboxing**: Runs within Claude Code's existing sandbox.
- **Permissions**: Inherits user's approved permissions.
- **Audit**: `fin-reviewer` agent specifically enforces security checks (e.g., no hardcoded secrets).

## 8. Test Plan

| ID | Test Case | Input | Expected Output |
| :--- | :--- | :--- | :--- |
| TC-01 | **Plan with Context** | `/fin:plan "Add auth" @src/auth.ts` | Agent references `src/auth.ts` content and generates `PLAN.md`. |
| TC-02 | **Dev Loop** | `/fin:dev "Impl login"` | Agent creates test file -> fails -> implements code -> passes. |
| TC-03 | **Review Command** | `/fin:review` | Agent triggers `code-simplifier` and outputs review summary. |
| TC-04 | **Legacy Compatibility** | `fin plan "Old way"` | Shell script successfully invokes Claude and runs the plan. |

