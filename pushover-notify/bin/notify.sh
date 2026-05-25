#!/bin/bash
# notify.sh - Pushover notification control for Claude Code
#
# Subcommands:
#   enable                       Enable hook notifications globally
#   disable                      Disable hook notifications globally
#   toggle                       Flip enabled/disabled
#   status                       Show current state
#   send [OPTIONS] [MESSAGE]     Send a notification now (skill / user / AI)
#   hook                         Hook mode: read JSON from stdin, apply
#                                enable/display/cooldown gates, then send
#
# `send` ignores the enable flag — it is an explicit action. `hook` is the
# gated entry point used by the Notification hook.
#
# State file (git-config format):
#   ${XDG_STATE_HOME:-~/.local/state}/claude-pushover-notify.conf
#     [global] enabled      = true|false
#     [global] last-sent    = <epoch>          # last hook send time (any session)
#     [global] last-session = <session-id>     # session that triggered last hook send
#
# Environment:
#   PUSHOVER_TOKEN  (required to actually send)
#   PUSHOVER_USER   (required to actually send)

set -uo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_FILE="$STATE_DIR/claude-pushover-notify.conf"
API_URL="https://api.pushover.net/1/messages.json"
# Within this window after the last hook send from the SAME session, the next
# hook notification is delivered silently (sound=none) instead of dropped.
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

parse_priority() {
    case "$1" in
        lowest|-2)    echo "-2" ;;
        low|-1)       echo "-1" ;;
        normal|0)     echo "0" ;;
        high|1)       echo "1" ;;
        emergency|2)  echo "2" ;;
        *)            echo "$1" ;;
    esac
}

# Core POST to Pushover API.
# Reads named globals: TITLE PRIORITY SOUND ATTACH URL URL_TITLE RETRY EXPIRE MESSAGE QUIET
# Returns 0 on API status:1, 1 otherwise.
pushover_post() {
    if ! check_credentials; then
        echo "Error: PUSHOVER_TOKEN and PUSHOVER_USER must be set" >&2
        return 1
    fi
    if [[ -z "${MESSAGE:-}" ]]; then
        echo "Error: empty message" >&2
        return 1
    fi

    local -a args=(
        --form-string "token=$PUSHOVER_TOKEN"
        --form-string "user=$PUSHOVER_USER"
        --form-string "message=$MESSAGE"
    )
    [[ -n "${TITLE:-}" ]]     && args+=(--form-string "title=$TITLE")
    [[ -n "${PRIORITY:-}" ]]  && args+=(--form-string "priority=$PRIORITY")
    [[ -n "${SOUND:-}" ]]     && args+=(--form-string "sound=$SOUND")
    [[ -n "${URL:-}" ]]       && args+=(--form-string "url=$URL")
    [[ -n "${URL_TITLE:-}" ]] && args+=(--form-string "url_title=$URL_TITLE")
    [[ -n "${RETRY:-}" ]]     && args+=(--form-string "retry=$RETRY")
    [[ -n "${EXPIRE:-}" ]]    && args+=(--form-string "expire=$EXPIRE")

    if [[ -n "${ATTACH:-}" ]]; then
        if [[ ! -f "$ATTACH" ]]; then
            echo "Error: attachment file not found: $ATTACH" >&2
            return 1
        fi
        args+=(-F "attachment=@$ATTACH")
    fi

    local response
    response=$(curl -s --max-time 10 "${args[@]}" "$API_URL")
    [[ "${QUIET:-0}" -eq 0 ]] && echo "$response"
    echo "$response" | grep -q '"status":1'
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
        echo "jq: missing (hook notifications will be skipped)"
    fi

    if command -v pmset >/dev/null 2>&1; then
        if is_display_on; then
            echo "Display: on (hook notifications skipped)"
        else
            echo "Display: off (hook notifications sent)"
        fi
    else
        echo "Display detection: unavailable (pmset not found, hook notifications always sent)"
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

send_usage() {
    cat <<'EOF'
Usage: notify.sh send [OPTIONS] [MESSAGE]

Send a Pushover notification immediately. Ignores the enable/disable flag —
this is an explicit action by the user or the AI.

Options:
  -t, --title TITLE         Notification title
  -p, --priority LEVEL      lowest | low | normal | high | emergency
                            or -2, -1, 0, 1, 2
  -s, --sound NAME          pushover, magic, siren, spacealarm, none, ...
  -a, --attach FILE         Attach an image file
  -u, --url URL             Supplementary URL (tap to open)
  -U, --url-title TITLE     Label for the supplementary URL
  -q, --quiet               Suppress API response output

Presets:
      --done MESSAGE        ✅ Done (priority=normal, sound=magic)
      --error MESSAGE       ⚠️ Error (priority=high, sound=siren)
      --emergency MESSAGE   🚨 Emergency (rings until acknowledged)

Stdin:
  If MESSAGE is omitted, the message is read from stdin.

Examples:
  notify.sh send "終わった"
  notify.sh send -t "ビルド" -p high "失敗しました"
  notify.sh send --done "学習完了"
  echo "$RESULT" | notify.sh send -t "結果"
EOF
}

cmd_send() {
    TITLE=""
    PRIORITY=""
    SOUND=""
    ATTACH=""
    URL=""
    URL_TITLE=""
    MESSAGE=""
    RETRY=""
    EXPIRE=""
    QUIET=0
    local preset=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--title)       TITLE="$2"; shift 2 ;;
            -p|--priority)    PRIORITY="$(parse_priority "$2")"; shift 2 ;;
            -s|--sound)       SOUND="$2"; shift 2 ;;
            -a|--attach)      ATTACH="$2"; shift 2 ;;
            -u|--url)         URL="$2"; shift 2 ;;
            -U|--url-title)   URL_TITLE="$2"; shift 2 ;;
            -q|--quiet)       QUIET=1; shift ;;
            --done)           preset="done";      MESSAGE="${2:-}"; shift 2 || shift ;;
            --error)          preset="error";     MESSAGE="${2:-}"; shift 2 || shift ;;
            --emergency)      preset="emergency"; MESSAGE="${2:-}"; shift 2 || shift ;;
            -h|--help)        send_usage; exit 0 ;;
            --)               shift; MESSAGE="$*"; break ;;
            -*)               echo "Unknown option: $1" >&2; send_usage >&2; exit 1 ;;
            *)                MESSAGE="$1"; shift ;;
        esac
    done

    case "$preset" in
        done)
            : "${TITLE:=✅ Done}"
            : "${PRIORITY:=0}"
            : "${SOUND:=magic}"
            ;;
        error)
            : "${TITLE:=⚠️ Error}"
            : "${PRIORITY:=1}"
            : "${SOUND:=siren}"
            ;;
        emergency)
            : "${TITLE:=🚨 Emergency}"
            PRIORITY="2"
            : "${SOUND:=persistent}"
            RETRY="60"
            EXPIRE="3600"
            ;;
    esac

    if [[ -z "$MESSAGE" ]]; then
        if [[ ! -t 0 ]]; then
            MESSAGE="$(cat)"
        else
            echo "Error: no message given" >&2
            send_usage >&2
            exit 1
        fi
    fi

    pushover_post
}

