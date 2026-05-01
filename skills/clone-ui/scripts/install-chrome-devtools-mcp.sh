#!/usr/bin/env bash
# install-chrome-devtools-mcp.sh
# Adds chrome-devtools-mcp to Claude Code's settings.json without overwriting existing mcpServers entries.
# Run from bash:
#   ~/.claude/skills/clone-ui/scripts/install-chrome-devtools-mcp.sh

set -euo pipefail

SETTINGS="$HOME/.claude/settings.json"

if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq is required but not installed."
    echo "Install via: brew install jq  (macOS)  |  sudo apt install jq  (Debian/Ubuntu)"
    exit 1
fi

if [ ! -f "$SETTINGS" ]; then
    echo "Creating new settings.json at $SETTINGS"
    mkdir -p "$(dirname "$SETTINGS")"
    echo '{}' > "$SETTINGS"
fi

if jq -e '.mcpServers."chrome-devtools"' "$SETTINGS" >/dev/null 2>&1; then
    echo "chrome-devtools MCP server already configured. Skipping."
    exit 0
fi

tmp=$(mktemp)
jq '.mcpServers["chrome-devtools"] = {"command": "npx", "args": ["-y", "chrome-devtools-mcp@latest"]}' "$SETTINGS" > "$tmp"
mv "$tmp" "$SETTINGS"

echo "Added chrome-devtools MCP to $SETTINGS"
echo "Restart Claude Code to activate."
