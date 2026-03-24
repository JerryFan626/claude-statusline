#!/bin/bash
set -euo pipefail

REPO="https://raw.githubusercontent.com/JerryFan626/claude-statusline/main"
SCRIPT_PATH="$HOME/.claude/statusline-command.sh"
SETTINGS_PATH="$HOME/.claude/settings.json"

echo "Installing Claude Code Status Line..."
echo ""

# Check for jq
if ! command -v jq &> /dev/null; then
    echo "  ✗ jq is required but not installed."
    echo "    Install with: brew install jq"
    exit 1
fi

# Ensure ~/.claude exists
mkdir -p "$HOME/.claude"

# Backup existing statusline script
if [ -f "$SCRIPT_PATH" ]; then
    backup="${SCRIPT_PATH}.bak.$(date +%s)"
    cp "$SCRIPT_PATH" "$backup"
    echo "  ↩ Backed up existing script → ${backup##*/}"
fi

# Download the script
curl -fsSL -o "$SCRIPT_PATH" "$REPO/statusline-command.sh"
chmod +x "$SCRIPT_PATH"
echo "  ✓ Downloaded statusline-command.sh"

# Patch settings.json
STATUSLINE_CONFIG='{"type":"command","command":"~/.claude/statusline-command.sh","padding":1}'

if [ -f "$SETTINGS_PATH" ]; then
    backup="${SETTINGS_PATH}.bak.$(date +%s)"
    cp "$SETTINGS_PATH" "$backup"
    echo "  ↩ Backed up settings.json → ${backup##*/}"

    tmp=$(mktemp)
    jq --argjson sl "$STATUSLINE_CONFIG" '.statusLine = $sl' "$SETTINGS_PATH" > "$tmp" \
        && mv "$tmp" "$SETTINGS_PATH"
    echo "  ✓ Updated settings.json"
else
    echo "{\"statusLine\":$STATUSLINE_CONFIG}" | jq . > "$SETTINGS_PATH"
    echo "  ✓ Created settings.json"
fi

# Validate
if echo '{"model":{"display_name":"Test"},"context_window":{"used_percentage":25},"workspace":{"current_dir":"/tmp"},"cost":{"total_cost_usd":0,"total_duration_ms":0,"total_lines_added":0,"total_lines_removed":0}}' | "$SCRIPT_PATH" > /dev/null 2>&1; then
    echo "  ✓ Validation passed"
else
    echo "  ⚠ Validation warning: script test failed, check dependencies"
fi

echo ""
echo "Done! Restart Claude Code to see the status line."
echo "Requires: bash, jq, git, and a Nerd Font."
