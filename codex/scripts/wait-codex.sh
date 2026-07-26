#!/usr/bin/env bash
# Wait for completion of a codex run launched by run-codex.sh.
# Usage: wait-codex.sh TRANSCRIPT_FILE [TIMEOUT_SECONDS]
# Polls until EXIT_FILE (${TRANSCRIPT_FILE%.jsonl}.exit) appears or
# TIMEOUT_SECONDS (default 300) elapses. Prints "EXIT <code>" on completion,
# or "RUNNING" followed by the transcript tail while codex is still working.
set -u

transcript_file=$1
timeout=${2:-300}
exit_file="${transcript_file%.jsonl}.exit"

elapsed=0
while [ ! -f "$exit_file" ] && [ "$elapsed" -lt "$timeout" ]; do
  sleep 5
  elapsed=$((elapsed + 5))
done

if [ -f "$exit_file" ]; then
  echo "EXIT $(cat "$exit_file")"
else
  # Keep the progress output tiny: this is read by an LLM on every poll, so it
  # only needs enough signal to confirm forward progress. Report the completed
  # event count plus a truncated view of the latest activity. item.started is
  # dropped because item.completed already covers the same event.
  if command -v jq >/dev/null 2>&1; then
    done_count=$(grep -c '"type":"item.completed"' "$transcript_file" 2>/dev/null || echo 0)
    echo "RUNNING (${done_count} events done)"
    tail -n 20 "$transcript_file" 2>/dev/null |
      jq -r 'select(.type == "item.completed")
             | [.item.type? // "event", (.item.command? // .item.text? // "" | tostring | gsub("\\s+"; " ") | .[0:60])]
             | map(select(. != "")) | join(" | ")' 2>/dev/null |
      tail -n 2
  else
    echo "RUNNING"
    tail -n 2 "$transcript_file" 2>/dev/null | cut -c 1-100
  fi
fi
