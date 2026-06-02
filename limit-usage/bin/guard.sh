#!/bin/bash
# guard.sh - Stop tool execution before you exhaust your Claude rate limit.
#
# Reads usage captured by statusline-wrapper.sh (zero metering cost) and, from a
# PreToolUse hook, denies tool calls once a window passes the configured threshold.
#
# State files:
#   ${XDG_STATE_HOME:-~/.local/state}/cc-limit-usage-rate.json  - usage snapshot (written by wrapper)
#   ${XDG_STATE_HOME:-~/.local/state}/cc-limit-usage.conf        - thresholds (git-config format)
#
# Usage:
#   guard.sh check                    - Hook mode: read JSON from stdin, deny if over threshold
#   guard.sh set 5h 80 [--global]     - Set 5h window usage limit (%)
#   guard.sh set 7d 90 [--global]     - Set 7d window usage limit (%)
#   guard.sh off [5h|7d] [--global]   - Remove threshold(s) for this session (or --global)
#   guard.sh status                   - Show thresholds and current usage
#   guard.sh install '<orig command>' - Print before/after for wrapping statusLine (skill applies it)
#   guard.sh uninstall                - Print the saved original statusLine command to restore

set -uo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
RATE_FILE="$STATE_DIR/cc-limit-usage-rate.json"
CONFIG_FILE="$STATE_DIR/cc-limit-usage.conf"

# Usage snapshots older than this are ignored (fail-open). statusLine refreshes
# on every response and the wrapper rewrites the snapshot each time, so a stale
# snapshot means you simply haven't gotten a response recently — better to let
# the tool run than to block on old numbers.
STALE_SECONDS="${LIMIT_USAGE_STALE_SECONDS:-300}"

# Sentinel stored in orig-statusline when the user had no statusLine to wrap, so
# status/uninstall can tell "installed, nothing to restore" from "never installed".
NO_ORIG="(none)"

format_time() {
    date -r "$1" '+%H:%M' 2>/dev/null || date -d "@$1" '+%H:%M'
}

cfg_get() {
    git config -f "$CONFIG_FILE" "$1" 2>/dev/null || true
}

window_key() {
    case "$1" in
        5h|five-hour|five_hour) echo "five-hour" ;;
        7d|seven-day|seven_day) echo "seven-day" ;;
        *) echo "" ;;
    esac
}

# Resolve a threshold for a window: session.<id> -> global -> empty.
resolve_limit() {
    local val=""
    [[ -n "${CLAUDE_SESSION_ID:-}" ]] && val="$(cfg_get "session.${CLAUDE_SESSION_ID}.$1")"
    [[ -z "$val" ]] && val="$(cfg_get "global.$1")"
    echo "$val"
}

check() {
    # Fail-open: no jq, or no snapshot yet (free tier / before first API response).
    command -v jq >/dev/null 2>&1 || exit 0
    [[ -f "$RATE_FILE" ]] || exit 0

    # One jq over stdin for both the session id and the command being run.
    local cmd
    IFS=$'\t' read -r CLAUDE_SESSION_ID cmd < <(
        jq -r '[.session_id // "", .tool_input.command // ""] | @tsv' 2>/dev/null)
    export CLAUDE_SESSION_ID

    # Never block this plugin's own management commands. Otherwise tripping the
    # guard would block set/off/status too — the commands needed to recover.
    [[ "$cmd" == *"guard.sh"* ]] && exit 0

    local five seven five_reset seven_reset ts
    IFS=$'\t' read -r five seven five_reset seven_reset ts < <(
        jq -r '.rate_limits as $r | [$r.five_hour.used_percentage, $r.seven_day.used_percentage, $r.five_hour.resets_at, $r.seven_day.resets_at, .ts] | @tsv' "$RATE_FILE" 2>/dev/null)

    # Fail-open: snapshot too old to trust.
    [[ -n "$ts" && "$ts" != "null" ]] && (( $(date +%s) - ${ts%.*} > STALE_SECONDS )) && exit 0

    local five_limit seven_limit
    five_limit="$(resolve_limit five-hour)"
    seven_limit="$(resolve_limit seven-day)"

    # awk for float-safe >= ; deny on the first window over its limit. Skip a
    # window unless both used and limit are plain numbers (fail-open on garbage).
    local num='^[0-9]+([.][0-9]+)?$'
    if [[ "$five" =~ $num && "$five_limit" =~ $num ]] && awk -v u="$five" -v l="$five_limit" 'BEGIN{exit !(u>=l)}'; then
        deny "5h" "$five" "$five_limit" "$five_reset"
    elif [[ "$seven" =~ $num && "$seven_limit" =~ $num ]] && awk -v u="$seven" -v l="$seven_limit" 'BEGIN{exit !(u>=l)}'; then
        deny "7d" "$seven" "$seven_limit" "$seven_reset"
    fi
    exit 0
}

