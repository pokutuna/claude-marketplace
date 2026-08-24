#!/usr/bin/env bash
set -euo pipefail

# Start/stop the local document server used by the hybrid setup
# (local notebooks, remote kernel).
#
# Usage:
#   doc-server.sh start [root_dir] [port]
#   doc-server.sh stop
#   doc-server.sh status
#
# The server is a plain jupyter-server with jupyter-collaboration, run through
# uvx so it needs no local venv. jupyter-mcp-server talks to it for all
# document operations (DOCUMENT_URL) while kernels run on the remote
# CODE_SANDBOX_URL.
#
# Output of `start` on success (one per line):
#   DOCUMENT_URL=http://127.0.0.1:<port>
#   DOCUMENT_TOKEN=<token>
#   DOC_SERVER_PID=<pid>
#   DOC_SERVER_ROOT=<dir>

CONFIG_DIR="$HOME/.config/jupyter-mcp"
PID_FILE="$CONFIG_DIR/doc-server.pid"
TOKEN_FILE="$CONFIG_DIR/doc-server.token"
URL_FILE="$CONFIG_DIR/doc-server.url"
ROOT_FILE="$CONFIG_DIR/doc-server.root"
LOG_FILE="$CONFIG_DIR/doc-server.log"

# jupyter-collaboration 5 provides the jupyter_server_ydoc extension that the
# MCP server's document operations (Y.js rooms) require.
UVX_ARGS=(--from jupyter-server --with jupyter-collaboration --with jupyterlab)

ACTION=${1:-status}

running_pid() {
  [[ -f "$PID_FILE" ]] || return 1
  local pid
  pid=$(cat "$PID_FILE" 2>/dev/null) || return 1
  [[ -n "$pid" ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  echo "$pid"
}

case "$ACTION" in
  start)
    ROOT=${2:-$PWD}
    WANT_PORT=${3:-48891}
    mkdir -p "$CONFIG_DIR"
    umask 077

    if [[ ! -d "$ROOT" ]]; then
      echo "doc-server: root dir not found: $ROOT" >&2
      exit 1
    fi
    ROOT=$(cd "$ROOT" && pwd)

    # Reuse a healthy server only when it already serves this root; otherwise
    # replace it, since documents outside the root are not reachable.
    if PID=$(running_pid); then
      OLD_ROOT=$(cat "$ROOT_FILE" 2>/dev/null || echo "")
      OLD_URL=$(cat "$URL_FILE" 2>/dev/null || echo "")
      OLD_TOKEN=$(cat "$TOKEN_FILE" 2>/dev/null || echo "")
      if [[ "$OLD_ROOT" == "$ROOT" && -n "$OLD_URL" ]] &&
         curl -fsS --max-time 5 -H "Authorization: token $OLD_TOKEN" "$OLD_URL/api" >/dev/null 2>&1; then
        echo "reusing running doc server (pid $PID)" >&2
        echo "DOCUMENT_URL=$OLD_URL"
        echo "DOCUMENT_TOKEN=$OLD_TOKEN"
        echo "DOC_SERVER_PID=$PID"
        echo "DOC_SERVER_ROOT=$ROOT"
        exit 0
      fi
      echo "stopping doc server on a different root (pid $PID)" >&2
      kill "$PID" 2>/dev/null || true
      for _ in $(seq 1 20); do kill -0 "$PID" 2>/dev/null || break; sleep 0.2; done
      kill -9 "$PID" 2>/dev/null || true
      rm -f "$PID_FILE"
    fi

    # Pin the port so DOCUMENT_URL stays valid: jupyter would otherwise pick a
    # different port when this one is busy, leaving the state file stale.
    if nc -z 127.0.0.1 "$WANT_PORT" >/dev/null 2>&1; then
      WANT_PORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')
    fi

    TOKEN=$(python3 -c 'import secrets; print(secrets.token_hex(24))')
    URL="http://127.0.0.1:$WANT_PORT"

    nohup uvx "${UVX_ARGS[@]}" jupyter server \
      --ServerApp.root_dir="$ROOT" \
      --ServerApp.ip=127.0.0.1 \
      --ServerApp.port="$WANT_PORT" \
      --ServerApp.port_retries=0 \
      --ServerApp.token="$TOKEN" \
      --ServerApp.open_browser=False \
      --ServerApp.disable_check_xsrf=True \
      </dev/null >"$LOG_FILE" 2>&1 &
    PID=$!

    echo "$PID" >"$PID_FILE"
    printf '%s' "$TOKEN" >"$TOKEN_FILE"
    printf '%s' "$URL" >"$URL_FILE"
    printf '%s' "$ROOT" >"$ROOT_FILE"

    # First run downloads the uvx environment, so allow a generous timeout.
    for _ in $(seq 1 90); do
      if ! kill -0 "$PID" 2>/dev/null; then
        echo "doc server exited unexpectedly:" >&2
        tail -30 "$LOG_FILE" >&2
        rm -f "$PID_FILE"
        exit 1
      fi
      if curl -fsS --max-time 2 -H "Authorization: token $TOKEN" "$URL/api" >/dev/null 2>&1; then
        # jupyter_server_ydoc is what serves /api/collaboration/session/...
        if ! grep -q "jupyter_server_ydoc | extension was successfully loaded" "$LOG_FILE"; then
          echo "warning: jupyter_server_ydoc not loaded; notebook tools may fail" >&2
        fi
        echo "DOCUMENT_URL=$URL"
        echo "DOCUMENT_TOKEN=$TOKEN"
        echo "DOC_SERVER_PID=$PID"
        echo "DOC_SERVER_ROOT=$ROOT"
        exit 0
      fi
      sleep 1
    done

    echo "doc server did not become ready within 90s:" >&2
    tail -30 "$LOG_FILE" >&2
    kill "$PID" 2>/dev/null || true
    rm -f "$PID_FILE"
    exit 1
    ;;

  stop)
    if PID=$(running_pid); then
      kill "$PID" 2>/dev/null || true
      for _ in $(seq 1 20); do kill -0 "$PID" 2>/dev/null || break; sleep 0.2; done
      kill -9 "$PID" 2>/dev/null || true
      echo "doc server stopped (pid $PID)"
    else
      echo "no running doc server"
    fi
    rm -f "$PID_FILE" "$TOKEN_FILE" "$URL_FILE" "$ROOT_FILE"
    ;;

  status)
    if PID=$(running_pid); then
      echo "doc server: alive (pid $PID)"
      echo "  url:  $(cat "$URL_FILE" 2>/dev/null || echo '?')"
      echo "  root: $(cat "$ROOT_FILE" 2>/dev/null || echo '?')"
    else
      echo "doc server: not running"
    fi
    ;;

  *)
    echo "usage: doc-server.sh {start [root_dir] [port]|stop|status}" >&2
    exit 1
    ;;
esac
