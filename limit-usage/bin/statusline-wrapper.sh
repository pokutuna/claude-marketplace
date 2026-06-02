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
#     2. extracts rate_limits + a capture timestamp into the rate-state file
#     3. replays the exact same stdin to the original statusLine command
#   stdout / stderr / exit code of the original command are passed through untouched.
#
# Rate-state file:
#   ${XDG_STATE_HOME:-~/.local/state}/limit-usage-rate.json
#   {"five_h":42,"seven_d":18,"five_reset":1780417800,"seven_reset":...,"ts":<epoch>}
#
# Usage (set by `guard.sh setup` in settings.json statusLine.command):
#   statusline-wrapper.sh '<original statusLine command>'
#
#   If no original command is given (user had no statusLine), prints a minimal
#   `5h: 42% | 7d: 18%` line itself so the status line is not blank.

set -uo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
RATE_FILE="$STATE_DIR/limit-usage-rate.json"

# Read all of stdin once.
input="$(cat)"

# Persist rate_limits if present. jq writes the state file only when at least one
# window carries a used_percentage; otherwise (free tier / before first API
# response) we leave the previous state untouched.
if command -v jq >/dev/null 2>&1; then
    mkdir -p "$STATE_DIR"
    printf '%s' "$input" | jq -c '
        (.rate_limits // {}) as $r
        | {
            five_h:      ($r.five_hour.used_percentage // null),
            seven_d:     ($r.seven_day.used_percentage // null),
            five_reset:  ($r.five_hour.resets_at // null),
            seven_reset: ($r.seven_day.resets_at // null),
            ts:          now
          }
        | select(.five_h != null or .seven_d != null)
    ' > "$RATE_FILE.tmp" 2>/dev/null

    if [[ -s "$RATE_FILE.tmp" ]]; then
        mv -f "$RATE_FILE.tmp" "$RATE_FILE"
    else
        rm -f "$RATE_FILE.tmp"
    fi
fi

# Pass through to the original statusLine command, if any.
orig="${1:-}"
if [[ -n "$orig" ]]; then
    # Expand a leading literal ~ to $HOME so paths like "~/.claude/statusline.ts" work.
    # shellcheck disable=SC2088  # matching a literal "~/" prefix, not expecting expansion
    case "$orig" in
        "~/"*) orig="$HOME/${orig#\~/}" ;;
    esac
    # Replay the captured stdin to the original command and adopt its exit code.
    # (Cannot `exec` here: the pipeline would only replace the subshell, leaving
    # the parent script to fall through to the minimal-line block below.)
    printf '%s' "$input" | sh -c "$orig"
    exit $?
fi

# No original command: emit a minimal status line so it is not blank.
if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r '
        (.rate_limits // {}) as $r
        | [ ($r.five_hour.used_percentage  | if . == null then empty else "5h: \(. | floor)%" end),
            ($r.seven_day.used_percentage   | if . == null then empty else "7d: \(. | floor)%" end) ]
        | if length == 0 then "" else join(" | ") end
    '
fi
