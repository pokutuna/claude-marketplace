---
name: toggle-plugin
description: >-
  Toggle Claude Code plugins enabled/disabled per project.
model_invocation: false
metadata:
  author: pokutuna
  compatibility: ">=1.0.0"
allowed-tools:
  - Bash(${CLAUDE_PLUGIN_ROOT}/bin/toggle-plugin.sh *)
---

Toggle Claude Code plugins enabled/disabled for the current project.

<ARGUMENTS>
$ARGUMENTS
</ARGUMENTS>

## Subcommands

Parse $ARGUMENTS to determine the subcommand and run:

- `list` (or no arguments): `${CLAUDE_PLUGIN_ROOT}/bin/toggle-plugin.sh list`
- `enable <id>`: `${CLAUDE_PLUGIN_ROOT}/bin/toggle-plugin.sh enable <id>`
- `disable <id>`: `${CLAUDE_PLUGIN_ROOT}/bin/toggle-plugin.sh disable <id>`

If `--local` is specified, prepend `--local` flag to write to `.claude/settings.local.json` instead.

`<id>` can be a full ID (`runpod@pokutuna-plugins`) or short name (`runpod`).

Report the result to the user.
