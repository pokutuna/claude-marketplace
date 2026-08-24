#!/usr/bin/env bash
set -euo pipefail

# Update the jupyter-mcp state file and ensure the .mcp.json entry exists.
#
# Usage: update-config.sh <remote_url> [token] [mcp_json_path] [doc_url] [doc_token]
#   remote_url:    e.g. http://localhost:48888 or https://xxx-8888.proxy.runpod.net
#   token:         remote server token (optional; pass "" for token-less servers)
#   mcp_json_path: default ./.mcp.json
#   doc_url:       local document server URL; enables the hybrid setup
#   doc_token:     local document server token
#
# Two shapes, following the upstream configuration docs:
#   - hybrid (doc_url given): DOCUMENT_URL/_TOKEN for notebook files (local) plus
#     CODE_SANDBOX_URL/_TOKEN for kernels (remote) -- the "advanced" split.
#   - single server (doc_url omitted): JUPYTER_URL/_TOKEN, the "simplified"
#     form, which points both document and kernel operations at the remote.
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

URL=${1:?usage: update-config.sh <remote_url> [token] [mcp_json_path] [doc_url] [doc_token]}
TOKEN=${2:-}
FILE=${3:-.mcp.json}
DOC_URL=${4:-}
DOC_TOKEN=${5:-}

CONFIG_DIR="$HOME/.config/jupyter-mcp"
ENV_FILE="$CONFIG_DIR/current.env"
WRAPPER="$CONFIG_DIR/wrapper.sh"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

mkdir -p "$CONFIG_DIR"
umask 077

# 1. Write the state file (read by the wrapper at exec time)
{
  if [[ -n "$DOC_URL" ]]; then
    printf 'DOCUMENT_URL=%q\n' "$DOC_URL"
    [[ -n "$DOC_TOKEN" ]] && printf 'DOCUMENT_TOKEN=%q\n' "$DOC_TOKEN"
    printf 'CODE_SANDBOX_URL=%q\n' "$URL"
    [[ -n "$TOKEN" ]] && printf 'CODE_SANDBOX_TOKEN=%q\n' "$TOKEN"
  else
    printf 'JUPYTER_URL=%q\n' "$URL"
    [[ -n "$TOKEN" ]] && printf 'JUPYTER_TOKEN=%q\n' "$TOKEN"
  fi
  printf 'ALLOW_IMG_OUTPUT=true\n'
} >"$ENV_FILE"
if [[ -n "$DOC_URL" ]]; then
  echo "state file updated (hybrid: local documents, remote kernel): $ENV_FILE"
else
  echo "state file updated (single server): $ENV_FILE"
fi

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
