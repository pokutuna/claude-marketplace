#!/usr/bin/env bash
# Launch codex exec detached from the caller's process group so that the
# Bash tool timeout (SIGKILL to the process group) cannot kill it.
# stdout (JSONL events) -> TRANSCRIPT_FILE, stderr -> LOG_FILE,
# exit code -> EXIT_FILE on completion. Prints the codex PID and returns.
set -u -m

result_file=$1
transcript_file=$2
shift 2

log_file="${transcript_file%.jsonl}.log"
exit_file="${transcript_file%.jsonl}.exit"

# Remove a stale exit file from a previous run so that resume with the same
# paths does not make the polling loop see completion immediately.
rm -f "$exit_file"

(
  codex exec --output-last-message "$result_file" "$@" </dev/null >>"$transcript_file" 2>>"$log_file"
  echo $? >"$exit_file"
) &
pid=$!
disown
echo "$pid"
