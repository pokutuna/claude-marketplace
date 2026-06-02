#!/bin/bash
# guard.sh - Stop tool execution before you exhaust your Claude rate limit.
#
# Reads usage captured by statusline-wrapper.sh (zero metering cost) and, from a
# PreToolUse hook, denies tool calls once a window passes the configured threshold.
#
# State files:
#   ${XDG_STATE_HOME:-~/.local/state}/limit-usage-rate.json  - usage snapshot (written by wrapper)
#   ${XDG_STATE_HOME:-~/.local/state}/limit-usage.conf        - thresholds (git-config format)
#
# Usage:
#   guard.sh check                  - Hook mode: read JSON from stdin, deny if over threshold
#   guard.sh set 5h 80 [--global]   - Set 5h window usage limit (%)
#   guard.sh set 7d 90 [--global]   - Set 7d window usage limit (%)
#   guard.sh off [5h|7d] [--global] - Remove threshold(s) for this session (or --global)
#   guard.sh status                 - Show thresholds and current usage
#   guard.sh setup '<orig command>' - Print before/after for wrapping statusLine (skill applies it)
#   guard.sh teardown               - Print the saved original statusLine command to restore

set -uo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
RATE_FILE="$STATE_DIR/limit-usage-rate.json"
CONFIG_FILE="$STATE_DIR/limit-usage.conf"

# Usage snapshots older than this are ignored (fail-open). statusLine refreshes
# on every response and on refreshInterval, so a stale snapshot means the data is
# unreliable; better to let the tool run than to block on old numbers.
STALE_SECONDS="${LIMIT_USAGE_STALE_SECONDS:-1800}"

# ---- helpers ----------------------------------------------------------------

format_time() {
    local epoch="$1"
    date -r "$epoch" '+%H:%M' 2>/dev/null || date -d "@$epoch" '+%H:%M'
}

cfg_get() {
    git config -f "$CONFIG_FILE" "$1" 2>/dev/null || true
}

cfg_set() {
    mkdir -p "$STATE_DIR"
    git config -f "$CONFIG_FILE" "$1" "$2"
}

cfg_unset() {
    git config -f "$CONFIG_FILE" --unset "$1" 2>/dev/null || true
}

# Normalize a window argument to the config key suffix.
window_key() {
    case "$1" in
        5h|five-hour|five_hour) echo "five-hour" ;;
        7d|seven-day|seven_day) echo "seven-day" ;;
        *) echo "" ;;
    esac
}

# Resolve a threshold for a window: session.<id> -> global -> empty.
resolve_limit() {
    local key="$1" val=""
    if [[ -n "${CLAUDE_SESSION_ID:-}" ]]; then
        val="$(cfg_get "session.${CLAUDE_SESSION_ID}.${key}")"
    fi
    if [[ -z "$val" ]]; then
        val="$(cfg_get "global.${key}")"
    fi
    echo "$val"
}

# ---- check (hook mode) ------------------------------------------------------

