#!/usr/bin/env bash
# Play a bell sound corresponding to the current tmux window index.
# Falls back to bell_0.wav if not in tmux or index out of range.
# Supports macOS (afplay) and Linux (paplay, aplay, pw-play).

set -euo pipefail

SOUNDS_DIR="$(cd "$(dirname "$0")/../sounds" && pwd)"
MAX_INDEX=21

# Determine tmux window index
if command -v tmux &>/dev/null && [ -n "${TMUX:-}" ] && [ -n "${TMUX_PANE:-}" ]; then
    INDEX=$(tmux display-message -t "$TMUX_PANE" -p '#{window_index}')
else
    INDEX=0
fi

# Clamp to valid range
if [ "$INDEX" -gt "$MAX_INDEX" ] 2>/dev/null; then
    INDEX=$MAX_INDEX
fi

WAV="${SOUNDS_DIR}/bell_${INDEX}.wav"
if [ ! -f "$WAV" ]; then
    WAV="${SOUNDS_DIR}/bell_0.wav"
fi

# Play with available command
if command -v afplay &>/dev/null; then
    afplay "$WAV" &
elif command -v paplay &>/dev/null; then
    paplay "$WAV" &
elif command -v pw-play &>/dev/null; then
    pw-play "$WAV" &
elif command -v aplay &>/dev/null; then
    aplay -q "$WAV" &
fi
