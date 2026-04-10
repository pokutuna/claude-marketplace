# octave-notification

Play musical scale notification sounds based on tmux window index. Each window gets a unique pitch, so you can tell which session completed by ear.

## How it works

A `Notification` hook plays a bell-like WAV file when Claude Code sends a notification (e.g., task completion after being idle for 6+ seconds). The pitch corresponds to the current tmux window index.

- Supports macOS (`afplay`) and Linux (`paplay`, `pw-play`, `aplay`)
- Falls back to the lowest note (C4) if not in tmux or window index exceeds range

## Sound map

22 notes: B3 + 3 octaves (C4 - B6), mapped to tmux window index 0-21. Index 1 = C4 (Do), so `base-index 1` users get Do-Re-Mi starting from the first window.

| Index | Note | Frequency (Hz) |
|------:|:-----|----------------:|
|     0 | B3   |          246.95 |
|     1 | C4   |          261.63 |
|     2 | D4   |          293.67 |
|     3 | E4   |          329.63 |
|     4 | F4   |          349.23 |
|     5 | G4   |          392.00 |
|     6 | A4   |          440.01 |
|     7 | B4   |          493.89 |
|     8 | C5   |          523.26 |
|     9 | D5   |          587.34 |
|    10 | E5   |          659.27 |
|    11 | F5   |          698.47 |
|    12 | G5   |          784.00 |
|    13 | A5   |          880.01 |
|    14 | B5   |          987.78 |
|    15 | C6   |         1046.52 |
|    16 | D6   |         1174.68 |
|    17 | E6   |         1318.53 |
|    18 | F6   |         1396.94 |
|    19 | G6   |         1568.01 |
|    20 | A6   |         1760.03 |
|    21 | B6   |         1975.57 |

Window index > 21 uses B6 (the highest note).

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
