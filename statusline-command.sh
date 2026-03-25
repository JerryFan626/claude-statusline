#!/bin/bash

# Claude Code Status Line — Two-line layout with dual icon modes (ascii/nerd)
# Line 1: Model │ Context Bar │ Cost │ 5h usage │ 7d usage
# Line 2: Directory │ Git Branch & Status │ Node.js │ Lines Changed │ Duration │ Agent │ Worktree │ Vim
#
# https://github.com/JerryFan626/claude-statusline

input=$(< /dev/stdin)
now=$(date +%s)

# --- Extract all values in a single jq call ---
eval "$(echo "$input" | jq -r '
    @sh "model=\(.model.display_name // "?")",
    @sh "cwd=\(.workspace.current_dir // ".")",
    @sh "used_pct=\(.context_window.used_percentage // 0)",
    @sh "cost=\(.cost.total_cost_usd // 0)",
    @sh "duration_ms=\(.cost.total_duration_ms // 0)",
    @sh "lines_added=\(.cost.total_lines_added // 0)",
    @sh "lines_removed=\(.cost.total_lines_removed // 0)",
    @sh "vim_mode=\(.vim.mode // "")",
    @sh "agent_name=\(.agent.name // "")",
    @sh "worktree_name=\(.worktree.name // "")",
    @sh "pct5h=\(.rate_limits.five_hour.used_percentage // -1)",
    @sh "epoch5h=\(.rate_limits.five_hour.resets_at // 0)",
    @sh "pct7d=\(.rate_limits.seven_day.used_percentage // -1)",
    @sh "epoch7d=\(.rate_limits.seven_day.resets_at // 0)"
')"

dir_name="${cwd##*/}"

# --- Theme detection ---
# Override with STATUSLINE_THEME=dark|light|auto (default: auto)
detect_theme() {
    local theme="${STATUSLINE_THEME:-auto}"
    if [ "$theme" != "auto" ]; then echo "$theme"; return; fi

    # macOS system appearance
    if defaults read -g AppleInterfaceStyle &>/dev/null; then
        echo "dark"; return
    fi

    # COLORFGBG env var (e.g. "15;0" → bg=0 is dark)
    if [ -n "$COLORFGBG" ]; then
        local bg="${COLORFGBG##*;}"
        if [ "$bg" -lt 8 ] 2>/dev/null; then
            echo "dark"
        else
            echo "light"
        fi
        return
    fi

    echo "dark"
}

THEME=$(detect_theme)

# --- Colors ---
RST=$'\033[0m'
BOLD=$'\033[1m'

if [ "$THEME" = "light" ]; then
    DIM=$'\033[90m'
    CYAN=$'\033[36m'
    GREEN=$'\033[32m'
    YELLOW=$'\033[33m'
    RED=$'\033[31m'
    MAGENTA=$'\033[35m'
    BLUE=$'\033[34m'
    BG_RED=$'\033[41m'
    WHITE_BOLD=$'\033[1;30m'
else
    DIM=$'\033[2m'
    CYAN=$'\033[36m'
    GREEN=$'\033[32m'
    YELLOW=$'\033[33m'
    RED=$'\033[31m'
    MAGENTA=$'\033[35m'
    BLUE=$'\033[34m'
    BG_RED=$'\033[41m'
    WHITE_BOLD=$'\033[1;37m'
fi

# --- Icons: ascii (default) or nerd (requires Nerd Font) ---
# Override with STATUSLINE_ICONS=nerd
ICON_MODE="${STATUSLINE_ICONS:-ascii}"

