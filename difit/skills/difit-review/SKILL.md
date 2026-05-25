---
name: difit-review
description: Round-trip code review through difit. Use when the user mentions "difit", "diff review", "open the diff", "let me look at this", or "review this PR locally".
metadata:
  author: pokutuna
  version: 0.2.0
allowed-tools:
  - "Bash(${CLAUDE_PLUGIN_ROOT}/bin/difit-comments *)"
  - "Bash(difit *)"
  - "Bash(kill -INT *)"
  - "Bash(lsof -ti *)"
---

# difit-review

Open a diff in [difit](https://github.com/yoshiko-pg/difit) (a local diff viewer) with AI-authored line comments preloaded, then loop with the human reviewer over difit's HTTP API: the human writes replies in the browser, you read them while the server keeps running, and answer back with `difit comment add`.

Two symmetric use cases, same flow:

- **AI explains its own code to a human reviewer.** After you (the AI) finish a change, open difit and attach line comments that say "here's what I did", "why I did it this way", and "this part needs your judgement".
- **AI reviews human-written code.** Same flow, but the comments are findings ("this branch can throw NPE", "consider X") instead of explanations.

A single difit session can go both ways — human asks a question, AI answers, AI raises a new finding, etc.

## Core principle: HTTP API, not signals

difit lets you exchange comments **while the server keeps running** via its HTTP API. This skill uses the API exclusively:

- Never kill the process to retrieve comments. Killing is for ending the session, not for fetching state.
- The server can stay up for the entire review loop. Re-querying is cheap.

`difit` must be on `$PATH` (`npm i -g difit`). If it isn't, stop and tell the user — no fallback.

## Step 1 — Open difit with your initial comments

Decide what to attach as line comments before launching. Cover, in order of priority:

1. Points where you specifically want human judgement ("not sure if this matches the convention you want").
2. The intent / why behind non-obvious changes.
3. A short summary of each substantial change ("extracted parseFoo from bar(); behaviour preserved").

Set `author: "ai"` on every comment so AI-authored comments are distinguishable both programmatically and in the browser UI (difit renders `author` as a label). Write the body in the user's language.

```bash
difit <target> [compare-with] --keep-alive \
  --comment '{"type":"thread","author":"ai","filePath":"src/foo.ts","position":{"side":"new","line":42},"body":"Extracted parseFoo() — pure refactor, no behaviour change. Want a sanity-check on naming."}' \
  --comment '{"type":"thread","author":"ai","filePath":"src/bar.ts","position":{"side":"new","line":{"start":10,"end":18}},"body":"New error path for the 429 case. Intentionally bubbles up; please confirm that''s what you want."}'
```

**`--keep-alive` is mandatory.** Without it, difit exits as soon as the browser tab disconnects (SSE close), and subsequent HTTP API calls will fail with connection refused.

Target conventions:

- `difit` — review HEAD commit
- `difit .` — review uncommitted changes (add `--include-untracked` to include un-`git add`-ed files)
- `difit staged` / `difit working` — staged / unstaged only
- **Review what the current branch added on top of `main` (the common case for PR review)**: `difit HEAD main --merge-base` — equivalent to `git diff main...HEAD`. **Always pass `--merge-base`**; without it difit defaults to `git diff main..HEAD` (two-dot), which leaks back any commits that landed on `main` after the branch diverged. Two-dot is almost never what you want.

Comment payload notes:

- `type` must be `thread` for new top-level threads, `reply` to add to an existing one (rare at launch time).
- `position.side`: `new` for lines on the target side, `old` for lines only on the deleted side.
- Use `position.line: {start, end}` for ranges.
- **Never put secrets, tokens, or credentials in `--comment` arguments** — they go on the command line.

### Launch in the background

Run difit as a background task so you can keep working and still query its HTTP API. **Capture the port from the startup output** — every API call below needs it.

```bash
# example (run_in_background: true)
difit . --keep-alive --comment '...'
```

Then tell the user the URL.

## Step 2 — Pick up the human's comments

When the user signals they're done reviewing (or asks you to "pick up", "fetch", "see what they wrote"), query the running server with the bundled helper. **No need to stop or restart difit** — leave it running for the rest of the loop.

```bash
${CLAUDE_PLUGIN_ROOT}/bin/difit-comments <port>
```

This returns a JSON array of threads with only the fields you need to reply: `id`, `filePath`, `position`, `codeSnapshot` (flattened to the line's code, or `null`), and `messages: [{author, body}]`. Timestamps and message IDs are dropped — they're not needed for the reply flow and would just be noise.

Treat the result like this:

- `author == "ai"` → your own past comment. Skip unless you need it for context.
- `author` anything else (often empty) → human comment / reply. Address it.
- `codeSnapshot` is the snippet at the commented line. Use it instead of `Read`-ing the file when you just need to see the few lines under discussion.

You can call this as many times as you want during the session; the server's state is the source of truth.

## Step 3 — Reply inline

To add new replies or new comments to the running session, use `difit comment add`. A reply attaches to an existing thread by matching `filePath` + `position` (not by a thread id), so the payload looks just like a thread comment with `type: "reply"`:

```bash
# Reply to the thread on src/foo.ts:42
difit comment add --port <port> \
  '{"type":"reply","author":"ai","filePath":"src/foo.ts","position":{"side":"new","line":42},"body":"Good catch — fixed in the next commit."}'

# A brand new finding on a new line:
difit comment add --port <port> \
  '{"type":"thread","author":"ai","filePath":"src/foo.ts","position":{"side":"new","line":99},"body":"Realised this branch needs a unit test. Adding one."}'
```

The human sees new threads / replies live in the browser. Then go back to Step 2 when they reply. This is the entire loop — Step 2 ↔ Step 3, indefinitely.

## Step 4 — Ending the session

Stop difit when one of these happens:

1. The user explicitly tells you to close / stop / quit it.
2. The review loop is clearly over — the user moves on to creating a PR, commits and walks away, or switches to an unrelated task. Don't keep difit running just because no one said to stop.

Before stopping, run `${CLAUDE_PLUGIN_ROOT}/bin/difit-comments <port>` one more time so you've collected the latest replies. Then send `SIGINT` — look up the PID from the port:

```bash
kill -INT "$(lsof -ti :<port>)"
```

`SIGINT` only. **Never use plain `kill`, `pkill`, or `kill -9`** — difit only handles `SIGINT` and any other signal discards in-flight state.

There is **no "Finish Review" button** in difit's UI. Do not tell the user to press one. If you need a signal from the human, ask plainly: "let me know when you've finished commenting and I'll pick them up".

## Reference: comment JSON shape

```json
{
  "type": "thread",        // "thread" for a new top-level comment, "reply" to extend an existing one
  "author": "ai",          // free-form string; "ai" by convention for this skill
  "filePath": "src/x.ts",  // repo-relative path
  "position": {
    "side": "new",         // "new" = post-change side, "old" = deleted side
    "line": 42             // or { "start": 36, "end": 39 } for a range
  },
  "body": "comment text in the user's language"
}
```

Replies use `type: "reply"` and the same `filePath` + `position` as the thread they attach to. There is no separate thread-id field.

## Constraints

- Only works inside a git-managed directory.
- The server holds state in memory — if it dies abnormally (`kill -9`, crash, host restart), in-flight comments are gone. The HTTP API flow makes this rare in practice because you fetch eagerly.
- difit listens on `localhost` only; the port is dynamic — capture it from startup output.
