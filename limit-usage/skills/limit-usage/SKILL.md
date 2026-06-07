---
name: limit-usage
description: Stop tool execution before exhausting your Claude usage — set a 5h/7d usage-% or per-session cost threshold.
disable-model-invocation: true
argument-hint: "5h=80 7d=90 | cost=5 | clear | status"
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

- **Set** — window-with-value input → `set <window> <value> ...` (`set`/`=`/`%`/`$` optional, multiple windows in one call). `5h=80 7d=90` → `set 5h 80 7d 90`; `cost=5` → `set cost 5`. Keep `--global` if present (but not with `cost` — see below). If one input mixes `--global` with `cost`, split into two calls — `set <rate...> --global` and a separate `set cost <n>` — since guard.sh rejects `--global` together with cost.
  - `5h` / `7d`: the value is `used_percentage` (0–100); `5h 80` stops at 80% used. Needs a usage quota (the `5h`/`7d` figures only show up on plans that have one).
  - `cost`: the value is this session's **approximate cumulative USD** ceiling; `cost 5` stops once the session reaches ~$5. Use this when `5h`/`7d` aren't reported (a plan with no usage quota). It's **per-session only** — reject `--global` for cost (guard.sh errors anyway).
- **Clear** — any "turn it off" intent → `clear` (wipes every threshold in effect; to drop one window, re-`set` the others).
- **Status** — `status` or no arguments → `status`. If status shows no 5h/7d usage, suggest a `cost` limit.
- **Install / uninstall** — point the user to `/limit-usage-setup install` (or `uninstall`).

A bare number with no window (`90`) → ask which window (5h / 7d / cost / combination); never guess.

State the result briefly. Mention `/limit-usage-setup install` only when the wrapper isn't installed.
