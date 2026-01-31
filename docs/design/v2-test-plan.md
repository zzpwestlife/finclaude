# FinClaude V2 Test Plan

This document outlines the testing strategy for the V2 native slash command implementation.

## 1. Unit Tests (Command Parsing)

| Test Case ID | Description | Input | Expected Outcome |
| :--- | :--- | :--- | :--- |
| UT-01 | **Valid Command** | `/fin:plan "New Feature"` | Command resolves, `fin-planner` agent is selected. |
| UT-02 | **Argument Parsing** | `/fin:dev "Fix login" @src/auth.ts` | Agent receives "Fix login" text AND content of `src/auth.ts`. |
| UT-03 | **Missing Arguments** | `/fin:plan` | Agent prompts user for description. |

## 2. Integration Tests (Workflow)

### 2.1 Planning Workflow
**Scenario**: User wants to plan a new "Audit Logging" module.
1.  **Action**: `/fin:plan "Design Audit Logging system" @docs/requirements.md`
2.  **Verify**:
    - `fin-planner` agent starts.
    - Agent reads `docs/requirements.md` (via context).
    - Agent produces `PLAN.md` in root.
    - `PLAN.md` contains "Security" section.

### 2.2 Development Workflow
**Scenario**: User wants to implement the Audit Logger.
1.  **Action**: `/fin:dev "Implement AuditLogger class"`
2.  **Verify**:
    - `fin-developer` agent starts.
    - Agent creates `tests/test_audit_logger.ts` (RED).
    - Agent runs tests -> Fail.
    - Agent creates `src/audit_logger.ts` (GREEN).
    - Agent runs tests -> Pass.

### 2.3 Review Workflow
**Scenario**: User requests code review.
1.  **Action**: `/fin:review @src/audit_logger.ts`
2.  **Verify**:
    - `fin-reviewer` agent starts.
    - Agent calls `code-simplifier` on `src/audit_logger.ts`.
    - Agent outputs review comments regarding logging formats and PII masking.

## 3. Regression Tests (Legacy Compatibility)

| Test Case ID | Description | Input | Expected Outcome |
| :--- | :--- | :--- | :--- |
| RT-01 | **Legacy Shell Command** | `fin plan "Old way"` | Shell script detects arguments, executes `claude -p "/fin:plan 'Old way'"`. |
| RT-02 | **Environment Check** | `fin doctor` | Still correctly identifies installed components (including new agent files). |

## 4. Acceptance Criteria

- All commands (`/fin:plan`, `/fin:dev`, `/fin:review`) must appear in Claude Code's autocomplete (if supported) or be executable without error.
- `@` references must be resolved correctly.
- Subagents must stay in character (Planner doesn't write code, Developer doesn't write plans).