if [ "$ICON_MODE" = "nerd" ]; then
    ICON_MODEL="󰚩"     # nf-md-robot
    ICON_CTX="󰍛"       # nf-md-memory
    ICON_DIR="󰝰"       # nf-md-folder_outline
    ICON_GIT="󰘬"       # nf-md-source_branch
    ICON_COST="󰄉"      # nf-md-cash
    ICON_WARN=""       # nf-fa-warning
    ICON_VIM="󰕷"       # nf-md-vim
    ICON_NODE="󰎙"      # nf-md-nodejs
    ICON_CLOCK="󰥔"     # nf-md-clock_outline
    ICON_CODE="󰅩"      # nf-md-code_tags
    ICON_AGENT="󰳗"     # nf-md-robot_outline
    ICON_TREE="󰐅"      # nf-md-source_fork
else
    ICON_MODEL="⚡"
    ICON_CTX="◧"
    ICON_DIR="📂"
    ICON_GIT="⎇"
    ICON_COST=""
    ICON_WARN="⚠"
    ICON_VIM="VIM"
    ICON_NODE="⬢"
    ICON_CLOCK="⏱"
    ICON_CODE="<>"
    ICON_AGENT="🤖"
    ICON_TREE="🌳"
fi

SEP="${DIM} │ ${RST}"
BAR_SEGMENTS=16

# --- Color helper for utilization percentage ---
pct_color() {
    local pct=$1
    if [ "$pct" -lt 50 ]; then echo "$GREEN"
    elif [ "$pct" -lt 80 ]; then echo "$YELLOW"
    else echo "$RED"
    fi
}

# --- Context percentage ---
pct_int=${used_pct%.*}
pct_int=${pct_int:-0}
CTX_COLOR=$(pct_color "$pct_int")

# --- Progress bar ---
filled=$(( (pct_int * BAR_SEGMENTS + 50) / 100 ))
if [ "$filled" -gt "$BAR_SEGMENTS" ]; then filled=$BAR_SEGMENTS; fi
empty=$((BAR_SEGMENTS - filled))
bar=""
i=0; while [ "$i" -lt "$filled" ]; do bar="${bar}▰"; i=$((i + 1)); done
i=0; while [ "$i" -lt "$empty" ]; do bar="${bar}▱"; i=$((i + 1)); done

# --- Cost ---
printf -v cost_str '$%.2f' "$cost"

# --- Rate limit helpers ---
format_countdown() {
    local diff=$(( $1 - now ))
    if [ "$diff" -le 0 ]; then echo "soon"; return; fi
    if [ "$diff" -ge 86400 ]; then
        echo "$((diff / 86400))d$((diff % 86400 / 3600))h"
    elif [ "$diff" -ge 3600 ]; then
        echo "$((diff / 3600))h$((diff % 3600 / 60))m"
    else
        echo "$((diff / 60))m"
    fi
}

usage_segment() {
    local label=$1 pct=$2 reset_epoch=$3
    local color reset_str
    color=$(pct_color "$pct")
    reset_str=$(format_countdown "$reset_epoch")
    echo "${SEP}${DIM}${label}${RST} ${color}${pct}%${RST} ${DIM}↺ ${reset_str}${RST}"
}

# --- Rate limits (direct from stdin JSON, no API call needed) ---
usage_5h="" usage_7d=""
pct5h_int=${pct5h%.*}; pct5h_int=${pct5h_int:-0}
pct7d_int=${pct7d%.*}; pct7d_int=${pct7d_int:-0}

if [ "$pct5h_int" -ge 0 ] 2>/dev/null; then
    usage_5h=$(usage_segment "5h" "$pct5h_int" "$epoch5h")
fi
if [ "$pct7d_int" -ge 0 ] 2>/dev/null; then
    usage_7d=$(usage_segment "7d" "$pct7d_int" "$epoch7d")
fi

