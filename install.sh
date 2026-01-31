#!/bin/bash
# FinClaude Simplified Installer

set -e

# Configuration
AGENTS_DIR="$HOME/.claude/agents"
COMMANDS_DIR="$HOME/.claude/commands/fin"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "========================================"
echo "  FinClaude Installer"
echo "========================================"

# 1. Check Claude Code
echo "[INFO] Checking Claude Code environment..."
if [ ! -d "$HOME/.claude" ]; then
    echo "[ERROR] ~/.claude directory not found. Please install Claude Code first."
    exit 1
fi

# 2. Create directories
echo "[INFO] Creating directories..."
mkdir -p "$AGENTS_DIR"
mkdir -p "$COMMANDS_DIR"

# 3. Install Agents
echo "[INFO] Installing Agents..."
cp "$SCRIPT_DIR/agents/"*.md "$AGENTS_DIR/"

# 4. Install Commands
echo "[INFO] Installing Slash Commands..."
cp "$SCRIPT_DIR/commands/fin/"*.md "$COMMANDS_DIR/"

echo "[SUCCESS] Installation Complete!"
echo "========================================"
echo "Usage:"
echo "  /fin:plan   - Architecture Planning"
echo "  /fin:dev    - TDD Development"
echo "  /fin:review - Code Review"
echo "========================================"
