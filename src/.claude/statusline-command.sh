#!/bin/bash
# Status line converted from ~/.zshrc PROMPT='%F{6}%c%f $ '
# %F{6}/%f -> cyan color, %c -> current directory (basename)

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
dir=$(basename "$cwd")
model=$(echo "$input" | jq -r '.model.display_name')
session_id=$(echo "$input" | jq -r '.session_id // empty')
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
WHITE='\033[97m'
MAGENTA='\033[35m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
GRAY='\033[90m'
RESET='\033[0m'

if [ -n "$branch" ]; then
    dir_display="${WHITE}${dir}${RESET} ${CYAN}(${branch})${RESET}"
else
    dir_display="${WHITE}${dir}${RESET}"
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

# --- Other running Claude Code sessions (from ~/.claude/sessions/*.json) ---
SESSIONS_DIR="${CLAUDE_SESSIONS_DIR:-$HOME/.claude/sessions}"
sess_pid=() sess_sid=() sess_name=() sess_status=() sess_cwd=()
sess_overflow=0
sess_max=8

if [ -d "$SESSIONS_DIR" ]; then
    session_json_files=("$SESSIONS_DIR"/*.json)
    if [ -e "${session_json_files[0]}" ]; then
        # Use \x1f (unit separator) instead of @tsv: bash's IFS treats tab as
        # whitespace and collapses consecutive tabs, which breaks empty fields
        # (e.g. a session with no "name").
        session_lines=$(jq -s -r '
            [.[] | select(.kind == "interactive")]
            | sort_by(.startedAt)
            | .[] | [(.pid|tostring), (.sessionId // ""), (.name // ""), (.status // ""), .cwd] | join("")
        ' "${session_json_files[@]}" 2>/dev/null)

        sess_seen=0
        while IFS=$'\x1f' read -r s_pid s_sid s_name s_status s_cwd; do
            [ -z "$s_pid" ] && continue
            kill -0 "$s_pid" 2>/dev/null || continue
            [ -z "$s_name" ] && s_name=$(basename "$s_cwd")
            sess_seen=$((sess_seen + 1))
            if [ "$sess_seen" -gt "$sess_max" ]; then
                sess_overflow=$((sess_overflow + 1))
                continue
            fi
            sess_pid+=("$s_pid")
            sess_sid+=("$s_sid")
            sess_name+=("$s_name")
            sess_status+=("$s_status")
            sess_cwd+=("$s_cwd")
        done <<< "$session_lines"
    fi
fi

sess_name_width=0
for n in "${sess_name[@]}"; do
    if [ "${#n}" -gt "$sess_name_width" ]; then
        sess_name_width=${#n}
    fi
done
sess_status_width=7 # length of "waiting", the longest status value

render_session_line() {
    local sid="$1" name="$2" status="$3" cwd_raw="$4"
    local marker name_disp status_color status_disp cwd_disp prefix_len max_cwd

    if [ -n "$session_id" ] && [ "$sid" = "$session_id" ]; then
        marker='▶ '
        name_disp="${WHITE}$(printf '%-*s' "$sess_name_width" "$name")${RESET}"
    else
        marker='  '
        name_disp="$(printf '%-*s' "$sess_name_width" "$name")"
    fi

    case "$status" in
        busy) status_color=$YELLOW ;;
        waiting) status_color=$RED ;;
        idle) status_color=$GRAY ;;
        shell) status_color=$CYAN ;;
        *) status_color=$GRAY; status='-' ;;
    esac
    status_disp="${status_color}$(printf '%-*s' "$sess_status_width" "$status")${RESET}"

    cwd_disp="${cwd_raw/#$HOME/~}"
    if [ -n "$COLUMNS" ] && [ "$COLUMNS" -gt 0 ]; then
        prefix_len=$(( 2 + sess_name_width + 2 + sess_status_width + 2 ))
        max_cwd=$(( COLUMNS - prefix_len - 1 ))
        if [ "$max_cwd" -lt 5 ]; then
            max_cwd=5
        fi
        if [ "${#cwd_disp}" -gt "$max_cwd" ]; then
            cwd_disp="…${cwd_disp: -$((max_cwd - 1))}"
        fi
    fi

    printf '%s%s  %s  %b%s%b' "$marker" "$name_disp" "$status_disp" "$GRAY" "$cwd_disp" "$RESET"
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

for i in "${!sess_pid[@]}"; do
    printf '\n%b' "$(render_session_line "${sess_sid[$i]}" "${sess_name[$i]}" "${sess_status[$i]}" "${sess_cwd[$i]}")"
done

if [ "$sess_overflow" -gt 0 ]; then
    printf '\n%b' "${GRAY}  … +${sess_overflow} more${RESET}"
fi
