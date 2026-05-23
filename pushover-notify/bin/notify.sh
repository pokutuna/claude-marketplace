#!/bin/bash
# notify.sh - Pushover notification control for Claude Code
#
# Subcommands:
#   enable           Enable notifications globally
#   disable          Disable notifications globally
#   toggle           Flip enabled/disabled
#   status           Show current state
#   send             Hook mode: read JSON from stdin and send notification
#
# State file (git-config format):
#   ${XDG_STATE_HOME:-~/.local/state}/claude-pushover-notify.conf
#     [global] enabled    = true|false
#     [global] last-sent  = <epoch>          # last successful send time (any session)
#     [global] last-session = <session-id>   # session that triggered the last send
#
# Environment:
#   PUSHOVER_TOKEN  (required for send/enable)
#   PUSHOVER_USER   (required for send/enable)

set -uo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_FILE="$STATE_DIR/claude-pushover-notify.conf"
# Within this window after the last send from the SAME session, the next
# notification is delivered silently (sound=none) instead of being dropped.
# Notifications from a DIFFERENT session always play a sound.
QUIET_WINDOW_SEC=180

ensure_state_dir() {
    mkdir -p "$STATE_DIR"
}

cfg_get() {
    git config -f "$CONFIG_FILE" "$1" 2>/dev/null
}

cfg_set() {
    ensure_state_dir
    git config -f "$CONFIG_FILE" "$1" "$2" 2>/dev/null || true
}

get_enabled()      { cfg_get global.enabled      || echo "false"; }
get_last_sent()    { cfg_get global.last-sent    || echo "0"; }
get_last_session() { cfg_get global.last-session || echo ""; }

set_enabled()      { cfg_set global.enabled      "$1"; }
set_last_sent()    { cfg_set global.last-sent    "$1"; }
set_last_session() { cfg_set global.last-session "$1"; }

check_credentials() {
    [[ -n "${PUSHOVER_TOKEN:-}" && -n "${PUSHOVER_USER:-}" ]]
}

# Returns 0 (true) if the user is currently active (display on, input recently used),
# 1 (false) if idle/display off or detection unavailable.
# Reads the system-wide UserIsActive assertion from `pmset -g assertions`, which is
# set to 1 by IOKit while input devices are in use and released ~180s after the last
# input event (i.e. around the time the display sleeps).
# When pmset is unavailable (non-macOS), returns 1 so notifications are sent.
is_display_on() {
    command -v pmset >/dev/null 2>&1 || return 1
    local value
    value=$(pmset -g assertions 2>/dev/null \
        | awk '/^Assertion status system-wide:/{f=1; next} /^Listed by owning process:/{f=0} f && $1=="UserIsActive"{print $2; exit}')
    [[ "$value" == "1" ]]
}

# Extract a short context summary from the transcript file.
# For each assistant turn (scanned from newest first), combine the trimmed text
# content with any tool_use names ("[ToolName]") in turn order so a short header
# like "結果サマリ:" still carries the following tool call into the notification.
# Returns the first non-empty result, truncated to 160 chars.
transcript_summary() {
    local path="$1"
    [[ -n "$path" && -r "$path" ]] || return 0
    command -v jq >/dev/null 2>&1 || return 0

    # tail -r reverses lines on BSD (macOS) and GNU coreutils; tac would
    # require coreutils on macOS, so prefer tail -r for portability.
    tail -r "$path" 2>/dev/null | jq -r '
        select(.type == "assistant")
        | .message.content // []
        | [
            .[]
            | if .type == "text" then (.text // "")
              elif .type == "tool_use" then "[" + .name + "]"
              else empty
              end
          ]
        | join(" ")
    ' 2>/dev/null | awk '
        {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "")
            gsub(/\n+/, " ")
        }
        NF > 0 { print; exit }
    ' | cut -c1-160
}

# Pretty repo name from cwd: basename, falling back to "cwd".
repo_label() {
    local cwd="$1"
    [[ -n "$cwd" ]] || return 0
    basename "$cwd"
}

cmd_enable() {
    if ! check_credentials; then
        echo "Error: PUSHOVER_TOKEN and PUSHOVER_USER must be set" >&2
        exit 1
    fi
    set_enabled "true"
    echo "Pushover notifications: enabled"
}

cmd_disable() {
    set_enabled "false"
    echo "Pushover notifications: disabled"
}

cmd_toggle() {
    local current
    current=$(get_enabled)
    if [[ "$current" == "true" ]]; then
        cmd_disable
    else
        cmd_enable
    fi
}

