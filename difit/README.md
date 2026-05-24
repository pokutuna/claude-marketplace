# difit

Plugin for round-trip code review with [difit](https://github.com/yoshiko-pg/difit) — a local diff viewer that lets humans leave line comments and the agent read them back.

## What it adds

- **`skills/difit-review`** — the main artifact. Instructs the agent to:
  - launch difit with AI-authored line comments preloaded (`--comment` with `author: "ai"` and a `[ai]` body prefix so the human can spot AI comments at a glance),
  - exchange comments with the human over difit's HTTP API **while the server keeps running** — no process kill required, no restart between rounds,
  - distinguish human vs. AI comments by the `author` field,
  - reply with `difit comment add` using `filePath` + `position` to attach to existing threads.
- **`bin/difit-comments`** — a small helper that wraps `GET /api/comments-json` and trims the response to just the fields the agent needs to reply: thread `id`, `filePath`, `position`, `codeSnapshot` (flattened), and `messages: [{author, body}]`. Timestamps, message IDs, and version metadata are dropped so the agent doesn't have to parse around them.

## Why

The natural pattern an agent reaches for is "open the diff viewer, wait for the human to type comments, then read them when closing the viewer". With difit, closing the viewer is `SIGINT`-only — any other signal discards the unflushed output and loses the comments. Worse, agents routinely use `kill <pid>` to "close" a background process.

The right answer is to **not use signal-based retrieval at all**. difit exposes an HTTP API (`comment get` / `comment add`) that reads and writes the running server's state directly. This plugin pushes the agent toward that API for the entire review loop, so the server can stay up for as long as the user wants and shutdown becomes a non-event.

## Use cases

- **AI explains its own code to a human reviewer.** After the agent makes changes, it opens difit and attaches line comments saying *what* it did, *why*, and *which parts need human judgement*. The human reviews in the browser and replies inline. The agent picks up replies and addresses them.
- **AI reviews human-written code.** Same flow, but with findings instead of explanations.
- **Q&A loop in a single session.** Human asks → AI replies in difit → human follow-up → AI answers, all without restarting difit.

## Setup

1. Install difit: `npm i -g difit` (so `difit` is on `$PATH`).
2. Enable this plugin. The skill calls `${CLAUDE_PLUGIN_ROOT}/bin/difit-comments` directly — no extra `$PATH` setup needed.

## See also

- `skills/difit-review/SKILL.md` — full skill documentation (start there).
- [difit upstream](https://github.com/yoshiko-pg/difit) — the diff viewer itself, including the `difit comment add` / `difit comment get` subcommands this plugin relies on.
