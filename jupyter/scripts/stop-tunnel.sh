#!/usr/bin/env bash
set -euo pipefail

# Stop SSH tunnel(s) started by setup-tunnel.sh.
# Usage: stop-tunnel.sh [port|all]   (default: all)

TARGET=${1:-all}
STATE_DIR="${TMPDIR:-/tmp}/jupyter-mcp-tunnel"

STOPPED=0
for PID_FILE in "$STATE_DIR"/port-*.pid; do
  [[ -e "$PID_FILE" ]] || continue
  PORT=$(basename "$PID_FILE" .pid); PORT=${PORT#port-}
  if [[ "$TARGET" != "all" && "$TARGET" != "$PORT" ]]; then
    continue
  fi
  PID=$(cat "$PID_FILE")
  if kill -0 "$PID" 2>/dev/null; then
    kill "$PID" 2>/dev/null || true
    echo "stopped tunnel on port $PORT (pid $PID)"
    STOPPED=1
  else
    echo "removed stale pid file for port $PORT"
  fi
  rm -f "$PID_FILE" "$STATE_DIR/port-$PORT.log"
done

[[ "$STOPPED" == 0 ]] && echo "no running tunnel matched '$TARGET'"
exit 0
