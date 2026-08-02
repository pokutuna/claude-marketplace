#!/usr/bin/env bash
set -euo pipefail

# Update the jupyter-mcp state file and ensure the .mcp.json entry exists.
#
# Usage: update-config.sh <jupyter_url> [token] [mcp_json_path]
#   jupyter_url:   e.g. http://localhost:48888 or https://xxx-8888.proxy.runpod.net
#   token:         JUPYTER_TOKEN (optional; pass "" for token-less servers)
#   mcp_json_path: default ./.mcp.json
#
# Design: .mcp.json points at a stable wrapper (~/.config/jupyter-mcp/wrapper.sh)
# that reads env from ~/.config/jupyter-mcp/current.env at exec time.
# Claude Code snapshots .mcp.json at session start, so keeping the entry
# immutable and moving mutable values to the state file lets a /mcp
# reconnect pick up new values without a session restart.
#
# Output: last line is either
#   ENTRY_ADDED <path>     (.mcp.json changed; session restart needed once)
#   ENTRY_UNCHANGED <path> (state file updated; /mcp reconnect is enough)

URL=${1:?usage: update-config.sh <jupyter_url> [token] [mcp_json_path]}
TOKEN=${2:-}
FILE=${3:-.mcp.json}

CONFIG_DIR="$HOME/.config/jupyter-mcp"
ENV_FILE="$CONFIG_DIR/current.env"
WRAPPER="$CONFIG_DIR/wrapper.sh"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

mkdir -p "$CONFIG_DIR"
umask 077

# 1. Write the state file (read by the wrapper at exec time)
{
  printf 'JUPYTER_URL=%q\n' "$URL"
  [[ -n "$TOKEN" ]] && printf 'JUPYTER_TOKEN=%q\n' "$TOKEN"
  printf 'ALLOW_IMG_OUTPUT=true\n'
} >"$ENV_FILE"
echo "state file updated: $ENV_FILE"

# 2. Install/refresh the wrapper at a stable path (plugin install paths can move)
cp "$SCRIPT_DIR/wrapper.sh" "$WRAPPER"
chmod 755 "$WRAPPER"

# 3. Ensure the .mcp.json entry (immutable; no URL/token inside)
if [[ -L "$FILE" ]]; then
  # Follow symlinks so we don't replace a linked file with a regular one
  FILE=$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$FILE")
fi
if [[ ! -f "$FILE" ]]; then
  echo '{}' >"$FILE"
fi

BEFORE=$(jq -c '.mcpServers["jupyter-mcp-server"] // null' "$FILE")
TMP=$(mktemp)
jq --arg wrapper "$WRAPPER" '
  .mcpServers = (.mcpServers // {}) |
  .mcpServers["jupyter-mcp-server"] = {
    command: "bash",
    args: [$wrapper]
  }
' "$FILE" >"$TMP"
AFTER=$(jq -c '.mcpServers["jupyter-mcp-server"]' "$TMP")

if [[ "$BEFORE" == "$AFTER" ]]; then
  rm -f "$TMP"
  echo "ENTRY_UNCHANGED $FILE"
else
  mv "$TMP" "$FILE"
  echo "ENTRY_ADDED $FILE"
fi
