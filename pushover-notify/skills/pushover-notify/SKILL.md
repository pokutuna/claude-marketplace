---
name: pushover-notify
description: Pushover による通知の送信、および通知 hook の toggle。"pushover で通知", "pushover on/off/toggle/status" などで起動。
argument-hint: "<message> | on | off | toggle | status"
metadata:
  author: pokutuna
allowed-tools:
  - "Bash(${CLAUDE_PLUGIN_ROOT}/bin/notify.sh *)"
---

## When to send a notification

"pushover で通知して", "終わったら pushover で知らせて", "結果を push で送って" などは send。

Preset 選択:

- Success / done → `--done "メッセージ"`
- Error / failure → `--error "メッセージ"`
- Critical / must-acknowledge → `--emergency "メッセージ"`
- Custom → `-t TITLE -p PRIORITY -s SOUND` etc.

Examples:

```bash
${CLAUDE_PLUGIN_ROOT}/bin/notify.sh send --done "ビルド完了"
${CLAUDE_PLUGIN_ROOT}/bin/notify.sh send -p high -s siren "デプロイ失敗"
echo "$LONG_OUTPUT" | ${CLAUDE_PLUGIN_ROOT}/bin/notify.sh send -t "summary"
```

## When to toggle the hook

- "pushover on" / "有効化" → `enable`
- "pushover off" / "無効化" → `disable`
- "pushover toggle" / 状態を切り替え → `toggle`
- "pushover status" / 状態を見せて → `status`

## Disambiguation

"pushover" だけ (verb なし) の時は send か toggle か聞く。
