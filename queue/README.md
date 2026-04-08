# queue

Task queue for Claude Code. Queue prompts with `:qu` and execute them later.

## Commands

| Command | Description |
|---------|-------------|
| `:qu MESSAGE` | Add MESSAGE to the queue |
| `:qu` / `:qu list` | Show queued items |
| `:qu del N` | Delete Nth item |
| `:qu clear` | Clear the queue |
| `:qu next` | Dequeue and execute the next item |
| `:qu auto` | Enable auto-dequeue on task completion |
| `:qu auto off` | Disable auto-dequeue (default) |
| `:qu help` | Show help |

## How it works

- **UserPromptSubmit hook** intercepts `:qu` prefixed input, stores messages in a git-config file, and blocks the prompt via `decision: "block"` with a `reason` message
- **Stop hook** fires when Claude finishes responding:
  - **manual mode** (default): notifies that queued tasks are waiting
  - **auto mode** (`:qu auto`): pops the next item and injects it via `additionalContext`
- When you submit a normal prompt with items in the queue, a status line shows the queue count
- Multiline messages are supported (git-config escapes `\n` internally)

## Storage

State is stored in `${XDG_STATE_HOME:-~/.local/state}/claude-queue.conf` using git-config format. Each session gets its own section:

```ini
[session "<CLAUDE_SESSION_ID>"]
  item = first task
  item = second task
  auto = true
```

## Install

```
/plugin marketplace add pokutuna/claude-plugins queue
```

## Test

```
cd queue && make check
```

Requires [bats-core](https://github.com/bats-core/bats-core).
