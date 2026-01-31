---
name: fin:dev
description: TDD execution: Red -> Green -> Refactor.
argument-hint: "[task] [@context]"
agent: fin-developer
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - RunCommand
  - mcp__context7__*
---

<objective>
Implement the requested feature using strict Test-Driven Development (TDD).
</objective>

<rules>
1. **RED**: Write a failing test case first. Verify it fails.
2. **GREEN**: Write the minimal code to pass the test. Verify it passes.
3. **REFACTOR**: Optimize code structure without breaking tests.
4. **COVERAGE**: Ensure new code has >80% coverage.
</rules>
