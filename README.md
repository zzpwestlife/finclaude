# FinClaude

> Financial-grade Development Extension for Claude Code.

FinClaude is a lightweight extension that brings standardized workflows to your Claude Code environment, focusing on Security, TDD, and Auditability.

## 🚀 Quick Start

```bash
# Clone and Install
git clone https://github.com/finclaude/finclaude.git
cd finclaude
./install.sh
```

## 🛠 Commands

| Command | Description | Usage |
|---------|-------------|-------|
| **/fin:plan** | **Architecture Planning**<br>Generates secure, atomic implementation plans. | `/fin:plan "Add OAuth2" @docs/auth.md` |
| **/fin:dev** | **TDD Development**<br>Executes Red-Green-Refactor cycle. | `/fin:dev "Implement User Model" @src/models/` |
| **/fin:review** | **Code Audit**<br>Checks for complexity and security risks. | `/fin:review @src/core/` |

## 🔄 Workflow Example

1.  **Plan**: `/fin:plan "Design transaction rollback mechanism"`
2.  **Develop**: `/fin:dev "Implement rollback logic" @PLAN.md`
3.  **Review**: `/fin:review @src/transaction.ts`

## 🧹 Uninstall

```bash
rm ~/.claude/agents/fin-*.md
rm -rf ~/.claude/commands/fin/
```

## 📄 License

MIT
