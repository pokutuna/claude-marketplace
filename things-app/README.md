# things-app

Read and update tasks in [Things 3](https://culturedcode.com/things/) via JXA (JavaScript for Automation).

## Requirements

- macOS with Things 3 installed

## Features

- List tasks from Today, Inbox, projects, and areas
- View task details (status, due date, tags, notes, etc.)
- Create new tasks with notes, due dates, tags, and project/area assignment
- Update tasks (title, notes, due date, tags, Today, area, project)
- Complete, cancel, reopen, and delete tasks

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
| `update <id>` | Update task properties |
| `complete <id>` | Mark as done |
| `cancel <id>` | Mark as canceled |
| `reopen <id>` | Reopen completed/canceled task |
| `delete <id>` | Move to Trash |

List commands support `--done`, `--offset N`, and `--limit N` options.

`update` supports `--name`, `--notes`, `--due`, `--tags`, `--add-tags`, `--remove-tags`, `--today`, `--no-today`, `--area`, `--project`.

## Installation

```
/plugin install things-app@pokutuna-plugins
```
