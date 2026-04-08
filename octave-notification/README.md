# octave-notification

Play musical scale notification sounds based on tmux window index. Each window gets a unique pitch, so you can tell which session completed by ear.

## How it works

A `Notification` hook plays a bell-like WAV file when Claude Code sends a notification (e.g., task completion after being idle for 6+ seconds). The pitch corresponds to the current tmux window index.

- Supports macOS (`afplay`) and Linux (`paplay`, `pw-play`, `aplay`)
- Falls back to the lowest note (C4) if not in tmux or window index exceeds range

## Sound map

21 notes across 3 octaves (C4 - B6), mapped to tmux window index 0-20:

| Index | Note | Frequency (Hz) |
|------:|:-----|----------------:|
|     0 | C4   |          261.63 |
|     1 | D4   |          293.67 |
|     2 | E4   |          329.63 |
|     3 | F4   |          349.23 |
|     4 | G4   |          392.00 |
|     5 | A4   |          440.01 |
|     6 | B4   |          493.89 |
|     7 | C5   |          523.26 |
|     8 | D5   |          587.34 |
|     9 | E5   |          659.27 |
|    10 | F5   |          698.47 |
|    11 | G5   |          784.00 |
|    12 | A5   |          880.01 |
|    13 | B5   |          987.78 |
|    14 | C6   |         1046.52 |
|    15 | D6   |         1174.68 |
|    16 | E6   |         1318.53 |
|    17 | F6   |         1396.94 |
|    18 | G6   |         1568.01 |
|    19 | A6   |         1760.03 |
|    20 | B6   |         1975.57 |

Window index > 20 uses B6 (the highest note).

## Files

```
octave-notification/
  .claude-plugin/plugin.json   # Plugin manifest
  hooks/hooks.json             # Notification hook definition
  bin/generate-sounds.py       # WAV generator script (uv run compatible)
  bin/play-notification.sh     # Playback script (macOS/Linux)
  sounds/bell_{0..20}.wav      # Pre-generated bell sounds
```

## Regenerating sounds

```sh
uv run bin/generate-sounds.py
```
