# zoom

Extract transcripts and download videos from Zoom recording share pages via Playwright.

## Requirements

One of the following Playwright integrations:

- **playwright MCP** (recommended): `npx @playwright/mcp` — configure in `.mcp.json`
- **playwright-cli**: `npm install -g playwright-cli`

The `zoom-video-download` skill additionally requires `uv` and `curl` (curl is preinstalled on
macOS/Linux).

## Skills

### zoom-transcript

Extract VTT transcript from a Zoom recording share URL.

**Input:** Recording share URL, passcode (if required), output file path

**How it works:**
1. Opens the recording page in a browser via Playwright (MCP or CLI)
2. Enters the passcode if needed
3. Captures the VTT transcript endpoint from network requests
4. Fetches the VTT using the authenticated browser session and saves to file

### zoom-video-download

Download the MP4 video from a Zoom recording share URL.

**Input:** Recording share URL, passcode (if required), output file path

**How it works:**
1. Opens the recording page in a browser and enters the passcode if needed
2. Reads the highest-resolution `<video>` source URL directly from the page (`ssrweb.zoom.us` MP4)
3. Exports the browser session cookies
4. Downloads the MP4 with `curl` using those cookies + a `Referer` header (the signed URL alone is
   not enough — Zoom requires the session cookies and Referer)

With `playwright-cli`, the whole flow runs deterministically via the bundled helper script
(`scripts/download_zoom_video.py`, run with `uv`). With the playwright MCP server, the same steps
are performed via MCP tools (see SKILL.md).

## Installation

```
/plugin install zoom@pokutuna-plugins
```
