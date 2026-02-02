---
name: fin:review
description: Code review, simplification, and pre-commit audit.
argument-hint: "[files/dirs]"
agent: fin-reviewer
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - mcp__code_simplifier__*
  - mcp__context7__*
---

<objective>
Review the current codebase (or specified files) for:
1. Complexity (Cyclomatic Complexity).
2. Security Vulnerabilities.
3. Style/Convention adherence.
</objective>

<process>
1. **Simplify**: Call `mcp__code_simplifier__simplify` on target files.
2. **Audit**: Scan for hardcoded secrets, weak crypto, or SQL injection risks.
3. **Report**: Generate a `REVIEW_REPORT.md` with findings and action items.
</process>
