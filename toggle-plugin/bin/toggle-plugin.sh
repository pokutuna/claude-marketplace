#!/bin/bash
# toggle-plugin.sh - List/enable/disable Claude Code plugins per project
#
# Usage:
#   toggle-plugin.sh [--local] list                 - List installed plugins
#   toggle-plugin.sh [--local] enable <id>          - Enable plugin in settings
#   toggle-plugin.sh [--local] disable <id>         - Disable plugin in settings
#
# Options:
#   --local    Use .claude/settings.local.json instead of .claude/settings.json
#
# <id> can be a full ID (runpod@pokutuna-plugins) or short name (runpod).
# If a short name matches multiple plugins, the command fails with candidates.

set -euo pipefail

SETTINGS_FILE=".claude/settings.json"

# Parse --local flag
if [[ "${1:-}" == "--local" ]]; then
  SETTINGS_FILE=".claude/settings.local.json"
  shift
fi

list_plugins() {
  claude plugins list --json 2>/dev/null | jq -r '.[] | "\(.id)\t\(.scope)\t\(.enabled)"'
}

resolve_id() {
  local query="$1"
  local plugins
  plugins=$(list_plugins)

  if [[ "$query" == *@* ]]; then
    # Full ID: exact match
    if echo "$plugins" | grep -q "^${query}	"; then
      echo "$query"
      return 0
    fi
    echo "Error: plugin '$query' not found" >&2
    return 1
  fi

  # Short name: match prefix before @
  local matches
  matches=$(echo "$plugins" | awk -F'\t' -v q="$query" '$1 ~ "^"q"@" {print $1}')
  local count
  count=$(echo "$matches" | grep -c . || true)

  if [[ "$count" -eq 0 ]]; then
    echo "Error: no plugin matching '$query'" >&2
    return 1
  elif [[ "$count" -eq 1 ]]; then
    echo "$matches"
    return 0
  else
    echo "Error: '$query' matches multiple plugins:" >&2
    echo "$matches" >&2
    return 1
  fi
}

read_settings() {
  if [[ -f "$SETTINGS_FILE" ]]; then
    cat "$SETTINGS_FILE"
  else
    echo '{}'
  fi
}

write_settings() {
  mkdir -p "$(dirname "$SETTINGS_FILE")"
  echo "$1" > "$SETTINGS_FILE"
}

cmd_enable() {
  local id
  id=$(resolve_id "$1") || exit 1
  local settings
  settings=$(read_settings)
  settings=$(echo "$settings" | jq --arg id "$id" '.enabledPlugins[$id] = true')
  write_settings "$settings"
  echo "Enabled $id in $SETTINGS_FILE"
}

cmd_disable() {
  local id
  id=$(resolve_id "$1") || exit 1
  local settings
  settings=$(read_settings)
  settings=$(echo "$settings" | jq --arg id "$id" '.enabledPlugins[$id] = false')
  write_settings "$settings"
  echo "Disabled $id in $SETTINGS_FILE"
}

case "${1:-list}" in
  list)
    list_plugins
    ;;
  enable)
    [[ -z "${2:-}" ]] && { echo "Usage: toggle-plugin.sh enable <id>" >&2; exit 1; }
    cmd_enable "$2"
    ;;
  disable)
    [[ -z "${2:-}" ]] && { echo "Usage: toggle-plugin.sh disable <id>" >&2; exit 1; }
    cmd_disable "$2"
    ;;
  *)
    echo "Usage: toggle-plugin.sh {list|enable|disable} [id]" >&2
    exit 1
    ;;
esac
