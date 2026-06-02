---
name: limit-usage-setup
description: Install or uninstall the limit-usage statusLine wrapper (edits settings.json).
disable-model-invocation: true
argument-hint: "install | uninstall"
metadata:
  author: pokutuna
allowed-tools:
  - "Bash(CLAUDE_PLUGIN_DATA=* CLAUDE_PLUGIN_ROOT=* ${CLAUDE_PLUGIN_ROOT}/bin/guard.sh *)"
  - Read
  # Pre-approve the common settings paths. If either is a symlink into a
  # dotfiles repo, editing its real path falls outside these patterns and
  # prompts for consent — which is what we want before touching that repo.
  - "Edit(~/.claude/settings.json)"
  - "Edit(.claude/settings.json)"
---

Install or uninstall the limit-usage statusLine wrapper. This is the only part that edits `settings.json`; day-to-day thresholds live in the `limit-usage` skill.

The wrapper captures usage from the statusLine stream (zero metering cost) so the guard can read it. Without it, thresholds set via `limit-usage` do nothing.

<ARGUMENTS>
$ARGUMENTS
</ARGUMENTS>

Pick `install` or `uninstall` from the argument. Run guard.sh with the data dir (where the wrapper copy lives):
`CLAUDE_PLUGIN_DATA=${CLAUDE_PLUGIN_DATA} CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT} ${CLAUDE_PLUGIN_ROOT}/bin/guard.sh <install|uninstall>`

## install (the Edit tool's permission prompt is the single consent point — don't add a second)

1. **Locate the settings file that actually holds `statusLine` for this session — never hardcode `~/.claude/settings.json`.** Determine the user-scope config dir, then find which settings file defines `statusLine`:
   - User-scope settings live at `$CLAUDE_CONFIG_DIR/settings.json` when `CLAUDE_CONFIG_DIR` is set, otherwise `~/.claude/settings.json`. (Note: `CLAUDE_CONFIG_DIR` does **not** move `CLAUDE.md`, so don't infer the config dir from the CLAUDE.md path in your context — read `$CLAUDE_CONFIG_DIR` directly, e.g. `echo "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"`.)
   - `statusLine` may instead be in the project `.claude/settings.json`. The session reminders/context tell you which config dir and project you're in — use those plus the env var to pick the right file. Read the candidate(s) and edit the one that actually defines `statusLine` (or the user-scope file if none does and the user wants it global).
   - **If the chosen file is a symlink, resolve it with `realpath` and edit the real file** — editing the link in place would replace it with a plain file and silently detach it from a dotfiles repo. Tell the user which real path you'll edit (e.g. `~/dotfiles/claude/settings.json`); for a dotfiles symlink that means their repo changes and they'll want to commit it.
2. In that file, read the current `statusLine.command` (empty if there is no `statusLine` yet).
3. `guard.sh install '<current statusLine.command>'` (empty string if none). This copies the wrapper into the plugin's data dir (a version-stable path that survives updates, since statusLine can't expand `${CLAUDE_PLUGIN_ROOT}`) and prints a before/after plan whose `after:` points at that copy. On `ALREADY_WRAPPED`, say it's done and stop.
4. State the change in one line — which file you'll edit and the before → after of `statusLine.command` (display is unchanged; the original is saved and restorable via `uninstall`) — then **Edit** the resolved file's `statusLine.command` to the `after:` value, keeping `type` and `padding`. Don't ask a separate confirmation question; the Edit tool's own permission prompt is the consent point (if it's blocked, the user gets asked there).
5. Guard activates after the next response (first statusLine refresh writes the snapshot). Set thresholds with `/limit-usage set`.

## uninstall

1. `guard.sh uninstall` → prints `RESTORE_TO` + original, or `RESTORE_REMOVE`, and removes the wrapper copy from the data dir.
2. Locate the settings file the same way as install step 1 — the one whose `statusLine.command` points at the wrapper (`$CLAUDE_CONFIG_DIR/settings.json` vs `~/.claude/settings.json` vs project `.claude/settings.json`); follow a symlink to its real path.
3. State the change in one line, then **Edit** the resolved file: `RESTORE_TO` → set the command back; `RESTORE_REMOVE` → remove the wrapper. No separate confirmation question — the Edit tool's permission prompt is the consent point.

## Notes

- After updating the plugin, re-run `install` to refresh the wrapper copy in the data dir (the baked statusLine path stays the same, so no settings.json edit is needed — just re-copy).
