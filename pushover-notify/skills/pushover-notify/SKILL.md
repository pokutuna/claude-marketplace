---
name: pushover-notify
description: Toggle Pushover push notifications on/off. "pushover", "toggle pushover" などで起動。
metadata:
  author: pokutuna
  version: 0.2.2
allowed-tools:
  - "Bash(${CLAUDE_PLUGIN_ROOT}/bin/notify.sh *)"
---

Run `${CLAUDE_PLUGIN_ROOT}/bin/notify.sh <subcommand>` and report the output to the user.

Subcommand mapping:

- "on" -> `enable`
- "off" -> `disable`
- empty / "toggle" -> `toggle`