check() {
    local input
    input="$(cat)"

    CLAUDE_SESSION_ID="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)"
    export CLAUDE_SESSION_ID

    # Fail-open: never block this plugin's own management commands (guard.sh ...).
    # Otherwise tripping the guard would also block set/off/status/teardown — the
    # very commands needed to recover — leaving the session deadlocked.
    local cmd
    cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
    if [[ "$cmd" == *"guard.sh"* ]]; then
        exit 0
    fi

    # Fail-open: no usage snapshot yet (free tier / before first API response).
    [[ -f "$RATE_FILE" ]] || exit 0
    command -v jq >/dev/null 2>&1 || exit 0

    local five seven five_reset seven_reset ts now
    five="$(jq -r '.five_h // empty' "$RATE_FILE" 2>/dev/null)"
    seven="$(jq -r '.seven_d // empty' "$RATE_FILE" 2>/dev/null)"
    five_reset="$(jq -r '.five_reset // empty' "$RATE_FILE" 2>/dev/null)"
    seven_reset="$(jq -r '.seven_reset // empty' "$RATE_FILE" 2>/dev/null)"
    ts="$(jq -r '.ts // empty' "$RATE_FILE" 2>/dev/null)"

    # Fail-open: snapshot too old to trust.
    now="$(date +%s)"
    if [[ -n "$ts" ]]; then
        # ts may be a float (jq `now`); compare as integer seconds.
        local ts_int=${ts%.*}
        if (( now - ts_int > STALE_SECONDS )); then
            exit 0
        fi
    fi

    local five_limit seven_limit
    five_limit="$(resolve_limit five-hour)"
    seven_limit="$(resolve_limit seven-day)"

    # Compare using awk for float-safe >= ; emit reason and deny on first breach.
    if [[ -n "$five_limit" && -n "$five" ]] && awk "BEGIN{exit !($five >= $five_limit)}"; then
        deny "5h" "$five" "$five_limit" "$five_reset"
        exit 0
    fi
    if [[ -n "$seven_limit" && -n "$seven" ]] && awk "BEGIN{exit !($seven >= $seven_limit)}"; then
        deny "7d" "$seven" "$seven_limit" "$seven_reset"
        exit 0
    fi

    # Under all configured thresholds (or none set): allow normally.
    exit 0
}

deny() {
    local label="$1" used="$2" limit="$3" reset="$4"
    local used_disp limit_disp reason resets=""
    used_disp="$(awk "BEGIN{printf \"%.0f\", $used}")"
    limit_disp="$(awk "BEGIN{printf \"%.0f\", $limit}")"
    if [[ -n "$reset" && "$reset" != "null" ]]; then
        resets=" Resets at $(format_time "${reset%.*}")."
    fi
    reason="${label} usage ${used_disp}% >= limit ${limit_disp}%. Stopped by limit-usage.${resets}"

    jq -nc --arg r "$reason" '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: $r
        }
    }'
}

# ---- set / off --------------------------------------------------------------

