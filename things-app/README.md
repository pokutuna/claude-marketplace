# things-app

Read and update tasks in [Things 3](https://culturedcode.com/things/) via JXA (JavaScript for Automation).

## Requirements

- macOS with Things 3 installed

## Features

- List tasks from Today, Inbox, projects, and areas
- View task details (status, due date, tags, notes, etc.)
- Create new tasks with notes, due dates, tags, and project/area assignment
- Update task titles and notes
- Move tasks to/from Today

## Commands

| Command | Description |
|---------|-------------|
| `today` | Show today's tasks |
| `inbox` | Show inbox tasks |
| `projects` | List all projects and areas |
| `project <name>` | Show tasks in a project |
| `area <name>` | Show tasks in an area |
| `detail <id>` | Show task details |
| `create <title>` | Create a new task |
| `update <id>` | Update task title or notes |
| `set-today <id> on/off` | Move task to/from Today |

All list commands support `--done`, `--offset N`, and `--limit N` options.

## Installation

```
/plugin install things-app@pokutuna-plugins
```
