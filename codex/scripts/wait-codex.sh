#!/usr/bin/env bash
# Wait for completion of a codex run launched by run-codex.sh.
# Usage: wait-codex.sh TRANSCRIPT_FILE [TIMEOUT_SECONDS]
# Polls until EXIT_FILE (${TRANSCRIPT_FILE%.jsonl}.exit) appears or
# TIMEOUT_SECONDS (default 300) elapses. Prints "EXIT <code>" on completion,
# "DEAD ..." when the codex process is gone without an exit code, or
# "RUNNING ..." with a transcript summary while codex is still working.
set -u

transcript_file=$1
timeout=${2:-300}
exit_file="${transcript_file%.jsonl}.exit"
pid_file="${transcript_file%.jsonl}.pid"

# GNU stat first (-c), then BSD stat (-f); GNU also accepts -f but treats it
# as a filesystem query, so the order matters.
mtime() {
  { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0; } | head -n 1
}

elapsed=0
while [ ! -f "$exit_file" ] && [ "$elapsed" -lt "$timeout" ]; do
  sleep 5
  elapsed=$((elapsed + 5))
done

if [ -f "$exit_file" ]; then
  echo "EXIT $(cat "$exit_file")"
  exit 0
fi

# The codex process died without writing an exit code (crash, kill -9,
# reboot). Report it so the poller stops looping and inspects LOG_FILE.
codex_pid=$(cat "$pid_file" 2>/dev/null || true)
if [ -n "$codex_pid" ] && ! kill -0 "$codex_pid" 2>/dev/null; then
  echo "DEAD (pid $codex_pid gone without exit code; check LOG_FILE and TRANSCRIPT_FILE tail)"
  exit 0
fi

# Keep the progress output tiny: this is read by an LLM on every poll, so it
# only needs enough signal to confirm forward progress. Report the completed
# event count, seconds since the last transcript/log write, plus a truncated
# view of the latest activity. item.started is dropped because item.completed
# already covers the same event.
last=$(mtime "$transcript_file")
log_last=$(mtime "${transcript_file%.jsonl}.log")
[ "$log_last" -gt "$last" ] && last=$log_last
age=$(( $(date +%s) - last ))
if command -v jq >/dev/null 2>&1; then
  done_count=$(grep -c '"type":"item.completed"' "$transcript_file" 2>/dev/null || echo 0)
  echo "RUNNING (${done_count} events done, last activity ${age}s ago)"
  tail -n 20 "$transcript_file" 2>/dev/null |
    jq -r 'select(.type == "item.completed")
           | [.item.type? // "event", (.item.command? // .item.text? // "" | tostring | gsub("\\s+"; " ") | .[0:60])]
           | map(select(. != "")) | join(" | ")' 2>/dev/null |
    tail -n 2
else
  echo "RUNNING (last activity ${age}s ago)"
  tail -n 2 "$transcript_file" 2>/dev/null | cut -c 1-100
fi
