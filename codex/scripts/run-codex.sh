#!/usr/bin/env bash
# Launch codex exec detached from the caller's process group so that the
# Bash tool timeout (SIGKILL to the process group) cannot kill it.
# stdout (JSONL events) -> TRANSCRIPT_FILE, stderr -> LOG_FILE,
# exit code -> EXIT_FILE on completion, codex PID -> PID_FILE.
# Prints the launcher PID and returns.
#
# A watchdog kills codex when the transcript/log show no activity for
# CODEX_STALL_LIMIT seconds (default 1200) or the run exceeds
# CODEX_MAX_RUNTIME seconds (default 5400), then EXIT_FILE records the
# non-zero code so pollers never wait forever.
set -u -m

result_file=$1
transcript_file=$2
shift 2

log_file="${transcript_file%.jsonl}.log"
exit_file="${transcript_file%.jsonl}.exit"
pid_file="${transcript_file%.jsonl}.pid"

stall_limit=${CODEX_STALL_LIMIT:-1200}
max_runtime=${CODEX_MAX_RUNTIME:-5400}
# Non-numeric values would break the watchdog arithmetic and silently disable
# both limits, so fall back to the defaults.
case $stall_limit in '' | *[!0-9]*) stall_limit=1200 ;; esac
case $max_runtime in '' | *[!0-9]*) max_runtime=5400 ;; esac

# Remove a stale exit file from a previous run so that resume with the same
# paths does not make the polling loop see completion immediately.
rm -f "$exit_file"

# GNU stat first (-c), then BSD stat (-f); GNU also accepts -f but treats it
# as a filesystem query, so the order matters.
mtime() {
  { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0; } | head -n 1
}

(
  codex exec --output-last-message "$result_file" "$@" </dev/null >>"$transcript_file" 2>>"$log_file" &
  codex_pid=$!
  echo "$codex_pid" >"$pid_file"

  (
    # Kill the whole process group (job control gives codex its own) so that
    # shell commands codex spawned die with it; fall back to the leader pid.
    kill_codex() {
      echo "watchdog: $1, killing codex (pid $codex_pid)" >>"$log_file"
      kill -- "-$codex_pid" 2>/dev/null || kill "$codex_pid" 2>/dev/null
      sleep 5
      kill -9 -- "-$codex_pid" 2>/dev/null || kill -9 "$codex_pid" 2>/dev/null
    }
    start=$(date +%s)
    while kill -0 "$codex_pid" 2>/dev/null; do
      sleep 15
      now=$(date +%s)
      last=$(mtime "$transcript_file")
      log_last=$(mtime "$log_file")
      [ "$log_last" -gt "$last" ] && last=$log_last
      [ "$last" -eq 0 ] && last=$start
      if [ $((now - last)) -ge "$stall_limit" ]; then
        kill_codex "no activity for ${stall_limit}s"
        break
      fi
      if [ $((now - start)) -ge "$max_runtime" ]; then
        kill_codex "exceeded max runtime ${max_runtime}s"
        break
      fi
    done
  ) &
  watchdog_pid=$!

  wait "$codex_pid"
  code=$?
  kill "$watchdog_pid" 2>/dev/null
  echo "$code" >"$exit_file"
) </dev/null >/dev/null 2>&1 &
pid=$!
disown
echo "$pid"
