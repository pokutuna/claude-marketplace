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
#     [global] enabled = true|false
#     [global] last-sent = <epoch>
#
# Environment:
#   PUSHOVER_TOKEN  (required for send/enable)
#   PUSHOVER_USER   (required for send/enable)

set -uo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_FILE="$STATE_DIR/claude-pushover-notify.conf"
COOLDOWN_SEC=60

ensure_state_dir() {
    mkdir -p "$STATE_DIR"
}

get_enabled() {
    git config -f "$CONFIG_FILE" global.enabled 2>/dev/null || echo "false"
}

set_enabled() {
    ensure_state_dir
    git config -f "$CONFIG_FILE" global.enabled "$1"
}

get_last_sent() {
    git config -f "$CONFIG_FILE" global.last-sent 2>/dev/null || echo "0"
}

set_last_sent() {
    ensure_state_dir
    git config -f "$CONFIG_FILE" global.last-sent "$1" 2>/dev/null || true
}

check_credentials() {
    [[ -n "${PUSHOVER_TOKEN:-}" && -n "${PUSHOVER_USER:-}" ]]
}

# Returns 0 (true) if display is on, 1 (false) if off or unknown.
# When pmset is unavailable (non-macOS), returns 1 so notifications are sent.
is_display_on() {
    command -v pmset >/dev/null 2>&1 || return 1
    local assertions
    assertions=$(pmset -g assertions 2>/dev/null) || return 1
    [[ "$assertions" == *"Prevent sleep while display is on"* ]]
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

    if command -v pmset >/dev/null 2>&1; then
        if is_display_on; then
            echo "Display: on (notifications skipped)"
        else
            echo "Display: off (notifications sent)"
        fi
    else
        echo "Display detection: unavailable (pmset not found, notifications always sent)"
    fi

    local last_sent
    last_sent=$(get_last_sent)
    if [[ "$last_sent" != "0" ]]; then
        local last_time
        last_time=$(date -r "$last_sent" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
            || date -d "@$last_sent" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
            || echo "$last_sent")
        echo "Last sent: $last_time"
    fi
}

cmd_send() {
    [[ "$(get_enabled)" == "true" ]] || exit 0
    check_credentials || exit 0
    ! is_display_on || exit 0

    local now last_sent
    now=$(date +%s)
    last_sent=$(get_last_sent)
    if (( now - last_sent < COOLDOWN_SEC )); then
        exit 0
    fi

    local input message
    input=$(cat)
    message=$(echo "$input" | jq -r '.message // "Claude Code needs your attention"' 2>/dev/null)
    [[ -z "$message" ]] && message="Claude Code needs your attention"

    set_last_sent "$now"

    curl -s --max-time 10 \
        --form-string "token=$PUSHOVER_TOKEN" \
        --form-string "user=$PUSHOVER_USER" \
        --form-string "title=Claude Code" \
        --form-string "message=$message" \
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