deny() {
    local label="$1" used="$2" limit="$3" reset="$4" resets=""
    [[ -n "$reset" && "$reset" != "null" ]] && resets=" Resets at $(format_time "${reset%.*}")."
    local reason
    reason="$(printf '%s usage %.0f%% >= limit %.0f%%. Stopped by limit-usage.%s' "$label" "$used" "$limit" "$resets")"
    jq -nc --arg r "$reason" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
}

# Where set/off write: --global, else this session, else global (so it still works).
target_section() {
    if [[ "$1" == global ]]; then
        echo "global"
    elif [[ -n "${CLAUDE_SESSION_ID:-}" ]]; then
        echo "session.${CLAUDE_SESSION_ID}"
    else
        echo "global"
    fi
}

set_limit() {
    local scope=session win="" pct=""
    for a in "$@"; do
        case "$a" in
            --global) scope=global ;;
            *) [[ -z "$win" ]] && win="$a" || pct="$a" ;;
        esac
    done

    local key
    key="$(window_key "$win")"
    [[ -z "$key" ]] && { echo "Error: window must be 5h or 7d (got '${win}')" >&2; exit 1; }
    pct="${pct%\%}"
    [[ "$pct" =~ ^[0-9]+([.][0-9]+)?$ ]] || { echo "Error: percent must be a number (got '${pct}')" >&2; exit 1; }

    local section
    section="$(target_section "$scope")"
    mkdir -p "$STATE_DIR"
    git config -f "$CONFIG_FILE" "${section}.${key}" "$pct"
    echo "Set ${win} limit to ${pct}% (${scope})."
}

off_limit() {
    local scope=session win=""
    for a in "$@"; do
        case "$a" in
            --global) scope=global ;;
            *) win="$a" ;;
        esac
    done

    local section
    section="$(target_section "$scope")"

    if [[ -z "$win" ]]; then
        git config -f "$CONFIG_FILE" --unset "${section}.five-hour" 2>/dev/null || true
        git config -f "$CONFIG_FILE" --unset "${section}.seven-day" 2>/dev/null || true
        echo "Cleared 5h and 7d limits (${scope})."
        return
    fi
    local key
    key="$(window_key "$win")"
    [[ -z "$key" ]] && { echo "Error: window must be 5h or 7d (got '${win}')" >&2; exit 1; }
    git config -f "$CONFIG_FILE" --unset "${section}.${key}" 2>/dev/null || true
    echo "Cleared ${win} limit (${scope})."
}

