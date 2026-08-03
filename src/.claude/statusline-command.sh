#!/bin/bash
# Status line converted from ~/.zshrc PROMPT='%F{6}%c%f $ '
# %F{6}/%f -> cyan color, %c -> current directory (basename)

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
dir=$(basename "$cwd")
model=$(echo "$input" | jq -r '.model.display_name')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
tokens_used=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
tokens_limit=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
five_hour=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hour_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_day_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

fmt_tokens() {
    awk -v n="$1" 'BEGIN{ if (n>=1000) printf "%.1fk", n/1000; else printf "%d", n }'
}

branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)

# Colors tuned for readability on dark terminal backgrounds (no bold)
CYAN='\033[36m'
BLUE='\033[34m'
MAGENTA='\033[35m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
GRAY='\033[90m'
RESET='\033[0m'

if [ -n "$branch" ]; then
    dir_display="${CYAN}${dir}${RESET} ${BLUE}(${branch})${RESET}"
else
    dir_display="${CYAN}${dir}${RESET}"
fi

if [ -n "$used" ]; then
    used_int=$(printf '%.0f' "$used")
    if [ "$used_int" -ge 80 ]; then
        ctx_color=$RED
    elif [ "$used_int" -ge 50 ]; then
        ctx_color=$YELLOW
    else
        ctx_color=$GREEN
    fi
    if [ -n "$tokens_used" ] && [ -n "$tokens_limit" ]; then
        ctx=$(printf 'Ctx: %d%% (%s/%s)' "$used_int" "$(fmt_tokens "$tokens_used")" "$(fmt_tokens "$tokens_limit")")
    else
        ctx=$(printf 'Ctx: %d%%' "$used_int")
    fi
else
    ctx_color=$GRAY
    ctx='Ctx: N/A'
fi

fmt_rate() {
    local label="$1" pct="$2" reset_epoch="$3" pct_int color reset_display=''
    pct_int=$(printf '%.0f' "$pct")
    if [ "$pct_int" -ge 80 ]; then
        color=$RED
    elif [ "$pct_int" -ge 50 ]; then
        color=$YELLOW
    else
        color=$GREEN
    fi
    if [ -n "$reset_epoch" ]; then
        now=$(date +%s)
        if [ "$reset_epoch" -gt "$((now + 86400))" ]; then
            reset_display=$(date -r "$reset_epoch" '+%m/%d %H:%M')
        else
            reset_display=$(date -r "$reset_epoch" '+%H:%M')
        fi
        printf '%b%s: %d%% (→%s)%b' "$color" "$label" "$pct_int" "$reset_display" "$RESET"
    else
        printf '%b%s: %d%%%b' "$color" "$label" "$pct_int" "$RESET"
    fi
}

sep=" ${GRAY}│${RESET} "
line="${dir_display}${sep}${MAGENTA}${model}${RESET}${sep}${ctx_color}${ctx}${RESET}"

if [ -n "$five_hour" ]; then
    line="${line}${sep}$(fmt_rate '5h' "$five_hour" "$five_hour_reset")"
fi

if [ -n "$seven_day" ]; then
    line="${line}${sep}$(fmt_rate '7d' "$seven_day" "$seven_day_reset")"
fi

if [ -n "$cost" ]; then
    cost_display=$(printf '$%.4f' "$cost")
    line="${line}${sep}${GREEN}${cost_display}${RESET}"
fi

printf '%b' "$line"
