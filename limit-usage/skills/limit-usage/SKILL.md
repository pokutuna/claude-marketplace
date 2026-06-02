---
name: limit-usage
description: Stop tool execution before exhausting your Claude rate limit. Set / clear per-window usage thresholds, check status, and wire up (setup) / restore (teardown) the statusLine usage capture. Triggers on "limit-usage", "set 5h 80%", "stop at N% usage", "usage limit".
metadata:
  author: pokutuna
allowed-tools:
  - "Bash(CLAUDE_SESSION_ID=* CLAUDE_PLUGIN_ROOT=* ${CLAUDE_PLUGIN_ROOT}/bin/guard.sh *)"
  - "Bash(${CLAUDE_PLUGIN_ROOT}/bin/guard.sh *)"
  - Read
  - Edit
---

Controls `limit-usage`: stop tool execution before a Claude rate-limit window passes a usage threshold. Usage is read from the statusLine snapshot at **zero metering cost** — no extra API calls.

<ARGUMENTS>
$ARGUMENTS
</ARGUMENTS>

Run guard.sh with the session id so per-session thresholds resolve:
`CLAUDE_SESSION_ID=${CLAUDE_SESSION_ID} CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT} ${CLAUDE_PLUGIN_ROOT}/bin/guard.sh <subcommand>`

## Subcommand mapping

- `set 5h 80%` / "stop 5h at 80" → `set 5h 80` (per session). Add `--global` for all sessions.
- `set 7d 90%` → `set 7d 90` (per session, or `--global`).
- `off` / `off 5h` / `off 7d` / "disable" → `off [5h|7d] [--global]`
- `status` / "show usage" → `status`
- `setup` → see **Setup** below (requires editing settings.json with consent).
- `teardown` → see **Teardown** below.
- Empty `$ARGUMENTS` → run `status`, then briefly remind the user that `setup` is required once before thresholds take effect.

Threshold meaning: the number is **used_percentage** (0–100). `set 5h 80` = stop once the 5-hour window is **80% used**. Reads resolve session → global → unset (unset = that window is not guarded).

After any `set`/`off`/`status`, report the result plainly.

## Setup (one time, requires consent)

The guard only sees usage after the statusLine command is wrapped to capture it. **Never edit settings.json without showing the change and getting consent.**

1. Read the user's `settings.json` (check `~/.claude/settings.json`; also mention project `.claude/settings.json` if present) and find `statusLine.command`.
2. Run `guard.sh setup '<current statusLine.command>'` (pass an empty string if there is no statusLine). This prints a before/after plan and saves the original for teardown.
   - If output is `ALREADY_WRAPPED`, tell the user it's already set up and stop.
3. Show the before/after to the user and explain: *"This wraps your statusLine so usage % is recorded to a state file. Your status line display is unchanged; the original is saved and restorable with teardown."* If they had no statusLine, offer the minimal wrapper (it prints `5h: N% | 7d: N%`).
4. Use **AskUserQuestion** to confirm. Only on approval, **Edit** settings.json to set `statusLine.command` to the `after:` value. Preserve `statusLine.type` (`"command"`) and `padding`.
5. Tell the user the guard activates after the next assistant response (the first statusLine refresh writes the snapshot).

## Teardown

1. Run `guard.sh teardown`. It prints either `RESTORE_TO` + the original command, or `RESTORE_REMOVE` (no original was saved).
2. Read settings.json, show the change, confirm with **AskUserQuestion**, then **Edit**:
   - `RESTORE_TO` → set `statusLine.command` back to the printed original.
   - `RESTORE_REMOVE` → remove the wrapper (delete the `statusLine` block, or restore whatever the user prefers).
3. Optionally remind: thresholds in the state file remain; uninstalling the plugin removes the hook. See README for full uninstall.

## Notes

- **Fail-open**: if there's no snapshot yet, it's stale (>30 min, override `LIMIT_USAGE_STALE_SECONDS`), or the window has no threshold, the guard allows tools through. It only blocks on a confirmed breach.
- `rate_limits` only appears for Claude.ai subscriptions (Pro/Max/Team/Enterprise) and only after the first API response of a session. Free tier never triggers the guard.
