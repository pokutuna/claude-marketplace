---
name: side-fork
description: Fork the current Claude session and open the fork in a new tmux or screen window. This terminal continues as the original session; the new window becomes the experimental branch.
allowed-tools: "Bash(${CLAUDE_PLUGIN_ROOT}/bin/side-fork.sh *)"
disable-model-invocation: true
metadata:
  author: pokutuna
  version: 0.1.0
---
# side-fork

Fork the current session into a new terminal window. Unlike the built-in `/fork` (which replaces the current terminal with the fork), this keeps the current terminal as the original session and opens the fork in a new window.

## Instructions

Run the following command:

```
${CLAUDE_PLUGIN_ROOT}/bin/side-fork.sh ${CLAUDE_SESSION_ID}
```

On success, tell the user:
- A new window has been opened with the forked session
- This terminal continues as the original session

## Supported Terminals

- **tmux**: Opens a new window (`tmux new-window`)
- **screen**: Opens a new window (`screen -X screen`)

## Troubleshooting

### "unsupported terminal"

The script only supports tmux and screen. If you're using another terminal, run the fork manually:

```
claude --resume <session_id> --fork-session
```