cmd_hook() {
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
    # both *which session* and *what state*. App name already shows "Claude Code".
    local repo
    repo=$(repo_label "$cwd")
    if [[ -n "$repo" ]]; then
        TITLE="$repo: $hook_message"
    else
        TITLE="$hook_message"
    fi
    TITLE=$(printf '%s' "$TITLE" | cut -c1-80)

    # Body: the last assistant activity excerpt, if we can extract one.
    # If not, fall back to the hook message so the notification is not empty.
    local summary
    summary=$(transcript_summary "$transcript_path")
    if [[ -n "$summary" ]]; then
        MESSAGE="$summary"
    else
        MESSAGE="$hook_message"
    fi

    # Cooldown logic:
    #   - different session within window -> deliver with sound
    #   - same session within window      -> deliver silently
    #   - otherwise                       -> deliver with default sound
    SOUND=""
    PRIORITY=""
    local now last_sent last_session
    now=$(date +%s)
    last_sent=$(get_last_sent)
    last_session=$(get_last_session)

    if (( now - last_sent < QUIET_WINDOW_SEC )) \
        && [[ -n "$session_id" && "$session_id" == "$last_session" ]]; then
        SOUND="none"
        PRIORITY="-1"
    fi

    set_last_sent "$now"
    [[ -n "$session_id" ]] && set_last_session "$session_id"

    ATTACH=""
    URL=""
    URL_TITLE=""
    RETRY=""
    EXPIRE=""
    QUIET=1

    pushover_post || true
    exit 0
}

case "${1:-}" in
    enable)  cmd_enable ;;
    disable) cmd_disable ;;
    toggle)  cmd_toggle ;;
    status)  cmd_status ;;
    send)    shift; cmd_send "$@" ;;
    hook)    cmd_hook ;;
    # Back-compat: previous hooks.json used `send` as the hook entry point.
    *)
        echo "Usage: $0 {enable|disable|toggle|status|send|hook}" >&2
        exit 1
        ;;
esac
