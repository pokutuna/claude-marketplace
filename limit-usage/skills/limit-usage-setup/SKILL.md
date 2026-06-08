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

Pick `install` or `uninstall`. `guard.sh` only manages the wrapper copy in the data dir; **this skill owns settings.json** — it wraps the live `statusLine.command` on install and strips the wrapper back off on uninstall. We never store the original, so a statusLine the user edited after install is still respected.

The **Edit tool's own permission prompt is the single consent point** — never add a separate confirmation question. Before each Edit, just state in one line which file and the before → after of `statusLine.command` (the display is unchanged; `uninstall` reverses install).

### Finding the settings file (both flows)

Never hardcode `~/.claude/settings.json` — find the file that actually defines `statusLine`:
- User scope is `$CLAUDE_CONFIG_DIR/settings.json` (else `~/.claude/settings.json`). Read `$CLAUDE_CONFIG_DIR` directly — it does **not** move `CLAUDE.md`, so don't infer the dir from the CLAUDE.md path in your context.
- It may instead be the project `.claude/settings.json`. Use the session context to pick; read the candidate(s) and edit the one defining `statusLine` (or the user-scope file if none does and the user wants it global).
- **If that file is a symlink, resolve it with `realpath` and edit the real file** — editing the link replaces it with a plain file and silently detaches it from a dotfiles repo. Tell the user the real path (e.g. `~/dotfiles/claude/settings.json`); for a dotfiles symlink that's a repo change they'll want to commit.

### install

1. `guard.sh install` → copies the wrapper into the data dir (a version-stable path that survives updates, since statusLine can't expand `${CLAUDE_PLUGIN_ROOT}`), drops any pre-unification snapshot files, and prints `WRAPPER_PATH` then the baked path on the next line. Capture it as `<wrapper>`.
2. Read the current `statusLine.command`. **If it already contains `statusline-wrapper.sh` it's wrapped** — step 1 already refreshed the copy, so say it's done and stop (no settings edit unless the wrapper path itself changed).
3. **Edit** the command to `<wrapper> '<current command>'` — single-quote the current command, escaping embedded `'` as `'\''`; if there was none, the command is just `<wrapper>`. Keep `type`/`padding`; add a `statusLine` block with `"type": "command"` if absent.
4. Guard activates after the next response (the first statusLine refresh writes the snapshot). Set thresholds with `/limit-usage set`.

### uninstall

1. `guard.sh uninstall` → removes the wrapper copy and prints `WRAPPER_REMOVED` (idempotent).
2. Find the file whose `statusLine.command` contains `statusline-wrapper.sh`.
3. **Unwrap and Edit.** The wrapped form is `<wrapper> '<original>'`: strip the leading `<…>statusline-wrapper.sh ` and the surrounding single quotes (un-escape `'\''` → `'`). If an `<original>` remains, restore it; if nothing remains, there was no original → remove the `statusLine` block.

`guard.sh` for either flow:
`CLAUDE_PLUGIN_DATA=${CLAUDE_PLUGIN_DATA} CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT} ${CLAUDE_PLUGIN_ROOT}/bin/guard.sh <install|uninstall>`

## Notes

- After updating the plugin, re-run `install` to refresh the wrapper copy in the data dir (the baked statusLine path stays the same, so no settings.json edit is needed — just re-copy). If `/limit-usage status` warns the wrapper looks outdated, this is the fix.
