# side-fork

Fork the current Claude Code session and open the fork in a new tmux or screen window.

## What it does

Type `/side-fork` in a Claude Code session running inside tmux or screen:

- **This terminal** continues as the original session (main line)
- **New window** opens with the forked session

Unlike the built-in `/fork` (which replaces the current terminal with the fork), `side-fork` keeps this terminal as the original and opens the fork in a new window.

## Requirements

- [tmux](https://github.com/tmux/tmux) or [screen](https://www.gnu.org/software/screen/)
- Claude Code running inside a tmux or screen session

## Usage

```
/side-fork
```

## Installation

```
/plugin install side-fork@pokutuna-plugins
```
