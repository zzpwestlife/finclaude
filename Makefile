# FinClaude Makefile
# 简化常用操作

.PHONY: install update uninstall doctor status test notify clean help

# 默认目标
.DEFAULT_GOAL := help

# 安装 FinClaude
install:
	@echo "🔧 安装 FinClaude..."
	@chmod +x install.sh
	@./install.sh

# 更新 FinClaude
update:
	@echo "🔄 更新 FinClaude..."
	@git pull
	@./install.sh

# 卸载 FinClaude
uninstall:
	@echo "🗑️  卸载 FinClaude..."
	@rm -rf ~/finclaude
	@rm -f ~/.claude/settings.json
	@rm -rf ~/.finclaude
	@echo "✅ 卸载完成"

# 诊断环境
doctor:
	@fin doctor

# 查看状态
status:
	@fin status

# 运行测试
test:
	@npm test -- --coverage

# 发送测试通知
notify:
	@fin notify "测试通知"

# 清理临时文件
clean:
	@echo "🧹 清理临时文件..."
	@rm -rf node_modules
	@rm -f package-lock.json
	@find . -name ".DS_Store" -delete
	@find . -name "*.log" -delete
	@echo "✅ 清理完成"

# 显示帮助
help:
	@echo ""
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║  FinClaude Makefile                                        ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "可用命令:"
	@echo "  make install    安装 FinClaude"
	@echo "  make update     更新 FinClaude"
	@echo "  make uninstall  卸载 FinClaude"
	@echo "  make doctor     诊断环境配置"
	@echo "  make status     查看组件状态"
	@echo "  make test       运行测试"
	@echo "  make notify     发送测试通知"
	@echo "  make clean      清理临时文件"
	@echo "  make help       显示帮助信息"
	@echo ""