# Parse trailing --global from args, set GLOBAL=1, strip it from positionals.
GLOBAL=0
strip_global() {
    local out=()
    for a in "$@"; do
        if [[ "$a" == "--global" ]]; then
            GLOBAL=1
        else
            out+=("$a")
        fi
    done
    # Assign without "${out[@]}" expansion of a possibly-empty array (set -u safe).
    ARGS=()
    if [[ ${#out[@]} -gt 0 ]]; then
        ARGS=("${out[@]}")
    fi
}

target_section() {
    if [[ "$GLOBAL" -eq 1 ]]; then
        echo "global"
    elif [[ -n "${CLAUDE_SESSION_ID:-}" ]]; then
        echo "session.${CLAUDE_SESSION_ID}"
    else
        # No session id and not --global: fall back to global so `set` still works.
        echo "global"
    fi
}

set_limit() {
    strip_global "$@"
    local win="${ARGS[0]:-}" pct="${ARGS[1]:-}"
    local key
    key="$(window_key "$win")"
    if [[ -z "$key" ]]; then
        echo "Error: window must be 5h or 7d (got '${win}')" >&2
        exit 1
    fi
    # Accept "80" or "80%".
    pct="${pct%\%}"
    if ! [[ "$pct" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        echo "Error: percent must be a number (got '${pct:-}')" >&2
        exit 1
    fi
    local section
    section="$(target_section)"
    cfg_set "${section}.${key}" "$pct"
    local scope="session"
    [[ "$section" == "global" ]] && scope="global"
    echo "Set ${win} limit to ${pct}% (${scope})."
}

off_limit() {
    strip_global "$@"
    local win="${ARGS[0]:-}"
    local section
    section="$(target_section)"
    local scope="session"
    [[ "$section" == "global" ]] && scope="global"

    if [[ -z "$win" ]]; then
        cfg_unset "${section}.five-hour"
        cfg_unset "${section}.seven-day"
        echo "Cleared 5h and 7d limits (${scope})."
        return
    fi
    local key
    key="$(window_key "$win")"
    if [[ -z "$key" ]]; then
        echo "Error: window must be 5h or 7d (got '${win}')" >&2
        exit 1
    fi
    cfg_unset "${section}.${key}"
    echo "Cleared ${win} limit (${scope})."
}

# ---- status -----------------------------------------------------------------

status() {
    echo "limit-usage status"
    echo ""
    echo "Thresholds (effective: session -> global):"
    local fl sl
    fl="$(resolve_limit five-hour)"
    sl="$(resolve_limit seven-day)"
    echo "  5h limit: ${fl:-(not set)}${fl:+%}"
    echo "  7d limit: ${sl:-(not set)}${sl:+%}"

    echo ""
    echo "Current usage:"
    if [[ -f "$RATE_FILE" ]] && command -v jq >/dev/null 2>&1; then
        local five seven ts now age
        five="$(jq -r '.five_h // "?"' "$RATE_FILE" 2>/dev/null)"
        seven="$(jq -r '.seven_d // "?"' "$RATE_FILE" 2>/dev/null)"
        ts="$(jq -r '.ts // empty' "$RATE_FILE" 2>/dev/null)"
        echo "  5h used: ${five}%"
        echo "  7d used: ${seven}%"
        if [[ -n "$ts" ]]; then
            now="$(date +%s)"
            age=$(( now - ${ts%.*} ))
            echo "  snapshot age: ${age}s$( (( age > STALE_SECONDS )) && echo ' (STALE — guard fails open)')"
        fi
    else
        echo "  (no snapshot yet — run setup and let one response go by)"
    fi

    local orig
    orig="$(cfg_get "global.orig-statusline")"
    echo ""
    if [[ -n "$orig" ]]; then
        echo "statusLine wrapper: installed (original saved: ${orig})"
    else
        echo "statusLine wrapper: not installed (run /limit-usage setup)"
    fi
}

# ---- setup / teardown -------------------------------------------------------
# These print machine-readable plans; the skill applies the settings.json edit
# after user consent (the plugin never writes settings.json on its own).

setup() {
    local orig="${1:-}"
    local wrapper="${CLAUDE_PLUGIN_ROOT:-}/bin/statusline-wrapper.sh"
    mkdir -p "$STATE_DIR"

    # Idempotent: if the current command already points at our wrapper, do nothing.
    if [[ -n "$orig" && "$orig" == *"statusline-wrapper.sh"* ]]; then
        echo "ALREADY_WRAPPED"
        echo "current: $orig"
        return
    fi

    # Save original for teardown (only if not already wrapped).
    if [[ -n "$orig" ]]; then
        cfg_set "global.orig-statusline" "$orig"
        echo "before: $orig"
        echo "after:  ${wrapper} '${orig}'"
    else
        cfg_set "global.orig-statusline" ""
        echo "before: (none)"
        echo "after:  ${wrapper}"
    fi
}

teardown() {
    local orig
    orig="$(cfg_get "global.orig-statusline")"
    if [[ -z "$orig" ]]; then
        echo "RESTORE_REMOVE"
        echo "(no original statusLine was saved; remove the wrapper command entirely)"
    else
        echo "RESTORE_TO"
        echo "$orig"
    fi
    cfg_unset "global.orig-statusline"
}

# ---- dispatch ---------------------------------------------------------------

case "${1:-check}" in
    check)    check ;;
    set)      shift; set_limit "$@" ;;
    off)      shift; off_limit "$@" ;;
    status)   status ;;
    setup)    shift; setup "$@" ;;
    teardown) teardown ;;
    *)
        echo "Usage: $0 {check|set 5h|7d N [--global]|off [5h|7d] [--global]|status|setup <cmd>|teardown}" >&2
        exit 1
        ;;
esac
