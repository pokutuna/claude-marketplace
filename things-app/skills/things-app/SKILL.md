---
name: things-app
description: |
  Read and update tasks in Things 3 app via JXA.
  Use when user mentions "things", "today tasks", "inbox", "todo", "タスク",
  "what's on my plate", "things project", "things area", "今日のタスク".
metadata:
  author: pokutuna
  version: 0.1.0
  compatibility: macOS with Things 3 installed
allowed-tools: "Bash(osascript -l JavaScript ${CLAUDE_PLUGIN_ROOT}/skills/things-app/scripts/things.js *)"
---

# Things 3

Read and update tasks in Things 3 via JXA (JavaScript for Automation).

## Prerequisites

- macOS with Things 3 installed

## Script

All commands use a single script:

```
osascript -l JavaScript ${CLAUDE_PLUGIN_ROOT}/skills/things-app/scripts/things.js <command> [options]
```

## Read Commands

### today — Today's tasks

```bash
osascript -l JavaScript ${CLAUDE_PLUGIN_ROOT}/skills/things-app/scripts/things.js today
osascript -l JavaScript ${CLAUDE_PLUGIN_ROOT}/skills/things-app/scripts/things.js today --done
```

### inbox — Inbox tasks

```bash
osascript -l JavaScript ${CLAUDE_PLUGIN_ROOT}/skills/things-app/scripts/things.js inbox
osascript -l JavaScript ${CLAUDE_PLUGIN_ROOT}/skills/things-app/scripts/things.js inbox --limit 10
```

### projects — List all projects and areas

```bash
osascript -l JavaScript ${CLAUDE_PLUGIN_ROOT}/skills/things-app/scripts/things.js projects
```

### project / area — Tasks in a specific project or area

```bash
osascript -l JavaScript ${CLAUDE_PLUGIN_ROOT}/skills/things-app/scripts/things.js project "プロジェクト名"
osascript -l JavaScript ${CLAUDE_PLUGIN_ROOT}/skills/things-app/scripts/things.js area "エリア名"
```

### detail — Single task detail (by ID or name)

```bash
osascript -l JavaScript ${CLAUDE_PLUGIN_ROOT}/skills/things-app/scripts/things.js detail "タスクID"
```

IDs are shown in list output as `[ID: ...]`. Use them directly.

## Create Commands

### create — Create a new task

```bash
osascript -l JavaScript ${CLAUDE_PLUGIN_ROOT}/skills/things-app/scripts/things.js create "タスク名"
osascript -l JavaScript ${CLAUDE_PLUGIN_ROOT}/skills/things-app/scripts/things.js create "タスク名" --notes "メモ" --due "2026-04-10" --tags "tag1, tag2"
osascript -l JavaScript ${CLAUDE_PLUGIN_ROOT}/skills/things-app/scripts/things.js create "タスク名" --project "プロジェクト名"
osascript -l JavaScript ${CLAUDE_PLUGIN_ROOT}/skills/things-app/scripts/things.js create "タスク名" --area "エリア名" --today
```

| Option | Description |
|--------|-------------|
| `--notes "..."` | Add notes |
| `--due "YYYY-MM-DD"` | Set deadline |
| `--tags "t1, t2"` | Comma-separated tag names |
| `--project "..."` | Add to project |
| `--area "..."` | Add to area |
| `--today` | Also move to Today |

Default destination is Inbox. `--project` and `--area` override it.

## Update Commands

### set-today — Move task to/from Today

```bash
osascript -l JavaScript ${CLAUDE_PLUGIN_ROOT}/skills/things-app/scripts/things.js set-today "タスクID" on
osascript -l JavaScript ${CLAUDE_PLUGIN_ROOT}/skills/things-app/scripts/things.js set-today "タスクID" off
```

### update — Update task title or notes

```bash
osascript -l JavaScript ${CLAUDE_PLUGIN_ROOT}/skills/things-app/scripts/things.js update "タスクID" --name "新しいタイトル"
osascript -l JavaScript ${CLAUDE_PLUGIN_ROOT}/skills/things-app/scripts/things.js update "タスクID" --notes "新しいメモ"
osascript -l JavaScript ${CLAUDE_PLUGIN_ROOT}/skills/things-app/scripts/things.js update "タスクID" --name "タイトル" --notes "メモ"
```

## Common Options (for list commands)

| Option | Description |
|--------|-------------|
| `--done` | Include completed/canceled tasks |
| `--offset N` | Skip first N tasks (paging) |
| `--limit N` | Max tasks to return (default: 30) |

## Output Format

### List (one-line per task)

```
- タスク名 (Today, Due: 2025-01-15) #tag1, #tag2 [ID: abc123]
```

Components:
- Task name. If title is empty, shows `(note) first 20 chars...` from notes
- Parentheses: Today flag, due date, done/canceled status
- Tags as `#tag`
- `[ID: ...]` for use with detail/update/set-today/create commands

### Detail

```
タスク名

ID: abc123
Status: open
Today: Yes
Due: 2025-01-15
Tags: #tag1, #tag2
Project: プロジェクト名
Area: エリア名

Notes:
ノート内容
```

## Important Notes

- Update commands modify actual tasks — always confirm with the user before running
- List names are resolved dynamically (works in any locale)
- Paging: use `--offset` and `--limit` for large lists (e.g. inbox)
