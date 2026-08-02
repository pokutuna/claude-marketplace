#!/usr/bin/env bash
set -euo pipefail

# Establish an SSH tunnel to a remote Jupyter Server and print JUPYTER_URL.
#
# Usage: setup-tunnel.sh "<ssh command>" [remote_port] [local_port]
#   <ssh command>: any ssh connection string, e.g. "ssh -p 2222 root@1.2.3.4 -i ~/.ssh/id_xxx"
#   remote_port:   Jupyter Server port on the remote host (default: 8888)
#   local_port:    local forwarding port (default: 48888, auto-fallback if busy)
#
# Output on success (one per line):
#   JUPYTER_URL=http://localhost:<local_port>
#   TUNNEL_PID=<pid>
#   LOG_FILE=<path>

SSH_CMD=${1:?usage: setup-tunnel.sh "<ssh command>" [remote_port] [local_port]}
REMOTE_PORT=${2:-8888}
LOCAL_PORT=${3:-48888}

STATE_DIR="${TMPDIR:-/tmp}/jupyter-mcp-tunnel"
mkdir -p "$STATE_DIR"

port_in_use() {
  nc -z 127.0.0.1 "$1" >/dev/null 2>&1
}

find_free_port() {
  python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()'
}

# Kill a stale tunnel we started earlier on this port (pod switching)
PID_FILE="$STATE_DIR/port-$LOCAL_PORT.pid"
if [[ -f "$PID_FILE" ]]; then
  OLD_PID=$(cat "$PID_FILE")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    kill "$OLD_PID" 2>/dev/null || true
    for _ in $(seq 1 10); do
      kill -0 "$OLD_PID" 2>/dev/null || break
      sleep 0.2
    done
  fi
  rm -f "$PID_FILE"
fi

# If the port is held by something that isn't ours, fall back to a free port
if port_in_use "$LOCAL_PORT"; then
  echo "port $LOCAL_PORT is in use by another process, picking a free port" >&2
  LOCAL_PORT=$(find_free_port)
  PID_FILE="$STATE_DIR/port-$LOCAL_PORT.pid"
fi

LOG_FILE="$STATE_DIR/port-$LOCAL_PORT.log"
SSH_OPTS="-o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o BatchMode=yes -o StrictHostKeyChecking=accept-new"

nohup bash -c "exec $SSH_CMD $SSH_OPTS -N -L $LOCAL_PORT:localhost:$REMOTE_PORT" \
  </dev/null >"$LOG_FILE" 2>&1 &
TUNNEL_PID=$!
echo "$TUNNEL_PID" >"$PID_FILE"

# Wait until the Jupyter Server responds through the tunnel (GET /api needs no auth)
for _ in $(seq 1 30); do
  if ! kill -0 "$TUNNEL_PID" 2>/dev/null; then
    echo "ssh tunnel exited unexpectedly:" >&2
    cat "$LOG_FILE" >&2
    rm -f "$PID_FILE"
    exit 1
  fi
  if curl -fsS --max-time 2 "http://127.0.0.1:$LOCAL_PORT/api" >/dev/null 2>&1; then
    echo "JUPYTER_URL=http://localhost:$LOCAL_PORT"
    echo "TUNNEL_PID=$TUNNEL_PID"
    echo "LOG_FILE=$LOG_FILE"
    exit 0
  fi
  sleep 1
done

echo "tunnel established but Jupyter Server did not respond on remote port $REMOTE_PORT within 30s" >&2
cat "$LOG_FILE" >&2
kill "$TUNNEL_PID" 2>/dev/null || true
rm -f "$PID_FILE"
exit 1
