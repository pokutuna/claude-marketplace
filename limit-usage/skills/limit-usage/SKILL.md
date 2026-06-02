---
name: limit-usage
description: Stop tool execution before exhausting your Claude rate limit.
disable-model-invocation: true
argument-hint: "set 5h 80% | off [5h|7d] | status | install | uninstall [--global]"
metadata:
  author: pokutuna
allowed-tools:
  - "Bash(CLAUDE_SESSION_ID=* CLAUDE_PLUGIN_ROOT=* ${CLAUDE_PLUGIN_ROOT}/bin/guard.sh *)"
  # install/uninstall also pass CLAUDE_PLUGIN_DATA (where the wrapper copy lives).
  - "Bash(CLAUDE_PLUGIN_DATA=* CLAUDE_SESSION_ID=* CLAUDE_PLUGIN_ROOT=* ${CLAUDE_PLUGIN_ROOT}/bin/guard.sh *)"
  - Read
  # Pre-approve the common settings paths. If either is a symlink into a
  # dotfiles repo, editing its real path falls outside these patterns and
  # prompts for consent — which is what we want before touching that repo.
  - "Edit(~/.claude/settings.json)"
  - "Edit(.claude/settings.json)"
---

Stop tool execution before a Claude rate-limit window passes a usage threshold. Usage is read from the statusLine snapshot at zero metering cost.

<ARGUMENTS>
$ARGUMENTS
</ARGUMENTS>

Run guard.sh with the session id (per-session thresholds need it):
`CLAUDE_SESSION_ID=${CLAUDE_SESSION_ID} CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT} ${CLAUDE_PLUGIN_ROOT}/bin/guard.sh <subcommand>`

`install` / `uninstall` additionally need the data dir (that's where the wrapper copy lives); prefix those with `CLAUDE_PLUGIN_DATA=${CLAUDE_PLUGIN_DATA}`.

## Subcommands

- `set 5h 80%` → `set 5h 80` (strip `%`). Add `--global` for all sessions, else per-session.
- `set 7d 90%` → `set 7d 90`.
- `off` / `off 5h` / `off 7d` / "disable" → `off [5h|7d] [--global]`.
- `status` → `status`.
- `install` / `uninstall` → see below.
- Bare number or no window named (`90`, `set 90`) → **ask which window (5h / 7d / both) first; never guess.**

The number is `used_percentage` (0–100): `set 5h 80` stops once the 5h window is 80% used.

After `set`, also run `status`; if the wrapper is not installed, tell the user to run `install` (a threshold does nothing without it).

## install (requires consent — never edit settings.json without it)

1. Pick the settings file: `~/.claude/settings.json` (or project `.claude/settings.json` if that's where the user keeps `statusLine`). **If it is a symlink, resolve it with `realpath` and edit the real file** — editing the link in place would replace it with a plain file and silently detach it from a dotfiles repo. Tell the user which real path you'll edit (e.g. `~/dotfiles/claude/settings.json`); for a dotfiles symlink that means their repo changes and they'll want to commit it.
2. Read that file; find `statusLine.command`.
3. Run install **with the `CLAUDE_PLUGIN_DATA=${CLAUDE_PLUGIN_DATA}` prefix**: `CLAUDE_PLUGIN_DATA=${CLAUDE_PLUGIN_DATA} ... guard.sh install '<current statusLine.command>'` (empty string if none). This copies the wrapper into the plugin's data dir (a version-stable path that survives updates, since statusLine can't expand `${CLAUDE_PLUGIN_ROOT}`) and prints a before/after plan whose `after:` points at that copy. On `ALREADY_WRAPPED`, say it's done and stop.
4. Show before/after. Note: display is unchanged; the original is saved and restorable via `uninstall`.
5. Confirm with **AskUserQuestion**. Only on approval, **Edit** the resolved file's `statusLine.command` to the `after:` value; keep `type` and `padding`.
6. Guard activates after the next response (first statusLine refresh writes the snapshot).

## uninstall

1. Run uninstall **with the `CLAUDE_PLUGIN_DATA=${CLAUDE_PLUGIN_DATA}` prefix**: `CLAUDE_PLUGIN_DATA=${CLAUDE_PLUGIN_DATA} ... guard.sh uninstall` → prints `RESTORE_TO` + original, or `RESTORE_REMOVE`, and removes the wrapper copy from the data dir.
2. Resolve the settings file the same way as install step 1 (follow a symlink to its real path).
3. Confirm with **AskUserQuestion**, then **Edit** the resolved file: `RESTORE_TO` → set command back; `RESTORE_REMOVE` → remove the wrapper.

## Notes

- Fail-open: no/stale snapshot (>5 min, override `LIMIT_USAGE_STALE_SECONDS`) or no threshold → tools run. Blocks only on a confirmed breach.
- `rate_limits` needs a Claude.ai subscription and the first API response of a session; free tier never triggers.
- After updating the plugin, re-run `install` to refresh the wrapper copy in the data dir (the baked statusLine path stays the same, so no settings.json edit is needed — just re-copy).