status() {
    local fl sl
    fl="$(resolve_limit five-hour)"
    sl="$(resolve_limit seven-day)"
    echo "limit-usage status"
    echo ""
    echo "Thresholds (effective: session -> global):"
    echo "  5h limit: ${fl:-(not set)}${fl:+%}"
    echo "  7d limit: ${sl:-(not set)}${sl:+%}"
    echo ""
    echo "Current usage:"
    if [[ -f "$RATE_FILE" ]] && command -v jq >/dev/null 2>&1; then
        local five seven ts
        IFS=$'\t' read -r five seven ts < <(jq -r '.rate_limits as $r | [$r.five_hour.used_percentage // "?", $r.seven_day.used_percentage // "?", .ts] | @tsv' "$RATE_FILE" 2>/dev/null)
        echo "  5h used: ${five}%"
        echo "  7d used: ${seven}%"
        if [[ -n "$ts" && "$ts" != "null" ]]; then
            local age=$(( $(date +%s) - ${ts%.*} ))
            echo "  snapshot age: ${age}s$( (( age > STALE_SECONDS )) && echo ' (STALE — guard fails open)')"
        fi
    else
        echo "  (no snapshot yet — run install and let one response go by)"
    fi
    echo ""
    local orig
    orig="$(cfg_get "global.orig-statusline")"
    if [[ -z "$orig" ]]; then
        echo "statusLine wrapper: not installed (run /limit-usage install)"
    elif [[ "$orig" == "$NO_ORIG" ]]; then
        echo "statusLine wrapper: installed (no original to restore)"
    else
        echo "statusLine wrapper: installed (original saved: ${orig})"
    fi
}

# install/uninstall print machine-readable plans; the skill applies the
# settings.json edit after user consent (the plugin never writes it directly).

install() {
    local orig="${1:-}"

    if [[ "$orig" == *"statusline-wrapper.sh"* ]]; then
        echo "ALREADY_WRAPPED"
        echo "current: $orig"
        return
    fi

    # statusLine can't expand ${CLAUDE_PLUGIN_ROOT}, and the cache path is
    # versioned (breaks on update). Copy the wrapper into CLAUDE_PLUGIN_DATA —
    # a version-stable dir — and bake that path. Re-run install after an update
    # to refresh the copy.
    local src="${CLAUDE_PLUGIN_ROOT:-}/bin/statusline-wrapper.sh"
    if [[ -z "${CLAUDE_PLUGIN_DATA:-}" || ! -f "$src" ]]; then
        echo "ERROR: CLAUDE_PLUGIN_DATA unset or wrapper not found at ${src}" >&2
        exit 1
    fi
    local wrapper="$CLAUDE_PLUGIN_DATA/statusline-wrapper.sh"
    mkdir -p "$CLAUDE_PLUGIN_DATA" "$STATE_DIR"
    cp "$src" "$wrapper"
    chmod +x "$wrapper"

    if [[ -n "$orig" ]]; then
        git config -f "$CONFIG_FILE" "global.orig-statusline" "$orig"
        # Single-quote orig for the shell, escaping any embedded quotes.
        echo "before: $orig"
        echo "after:  ${wrapper} '${orig//\'/\'\\\'\'}'"
    else
        git config -f "$CONFIG_FILE" "global.orig-statusline" "$NO_ORIG"
        echo "before: (none)"
        echo "after:  ${wrapper}"
    fi
}

uninstall() {
    local orig
    orig="$(cfg_get "global.orig-statusline")"
    git config -f "$CONFIG_FILE" --unset "global.orig-statusline" 2>/dev/null || true
    [[ -n "${CLAUDE_PLUGIN_DATA:-}" ]] && rm -f "$CLAUDE_PLUGIN_DATA/statusline-wrapper.sh"
    if [[ -z "$orig" || "$orig" == "$NO_ORIG" ]]; then
        echo "RESTORE_REMOVE"
        echo "(no original statusLine was saved; remove the wrapper command entirely)"
    else
        echo "RESTORE_TO"
        echo "$orig"
    fi
}

case "${1:-check}" in
    check)     check ;;
    set)       shift; set_limit "$@" ;;
    off)       shift; off_limit "$@" ;;
    status)    status ;;
    install)   shift; install "$@" ;;
    uninstall) uninstall ;;
    *)
        echo "Usage: $0 {check|set 5h|7d N [--global]|off [5h|7d] [--global]|status|install <cmd>|uninstall}" >&2
        exit 1
        ;;
esac
