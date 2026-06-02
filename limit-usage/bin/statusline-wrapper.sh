#!/bin/bash
# statusline-wrapper.sh - Tee statusLine stdin into a rate-state file, then pass it
#                         through to the user's original statusLine command unchanged.
#
# Overview:
#   Claude Code feeds the statusLine command a JSON blob on stdin that includes
#   `rate_limits` (5h / 7d usage %). This is the ONLY hook surface that receives it,
#   and it rides on the normal response — so capturing it here costs zero extra quota.
#
#   This wrapper:
#     1. reads stdin once
#     2. saves rate_limits + a capture timestamp into the rate-state file
#     3. replays the exact same stdin to the original statusLine command
#   stdout / stderr / exit code of the original command are passed through untouched.
#   If there is no original command, nothing is printed — a user who had no
#   statusLine keeps an empty one (Claude Code has no built-in default to fall back to).
#
# Rate-state file:
#   ${XDG_STATE_HOME:-~/.local/state}/cc-limit-usage-rate.json
#   {"rate_limits":{"five_hour":{"used_percentage":42,...},"seven_day":{...}},"ts":<epoch>}
#
# Usage (set by `guard.sh install` in settings.json statusLine.command):
#   statusline-wrapper.sh '<original statusLine command>'

set -uo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
RATE_FILE="$STATE_DIR/cc-limit-usage-rate.json"

input="$(cat)"

# Persist rate_limits verbatim plus a capture timestamp. Only overwrite when
# rate_limits is actually present (absent on free tier / before the first API
# response) so we don't clobber a still-valid snapshot with an empty one.
if command -v jq >/dev/null 2>&1; then
    mkdir -p "$STATE_DIR"
    snapshot="$(printf '%s' "$input" | jq -c 'select(.rate_limits) | {rate_limits, ts: now}' 2>/dev/null)"
    [[ -n "$snapshot" ]] && printf '%s\n' "$snapshot" > "$RATE_FILE"
fi

# Pass through to the original statusLine command, if any. No original → print
# nothing (an empty status line stays empty).
orig="${1:-}"
if [[ -n "$orig" ]]; then
    printf '%s' "$input" | sh -c "$orig"
fi
