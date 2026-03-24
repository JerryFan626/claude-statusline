# Claude Code Status Line

A two-line status line for [Claude Code](https://claude.ai/claude-code) with Nerd Font icons.

[中文文档](README.zh-CN.md)

## Features

**Line 1 — AI Status & Usage:**
```
󰚩 Opus │ 󰍛 ▰▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱ 28% │ 󰄉 $0.42 │ 5h 45% ↺ 4h27m │ 7d 12% ↺ 5d2h
```
- Model name
- Context window usage (16-segment progress bar with color coding)
- Session cost
- 5-hour / 7-day API quota with reset countdown
- Red alert badge when context ≥ 90%

**Line 2 — Workspace:**
```
󰝰 my-project │ 󰘬 main +2 ~1 ?3 │ 󰎙 v22 │ 󰅩 +156/-23 │ 󰥔 12m │ 󰕷 NORMAL
```
- Current directory
- Git branch with staged (+), unstaged (~), untracked (?) counts
- Node.js version
- Lines added/removed in session
- Session duration
- Agent name (when using `--agent`)
- Worktree name (when using worktree mode)
- Vim mode indicator

## Color Coding

Traffic-light utilization colors:
- 🟢 Green: 0–49%
- 🟡 Yellow: 50–79%
- 🔴 Red: 80%+

## Install

### One-line install

```bash
curl -fsSL https://raw.githubusercontent.com/JerryFan626/claude-statusline/main/install.sh | bash
```

### Manual install

1. Download the script:
```bash
curl -fsSL -o ~/.claude/statusline-command.sh \
  https://raw.githubusercontent.com/JerryFan626/claude-statusline/main/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

2. Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline-command.sh",
    "padding": 1
  }
}
```

3. Restart Claude Code.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/JerryFan626/claude-statusline/main/uninstall.sh | bash
```

Or manually remove `~/.claude/statusline-command.sh` and the `statusLine` key from `settings.json`.

## Customization

### Theme

Auto-detects dark/light mode from macOS system settings. Override with:

```bash
export STATUSLINE_THEME=dark   # or light, auto
```

### Modifying the script

Clone the repo and edit `statusline-command.sh` directly. Key constants at the top:

| Variable | Default | Description |
|---|---|---|
| `BAR_SEGMENTS` | `16` | Number of progress bar segments |
| Color thresholds | `50 / 80` | Green→Yellow→Red boundaries |

## Requirements

- bash (compatible with macOS default bash 3.2)
- [jq](https://jqlang.github.io/jq/)
- git
- A [Nerd Font](https://www.nerdfonts.com/) for icon rendering

## Design

- Rate limits read directly from Claude Code's stdin JSON — no OAuth API calls or caching needed
- Single `jq` invocation for all JSON parsing
- Single `git status --porcelain` call for file counts
- Renders in ~30ms

## License

[MIT](LICENSE)
