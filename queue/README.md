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
| `:qu run` | Start running the queue (auto-dequeue on task completion) |
| `:qu stop` | Stop running the queue |
| `:qu help` | Show help |

## How it works

- **UserPromptSubmit hook** intercepts `:qu` prefixed input, stores messages in a git-config file, and blocks the prompt via `decision: "block"` with a `reason` message
- **Stop hook** fires when Claude finishes responding:
  - **manual mode** (default): notifies that queued tasks are waiting
  - **auto mode** (`:qu run`): pops the next item and blocks stop to continue with the task
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

## Limitations

- `:qu` commands only work when Claude is idle (waiting for input). Messages sent during active execution bypass `UserPromptSubmit` hooks entirely — this is a known Claude Code bug ([anthropics/claude-code#31114](https://github.com/anthropics/claude-code/issues/31114))
- `Original prompt: ...` line is always shown when a prompt is blocked — this is a Claude Code display behavior that cannot be suppressed by hooks

### Related Issues

- [#31114](https://github.com/anthropics/claude-code/issues/31114) — UserPromptSubmit hooks not fired when user sends message mid-turn (regression)
- [#33323](https://github.com/anthropics/claude-code/issues/33323) — Task queue feature request (community workaround with Stop hook)
- [#44851](https://github.com/anthropics/claude-code/issues/44851) — Queue typed input instead of interrupting running task
- [#29224](https://github.com/anthropics/claude-code/issues/29224) — Side-channel responses for queued messages during active task execution
- [#41759](https://github.com/anthropics/claude-code/issues/41759) — Chained thought input — queue follow-up prompts while a task is in flight

## Test

```
cd queue && make check
```

Requires [bats-core](https://github.com/bats-core/bats-core).
