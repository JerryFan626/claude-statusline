# Claude Code Status Line

为 [Claude Code](https://claude.ai/claude-code) 打造的双行状态栏，使用 Nerd Font 图标。

[English](README.md)

## 功能

**第一行 — AI 状态与用量：**
```
󰚩 Opus │ 󰍛 ▰▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱ 28% │ 󰄉 $0.42 │ 5h 45% ↺ 4h27m │ 7d 12% ↺ 5d2h
```
- 模型名称
- Context 使用率（16 段进度条，颜色随阈值变化）
- 会话费用
- 5 小时 / 7 天 API 配额及重置倒计时
- Context ≥ 90% 时显示红色警告

**第二行 — 工作区信息：**
```
󰝰 my-project │ 󰘬 main +2 ~1 ?3 │ 󰎙 v22 │ 󰅩 +156/-23 │ 󰥔 12m │ 󰕷 NORMAL
```
- 当前目录
- Git 分支及文件变更数：staged (+)、unstaged (~)、untracked (?)
- Node.js 版本
- 会话中增删行数
- 会话持续时间
- Agent 名称（使用 `--agent` 时）
- Worktree 名称（使用 worktree 模式时）
- Vim 模式指示

## 颜色规则

红绿灯式配色：
- 🟢 绿色：0–49%
- 🟡 黄色：50–79%
- 🔴 红色：80%+

## 安装

### 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/JerryFan626/claude-statusline/main/install.sh | bash
```

### 手动安装

1. 下载脚本：
```bash
curl -fsSL -o ~/.claude/statusline-command.sh \
  https://raw.githubusercontent.com/JerryFan626/claude-statusline/main/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

2. 在 `~/.claude/settings.json` 中添加配置：
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline-command.sh",
    "padding": 1
  }
}
```

3. 重启 Claude Code。

## 卸载

```bash
curl -fsSL https://raw.githubusercontent.com/JerryFan626/claude-statusline/main/uninstall.sh | bash
```

或手动删除 `~/.claude/statusline-command.sh` 并移除 `settings.json` 中的 `statusLine` 字段。

## 自定义

### 主题

自动从 macOS 系统设置检测深色/浅色模式。手动覆盖：

```bash
export STATUSLINE_THEME=dark   # 或 light、auto
```

### 修改脚本

克隆仓库后直接编辑 `statusline-command.sh`，关键常量：

| 变量 | 默认值 | 说明 |
|---|---|---|
| `BAR_SEGMENTS` | `16` | 进度条段数 |
| 颜色阈值 | `50 / 80` | 绿→黄→红 分界点 |

## 依赖

- bash（兼容 macOS 默认 bash 3.2）
- [jq](https://jqlang.github.io/jq/)
- git
- [Nerd Font](https://www.nerdfonts.com/) 字体

## 设计理念

- Rate limits 直接从 Claude Code stdin JSON 读取，无需 OAuth API 调用或缓存
- 所有 JSON 解析通过单次 `jq` 调用完成
- 单次 `git status --porcelain` 调用统计文件变更
- 渲染约 30ms

## 许可证

[MIT](LICENSE)
