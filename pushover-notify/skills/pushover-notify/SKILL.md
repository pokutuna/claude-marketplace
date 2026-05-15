---
name: pushover-notify
description: Toggle Pushover push notifications for Claude Code idle/permission prompts. Use when user mentions "pushover", "通知 on/off", "離席通知", "toggle pushover".
metadata:
  author: pokutuna
  version: 0.1.0
allowed-tools:
  - "Bash(${CLAUDE_PLUGIN_ROOT}/bin/notify.sh *)"
---

Run `${CLAUDE_PLUGIN_ROOT}/bin/notify.sh <subcommand>` and report the output to the user.

Subcommand mapping:

- "on" / "enable" / "有効" -> `enable`
- "off" / "disable" / "無効" -> `disable`
- "toggle" / empty -> `toggle`
- "status" / "状態" -> `status`
