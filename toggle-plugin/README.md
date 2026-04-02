# toggle-plugin

Toggle Claude Code plugins enabled/disabled per project via `.claude/settings.json`.

## Usage

```
/toggle-plugin list                    # List installed plugins
/toggle-plugin enable runpod           # Enable runpod in this project
/toggle-plugin disable runpod          # Disable runpod in this project
/toggle-plugin --local enable runpod   # Write to settings.local.json instead
```

## How it works

Globally disabled plugins can be enabled per-project by adding entries to `.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "runpod@pokutuna-plugins": true,
    "vertexai-gemini-batch@pokutuna-plugins": true
  }
}
```

Use `--local` to write to `.claude/settings.local.json` (gitignored).
