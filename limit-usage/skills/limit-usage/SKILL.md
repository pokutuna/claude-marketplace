---
name: limit-usage
description: Stop tool execution before exhausting your Claude rate limit.
disable-model-invocation: true
argument-hint: "5h=80 7d=90 | clear | status"
metadata:
  author: pokutuna
allowed-tools:
  - "Bash(CLAUDE_SESSION_ID=* CLAUDE_PLUGIN_ROOT=* ${CLAUDE_PLUGIN_ROOT}/bin/guard.sh *)"
---

Manage per-window usage thresholds. Capturing usage needs a one-time `/limit-usage-setup install`; without it, thresholds do nothing.

<ARGUMENTS>
$ARGUMENTS
</ARGUMENTS>

Turn the input into one guard.sh call (guard.sh is strict; you do the friendly parsing):
`CLAUDE_SESSION_ID=${CLAUDE_SESSION_ID} CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT} ${CLAUDE_PLUGIN_ROOT}/bin/guard.sh <subcommand>`

- **Set** — window-with-value input → `set <window> <pct> ...` (`set`/`=`/`%` optional, multiple windows in one call). `5h=80 7d=90` → `set 5h 80 7d 90`. Keep `--global` if present. The number is `used_percentage` (0–100); `5h 80` stops at 80% used.
- **Clear** — any "turn it off" intent → `clear` (wipes every threshold in effect; to drop one window, re-`set` the other).
- **Status** — `status` or no arguments → `status`.
- **Install / uninstall** — point the user to `/limit-usage-setup install` (or `uninstall`).

A number with no window (`90`) → ask which window (5h / 7d / both); never guess.

State the result briefly. Mention `/limit-usage-setup install` only when the wrapper isn't installed.
