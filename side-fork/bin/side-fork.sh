#!/bin/bash
# side-fork.sh - Open a forked Claude session in a new tmux or screen window
#
# Usage:
#   side-fork.sh <session_id>

set -euo pipefail

get_session_cwd() {
    local config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
    local transcript
    transcript=$(find "${config_dir}/projects" -name "${1}.jsonl" 2>/dev/null | head -1)
    [[ -n "$transcript" ]] && grep -m1 '"cwd"' "$transcript" | jq -r '.cwd // empty'
}

detect_terminal() {
    [[ -n "${TMUX:-}" ]] && { echo tmux; return; }
    [[ -n "${STY:-}" ]]  && { echo screen; return; }
}

open_new_window() {
    case "$1" in
        tmux)   tmux new-window -c "$2" "$3" ;;
        screen) screen -X screen bash -c "cd '$2' && $3" ;;
    esac
}

SESSION_ID="${1:-}"
[[ -z "$SESSION_ID" ]] && { echo "Usage: side-fork.sh <session_id>" >&2; exit 1; }

TERMINAL=$(detect_terminal)
CWD=$(get_session_cwd "$SESSION_ID")
if [[ -z "$CWD" ]]; then
    echo "side-fork: transcript not found for session ${SESSION_ID}, falling back to current directory"
    CWD="$PWD"
fi

if [[ -z "$TERMINAL" ]]; then
    echo "side-fork: unsupported terminal (tmux or screen required)" >&2
    echo "Run manually: cd '$CWD' && claude --resume ${SESSION_ID} --fork-session" >&2
    exit 1
fi

BANNER="Forked from SessionID: ${SESSION_ID}\nTo resume the original: claude --resume ${SESSION_ID}"
open_new_window "$TERMINAL" "$CWD" "printf '%b\n' '${BANNER}' && claude --resume ${SESSION_ID} --fork-session"
