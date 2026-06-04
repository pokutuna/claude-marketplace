---
name: limit-usage
description: Stop tool execution before exhausting your Claude rate limit.
disable-model-invocation: true
argument-hint: "5h=80 7d=90 | off [5h|7d] | clear | status"
metadata:
  author: pokutuna
allowed-tools:
  - "Bash(CLAUDE_SESSION_ID=* CLAUDE_PLUGIN_ROOT=* ${CLAUDE_PLUGIN_ROOT}/bin/guard.sh *)"
---

Set per-window usage thresholds; tools are denied once a Claude rate-limit window passes one. Usage is read from the statusLine snapshot at zero metering cost.

This skill only manages thresholds and status. The statusLine wrapper that captures usage is installed separately via **`/limit-usage-setup install`** — without it, thresholds do nothing.

<ARGUMENTS>
$ARGUMENTS
</ARGUMENTS>

Run guard.sh with the session id (per-session thresholds need it):
`CLAUDE_SESSION_ID=${CLAUDE_SESSION_ID} CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT} ${CLAUDE_PLUGIN_ROOT}/bin/guard.sh <subcommand>`

## Subcommands

Your job is to turn the user's input into one canonical guard.sh call. guard.sh
is strict; you do the friendly parsing. Always pass `set` explicitly to the shell.

**Setting thresholds.** Accept any of these and normalize to `set <window> <pct> ...`:
- `5h=80`, `5h 80`, `5h 80%`, or `set 5h 80` → `set 5h 80` (a window-value pair, `%` stripped, with or without `=` or the `set` keyword).
- Multiple windows in one go → one call with all pairs: `5h=80 7d=90` → `set 5h 80 7d 90`.
- `--global` anywhere → keep it on the call (applies to all sessions); else per-session.
- The number is `used_percentage` (0–100): `5h 80` stops once the 5h window is 80% used.

**Other subcommands** (pass through as-is):
- `off` / `off 5h` / `off 7d` / "disable" → `off [5h|7d] [--global]`. Removes one window (or both) in one scope.
- `clear` / "clear all" / "reset" → `clear`. Removes every threshold in effect for this session — both the session's own and any global ones — without needing a scope flag.
- `status` → `status`.
- `install` / `uninstall` → not here; tell the user to run `/limit-usage-setup install` (or `uninstall`), which edits settings.json.

**When unsure** — a bare number with no window (`90`, `set 90`), or an odd count of values → **ask which window (5h / 7d / both); never guess.**

State the result of the command you ran, briefly — a one-line confirmation for `set`/`off`/`clear`, or the `status` output for `status`. Add a pointer to `/limit-usage-setup install` only when the wrapper is not installed (a threshold does nothing without it).

## Notes

- Fail-open: no/stale snapshot (>5 min, override `LIMIT_USAGE_STALE_SECONDS`) or no threshold → tools run. Blocks only on a confirmed breach.
- `rate_limits` needs a Claude.ai subscription and the first API response of a session; free tier never triggers.
