---
name: limit-usage
description: Stop tool execution before exhausting your Claude rate limit.
disable-model-invocation: true
argument-hint: "set 5h 80% | off [5h|7d] | status"
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

- `set 5h 80%` → `set 5h 80` (strip `%`). Add `--global` for all sessions, else per-session.
- `set 7d 90%` → `set 7d 90`.
- `off` / `off 5h` / `off 7d` / "disable" → `off [5h|7d] [--global]`.
- `status` → `status`.
- `install` / `uninstall` → not here; tell the user to run `/limit-usage-setup install` (or `uninstall`), which edits settings.json.
- Bare number or no window named (`90`, `set 90`) → **ask which window (5h / 7d / both) first; never guess.**

The number is `used_percentage` (0–100): `set 5h 80` stops once the 5h window is 80% used.

State the result of the command you ran, briefly — a one-line confirmation for `set`/`off`, or the `status` output for `status`. Add a pointer to `/limit-usage-setup install` only when the wrapper is not installed (a threshold does nothing without it).

## Notes

- Fail-open: no/stale snapshot (>5 min, override `LIMIT_USAGE_STALE_SECONDS`) or no threshold → tools run. Blocks only on a confirmed breach.
- `rate_limits` needs a Claude.ai subscription and the first API response of a session; free tier never triggers.
