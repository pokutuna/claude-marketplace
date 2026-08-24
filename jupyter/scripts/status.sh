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

echo "== local doc server =="
bash "$(dirname "${BASH_SOURCE[0]}")/doc-server.sh" status

echo "== connectivity =="
check_server() {
  # $1 label, $2 url, $3 token, $4 probe path
  local label=$1 url=$2 token=$3 probe=$4
  local auth=()
  [[ -n "$token" ]] && auth=(-H "Authorization: token $token")
  if ! curl -fsS --max-time 5 "${auth[@]}" "$url/api" >/dev/null 2>&1; then
    echo "$label $url/api: unreachable"
    return
  fi
  if curl -fsS --max-time 5 "${auth[@]}" "$url$probe" >/dev/null 2>&1; then
    echo "$label $url$probe: authorized"
  else
    echo "$label $url$probe: unauthorized (check token)"
  fi
}

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  if [[ -n "${DOCUMENT_URL:-}" || -n "${CODE_SANDBOX_URL:-}" ]]; then
    echo "mode: hybrid (local documents, remote kernel)"
    [[ -n "${DOCUMENT_URL:-}" ]] &&
      check_server "documents:" "$DOCUMENT_URL" "${DOCUMENT_TOKEN:-}" "/api/contents"
    [[ -n "${CODE_SANDBOX_URL:-}" ]] &&
      check_server "kernels:  " "$CODE_SANDBOX_URL" "${CODE_SANDBOX_TOKEN:-}" "/api/kernels"
  elif [[ -n "${JUPYTER_URL:-}" ]]; then
    echo "mode: single server"
    check_server "jupyter:" "$JUPYTER_URL" "${JUPYTER_TOKEN:-}" "/api/kernels"
  else
    echo "(no server URL in state file)"
  fi
else
  echo "(no state file, skipped)"
fi
