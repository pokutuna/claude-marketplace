#!/usr/bin/env bash
# Wait for completion of a codex run launched by run-codex.sh.
# Usage: wait-codex.sh TRANSCRIPT_FILE [TIMEOUT_SECONDS]
# Polls until EXIT_FILE (${TRANSCRIPT_FILE%.jsonl}.exit) appears or
# TIMEOUT_SECONDS (default 120) elapses. Prints "EXIT <code>" on completion,
# or "RUNNING" followed by the transcript tail while codex is still working.
set -u

transcript_file=$1
timeout=${2:-120}
exit_file="${transcript_file%.jsonl}.exit"

elapsed=0
while [ ! -f "$exit_file" ] && [ "$elapsed" -lt "$timeout" ]; do
  sleep 5
  elapsed=$((elapsed + 5))
done

if [ -f "$exit_file" ]; then
  echo "EXIT $(cat "$exit_file")"
else
  echo "RUNNING"
  tail -n 5 "$transcript_file" 2>/dev/null
fi