# --- Git info (single git status --porcelain call) ---
git_info=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
    [ -z "$branch" ] && branch="detached"

    staged=0 unstaged=0 untracked=0
    while IFS= read -r line; do
        x=${line:0:1}
        y=${line:1:1}
        if [ "$x$y" = "??" ]; then
            untracked=$((untracked + 1))
        else
            [ "$x" != " " ] && [ "$x" != "?" ] && staged=$((staged + 1))
            [ "$y" != " " ] && unstaged=$((unstaged + 1))
        fi
    done < <(git -C "$cwd" status --porcelain 2>/dev/null)

    status=""
    [ "$staged" -gt 0 ] && status="${status} ${GREEN}+${staged}${RST}"
    [ "$unstaged" -gt 0 ] && status="${status} ${YELLOW}~${unstaged}${RST}"
    [ "$untracked" -gt 0 ] && status="${status} ${DIM}?${untracked}${RST}"

    git_info="${SEP}${MAGENTA}${ICON_GIT} ${branch}${RST}${status}"
fi

# --- Node.js version detection ---
node_str=""
if command -v node &>/dev/null; then
    node_ver=$(node --version 2>/dev/null | sed 's/^v//' | cut -d. -f1)
    if [ -n "$node_ver" ]; then
        node_str="${SEP}${GREEN}${ICON_NODE} v${node_ver}${RST}"
    fi
fi

# --- Lines changed ---
changes_str=""
la=${lines_added%.*}; la=${la:-0}
lr=${lines_removed%.*}; lr=${lr:-0}
if [ "$la" -gt 0 ] || [ "$lr" -gt 0 ]; then
    changes_str="${SEP}${DIM}${ICON_CODE}${RST} ${GREEN}+${la}${RST}/${RED}-${lr}${RST}"
fi

# --- Session duration ---
duration_str=""
dur_ms=${duration_ms%.*}; dur_ms=${dur_ms:-0}
if [ "$dur_ms" -gt 0 ]; then
    dur_sec=$((dur_ms / 1000))
    if [ "$dur_sec" -ge 3600 ]; then
        dur_h=$((dur_sec / 3600))
        dur_m=$(( (dur_sec % 3600) / 60 ))
        duration_str="${SEP}${DIM}${ICON_CLOCK} ${dur_h}h${dur_m}m${RST}"
    elif [ "$dur_sec" -ge 60 ]; then
        dur_m=$((dur_sec / 60))
        duration_str="${SEP}${DIM}${ICON_CLOCK} ${dur_m}m${RST}"
    else
        duration_str="${SEP}${DIM}${ICON_CLOCK} ${dur_sec}s${RST}"
    fi
fi

# --- Agent name ---
agent_str=""
if [ -n "$agent_name" ]; then
    agent_str="${SEP}${MAGENTA}${ICON_AGENT} ${agent_name}${RST}"
fi

# --- Worktree name ---
worktree_str=""
if [ -n "$worktree_name" ]; then
    worktree_str="${SEP}${CYAN}${ICON_TREE} ${worktree_name}${RST}"
fi

# --- Vim mode ---
vim_str=""
if [ -n "$vim_mode" ]; then
    if [ "$vim_mode" = "NORMAL" ]; then vim_color=$BLUE; else vim_color=$GREEN; fi
    vim_str="${SEP}${vim_color}${BOLD}${ICON_VIM} ${vim_mode}${RST}"
fi

# --- Build output ---
line1_tail="${SEP}${DIM}${ICON_COST} ${cost_str}${RST}${usage_5h}${usage_7d}"

if [ "$pct_int" -ge 90 ]; then
    line1="${BG_RED}${WHITE_BOLD} ${ICON_WARN} CTX ${pct_int}% ${RST} ${CYAN}${BOLD}${ICON_MODEL} ${model}${RST}${SEP}${CTX_COLOR}${bar}${RST}${line1_tail}"
else
    line1="${CYAN}${BOLD}${ICON_MODEL} ${model}${RST}${SEP}${DIM}${ICON_CTX}${RST} ${CTX_COLOR}${bar} ${pct_int}%${RST}${line1_tail}"
fi

line2="${BLUE}${ICON_DIR} ${dir_name}${RST}${git_info}${node_str}${changes_str}${duration_str}${agent_str}${worktree_str}${vim_str}"

printf '%s\n%s' "$line1" "$line2"
