#!/bin/bash
set -euo pipefail

SCRIPT_PATH="$HOME/.claude/statusline-command.sh"
SETTINGS_PATH="$HOME/.claude/settings.json"
CACHE_DIR="$HOME/.claude/statusline-cache"

echo "Uninstalling Claude Code Status Line..."
echo ""

# Remove script
if [ -f "$SCRIPT_PATH" ]; then
    rm "$SCRIPT_PATH"
    echo "  ✓ Removed statusline-command.sh"
else
    echo "  - statusline-command.sh not found, skipping"
fi

# Remove cache directory
if [ -d "$CACHE_DIR" ]; then
    rm -rf "$CACHE_DIR"
    echo "  ✓ Removed statusline cache"
fi

# Remove statusLine from settings.json
if [ -f "$SETTINGS_PATH" ] && command -v jq &>/dev/null; then
    if jq -e '.statusLine' "$SETTINGS_PATH" > /dev/null 2>&1; then
        tmp=$(mktemp)
        jq 'del(.statusLine)' "$SETTINGS_PATH" > "$tmp" && mv "$tmp" "$SETTINGS_PATH"
        echo "  ✓ Removed statusLine from settings.json"
    else
        echo "  - No statusLine config in settings.json, skipping"
    fi
fi

echo ""
echo "Done! Restart Claude Code to apply changes."