cmd_status() {
    local enabled token_status user_status
    enabled=$(get_enabled)

    if [[ -n "${PUSHOVER_TOKEN:-}" ]]; then token_status="set"; else token_status="unset"; fi
    if [[ -n "${PUSHOVER_USER:-}" ]]; then user_status="set"; else user_status="unset"; fi

    echo "Pushover notifications: $enabled"
    echo "PUSHOVER_TOKEN: $token_status"
    echo "PUSHOVER_USER: $user_status"

    if command -v jq >/dev/null 2>&1; then
        echo "jq: available"
    else
        echo "jq: missing (notifications will be skipped)"
    fi

    if command -v pmset >/dev/null 2>&1; then
        if is_display_on; then
            echo "Display: on (notifications skipped)"
        else
            echo "Display: off (notifications sent)"
        fi
    else
        echo "Display detection: unavailable (pmset not found, notifications always sent)"
    fi

    local last_sent last_session
    last_sent=$(get_last_sent)
    last_session=$(get_last_session)
    if [[ "$last_sent" != "0" ]]; then
        local last_time
        last_time=$(date -r "$last_sent" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
            || date -d "@$last_sent" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
            || echo "$last_sent")
        echo "Last sent: $last_time"
        [[ -n "$last_session" ]] && echo "Last session: $last_session"
    fi
}

cmd_send() {
    [[ "$(get_enabled)" == "true" ]] || exit 0
    check_credentials || exit 0
    command -v jq >/dev/null 2>&1 || exit 0
    ! is_display_on || exit 0

    local input
    input=$(cat)

    local hook_message session_id transcript_path cwd
    hook_message=$(echo "$input" | jq -r '.message // ""' 2>/dev/null)
    session_id=$(echo "$input"   | jq -r '.session_id // ""' 2>/dev/null)
    transcript_path=$(echo "$input" | jq -r '.transcript_path // ""' 2>/dev/null)
    cwd=$(echo "$input" | jq -r '.cwd // ""' 2>/dev/null)

    [[ -z "$hook_message" ]] && hook_message="needs your attention"

    # Title: "<repo>: <hook message>" so the lock-screen line itself carries
    # both *which session* and *what state*. Falls back gracefully if either
    # piece is missing. App name (Pushover client) already shows "Claude Code".
    local repo title
    repo=$(repo_label "$cwd")
    if [[ -n "$repo" ]]; then
        title="$repo: $hook_message"
    else
        title="$hook_message"
    fi
    title=$(printf '%s' "$title" | cut -c1-80)

    # Body: the last assistant activity excerpt, if we can extract one.
    # If not, fall back to the hook message so the notification is not empty
    # (Pushover requires a non-empty message).
    local summary message
    summary=$(transcript_summary "$transcript_path")
    if [[ -n "$summary" ]]; then
        message="$summary"
    else
        message="$hook_message"
    fi

    # Cooldown logic:
    #   - different session within window -> deliver with sound (a new session
    #     is a new alert worth hearing)
    #   - same session within window      -> deliver silently (sound=none) so
    #     repeated prompts from one session do not spam audio
    #   - otherwise                       -> deliver with default sound
    local now last_sent last_session sound="" priority=""
    now=$(date +%s)
    last_sent=$(get_last_sent)
    last_session=$(get_last_session)

    if (( now - last_sent < QUIET_WINDOW_SEC )) \
        && [[ -n "$session_id" && "$session_id" == "$last_session" ]]; then
        sound="none"
        priority="-1"  # low priority: notification arrives, no sound/vibration
    fi

    set_last_sent "$now"
    [[ -n "$session_id" ]] && set_last_session "$session_id"

    local -a curl_args=(
        --form-string "token=$PUSHOVER_TOKEN"
        --form-string "user=$PUSHOVER_USER"
        --form-string "title=$title"
        --form-string "message=$message"
    )
    [[ -n "$sound"    ]] && curl_args+=(--form-string "sound=$sound")
    [[ -n "$priority" ]] && curl_args+=(--form-string "priority=$priority")

    curl -s --max-time 10 "${curl_args[@]}" \
        https://api.pushover.net/1/messages.json >/dev/null 2>&1 || true

    exit 0
}

case "${1:-}" in
    enable)  cmd_enable ;;
    disable) cmd_disable ;;
    toggle)  cmd_toggle ;;
    status)  cmd_status ;;
    send)    cmd_send ;;
    *)
        echo "Usage: $0 {enable|disable|toggle|status|send}" >&2
        exit 1
        ;;
esac
