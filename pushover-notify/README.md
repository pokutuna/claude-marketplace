# pushover-notify

Send [Pushover](https://pushover.net/) push notifications when Claude Code needs your attention — idle prompts or permission requests.

## Features

- Fires on `Notification` events (idle prompts and permission requests)
- **Display-aware (macOS)**: skips sending when the display is on, so you only get pinged when you're actually away
- **Cross-session cooldown**: 60 seconds, prevents notification floods from multiple parallel sessions
- **Disabled by default**: opt-in via `/toggle-pushover on`
- Silent on failure: hook never disrupts Claude Code

## Installation

```bash
claude plugin marketplace add pokutuna/claude-plugins
claude plugin install pushover-notify@pokutuna-plugins --scope user
```

## Setup

1. Create a Pushover account and application: <https://pushover.net/>
2. Set credentials in your shell:

   ```bash
   export PUSHOVER_TOKEN="your-app-token"
   export PUSHOVER_USER="your-user-key"
   ```

3. Enable notifications by asking Claude in natural language:

   ```
   pushover on
   ```

## Usage

The plugin exposes a Skill triggered by phrases like:

- `pushover on` / `pushover off` — enable / disable
- `pushover toggle` — flip current state
- `pushover status` — show state, credentials, display detection, last sent

## How it works

```mermaid
flowchart LR
    N[Notification event] --> H[notify.sh send]
    H --> E{enabled?}
    E -- no --> X[exit]
    E -- yes --> C{credentials set?}
    C -- no --> X
    C -- yes --> D{display on?<br/>(macOS only)}
    D -- yes --> X
    D -- no --> R{cooldown<br/>elapsed?}
    R -- no --> X
    R -- yes --> P[POST Pushover API]
```

State is stored at `${XDG_STATE_HOME:-~/.local/state}/claude-pushover-notify.conf` in git-config format:

```
[global]
    enabled = true
    last-sent = 1730000000
```

## Display detection

On macOS, the script reads `pmset -g assertions` and skips notifications when the `"Prevent sleep while display is on"` assertion is held by `powerd` — i.e. the display is currently lit. When the display sleeps, the assertion is released and notifications go through.

On non-macOS systems (or when `pmset` is unavailable), this check is skipped and notifications are always sent.

## Environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `PUSHOVER_TOKEN` | yes | Pushover application token |
| `PUSHOVER_USER` | yes | Pushover user key |
