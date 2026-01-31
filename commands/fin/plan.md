---
name: fin:plan
description: Financial-grade planning: Architecture, Security, and Risk Assessment.
argument-hint: "[description] [@context]"
agent: fin-planner
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - WebFetch
---

<objective>
Create a comprehensive `PLAN.md` for the requested feature/change.
Ensure the plan adheres to Financial Grade constraints:
1. Security First (AuthZ/AuthN, Data Privacy).
2. Auditability (Logging, Tracing).
3. ACID Transactions (where applicable).
</objective>

<context>
User Input: $ARGUMENTS
(Note: @file references in arguments are automatically resolved by Claude Code)
</context>

<process>
1. Analyze requirements and provided context.
2. If context is insufficient, perform targeted research (WebFetch/Grep).
3. Draft `PLAN.md` containing:
   - Architecture Diagram (Mermaid)
   - Data Model Changes
   - Security Implications
   - Step-by-Step Implementation Plan
4. Ask user for approval.
</process>
