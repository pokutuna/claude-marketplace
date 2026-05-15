---
name: pushover-notify
description: Toggle Pushover push notifications for Claude Code idle/permission prompts. Use when user mentions "pushover", "toggle pushover", "enable/disable notification".
metadata:
  author: pokutuna
  version: 0.1.1
allowed-tools:
  - "Bash(${CLAUDE_PLUGIN_ROOT}/bin/notify.sh *)"
---

Run `${CLAUDE_PLUGIN_ROOT}/bin/notify.sh <subcommand>` and report the output to the user.

Subcommand mapping:

- "on" -> `enable`
- "off" -> `disable`
- empty / "toggle" -> `toggle`
