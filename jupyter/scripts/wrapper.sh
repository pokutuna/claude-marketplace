#!/usr/bin/env bash
set -euo pipefail

# jupyter-mcp-server launcher installed to ~/.config/jupyter-mcp/wrapper.sh
# by the jupyter plugin (connect-mcp skill).
#
# Reads JUPYTER_URL / JUPYTER_TOKEN from a state file at exec time, so that
# re-enabling the MCP server in /mcp picks up the latest values without
# restarting the Claude Code session (.mcp.json itself never changes).

ENV_FILE="${JUPYTER_MCP_ENV_FILE:-$HOME/.config/jupyter-mcp/current.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "jupyter-mcp wrapper: state file not found: $ENV_FILE" >&2
  echo "run the connect-mcp skill to create it" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

# @latest keeps us on the current release. 1.5.2+ routes document operations
# to DOCUMENT_URL when the document and code-sandbox servers differ
# (hybrid: local notebook + remote kernel).
exec uvx jupyter-mcp-server@latest
