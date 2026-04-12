# Claude Code Status Line

A two-line status line for [Claude Code](https://claude.ai/claude-code) with dual icon modes (ASCII / Nerd Font).

[中文文档](README.zh-CN.md)

## Features

**Line 1 — AI Status & Usage:**
```
⚡ Opus │ ◧ ▰▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱ 28% │ $ $0.42 │ 5h 45% ↺ 4h27m │ 7d 12% ↺ 5d2h
```
- Model name
- Context window usage (16-segment progress bar with color coding)
- Session cost
- 5-hour / 7-day API quota with reset countdown
- Red alert badge when context ≥ 90%

**Line 2 — Workspace:**
```
📂 my-project │ ⎇ main +2 ~1 ?3 │ ⬢ v22 │ <> +156/-23 │ ⏱ 12m │ VIM NORMAL
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

## Upgrade

Re-run the install command to upgrade to the latest version:

```bash
curl -fsSL https://raw.githubusercontent.com/JerryFan626/claude-statusline/main/install.sh | bash
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/JerryFan626/claude-statusline/main/uninstall.sh | bash
```

Or manually remove `~/.claude/statusline-command.sh` and the `statusLine` key from `settings.json`.

## Customization

### Icons

Two icon modes available, controlled by `STATUSLINE_ICONS` environment variable:

```bash
# ASCII mode (default, works in any terminal)
export STATUSLINE_ICONS=ascii

# Nerd Font mode (requires a Nerd Font installed)
export STATUSLINE_ICONS=nerd
```

### Theme

Auto-detects dark/light mode from macOS system settings. Override with:

```bash
export STATUSLINE_THEME=dark   # or light, auto
```

### Icon Overrides

Override any individual icon regardless of mode:

```bash
export STATUSLINE_ICON_GIT="󰘬"     # Override just the git icon
export STATUSLINE_ICON_MODEL="🤖"   # Override just the model icon
```

Available icon names: `MODEL`, `CTX`, `DIR`, `GIT`, `COST`, `WARN`, `VIM`, `NODE`, `CLOCK`, `CODE`, `AGENT`, `TREE`.

### Line Order

By default, AI status is on line 1 and workspace info on line 2. Swap them with:

```bash
export STATUSLINE_LINE_ORDER=workspace-first
```

This is useful when Claude Code's permission-mode indicator overlaps the bottom row.

### Worktree Root Path

Show the git worktree root path as a segment:

```bash
export STATUSLINE_SHOW_WORKTREE_PATH=1
```

### Workspace Segment Order

Customize the order of directory, branch, and worktree path segments:

```bash
# Default order
export STATUSLINE_WORKSPACE_ORDER=dir,branch,worktree_path

# Worktree-first order
export STATUSLINE_WORKSPACE_ORDER=worktree_path,branch,dir
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
- (Optional) A [Nerd Font](https://www.nerdfonts.com/) — only needed for `STATUSLINE_ICONS=nerd` mode

## Design

- Rate limits read directly from Claude Code's stdin JSON — no OAuth API calls or caching needed
- Single `jq` invocation for all JSON parsing
- Single `git status --porcelain` call for file counts
- Renders in ~30ms

## License

[MIT](LICENSE)
