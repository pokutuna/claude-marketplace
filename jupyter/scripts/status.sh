#!/usr/bin/env bash
set -euo pipefail

# Show current jupyter-mcp connection state: state file, tunnels, connectivity.
# Usage: status.sh

ENV_FILE="${JUPYTER_MCP_ENV_FILE:-$HOME/.config/jupyter-mcp/current.env}"
TUNNEL_DIR="${TMPDIR:-/tmp}/jupyter-mcp-tunnel"

echo "== state file ($ENV_FILE) =="
if [[ -f "$ENV_FILE" ]]; then
  sed -E 's/^([A-Z_]*TOKEN=).+/\1********/' "$ENV_FILE"
else
  echo "(not found)"
fi

echo "== ssh tunnels ($TUNNEL_DIR) =="
FOUND=0
for PID_FILE in "$TUNNEL_DIR"/port-*.pid; do
  [[ -e "$PID_FILE" ]] || continue
  FOUND=1
  PORT=$(basename "$PID_FILE" .pid); PORT=${PORT#port-}
  PID=$(cat "$PID_FILE")
  if kill -0 "$PID" 2>/dev/null; then
    echo "port $PORT: alive (pid $PID)"
  else
    echo "port $PORT: dead (stale pid file: $PID_FILE)"
  fi
done
[[ "$FOUND" == 0 ]] && echo "(none)"

echo "== connectivity =="
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  if [[ -n "${JUPYTER_URL:-}" ]]; then
    if curl -fsS --max-time 5 "$JUPYTER_URL/api" >/dev/null 2>&1; then
      echo "$JUPYTER_URL/api: reachable"
      AUTH_ARGS=()
      [[ -n "${JUPYTER_TOKEN:-}" ]] && AUTH_ARGS=(-H "Authorization: token $JUPYTER_TOKEN")
      if curl -fsS --max-time 5 "${AUTH_ARGS[@]}" "$JUPYTER_URL/api/kernels" >/dev/null 2>&1; then
        echo "$JUPYTER_URL/api/kernels: authorized"
      else
        echo "$JUPYTER_URL/api/kernels: unauthorized (check token)"
      fi
    else
      echo "$JUPYTER_URL/api: unreachable"
    fi
  else
    echo "(no JUPYTER_URL in state file)"
  fi
else
  echo "(no state file, skipped)"
fi
