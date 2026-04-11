# zoom

Extract transcripts from Zoom recording share pages via Playwright.

## Requirements

One of the following Playwright integrations:

- **playwright MCP** (recommended): `npx @playwright/mcp` — configure in `.mcp.json`
- **playwright-cli**: `npm install -g playwright-cli`

## Skills

### zoom-transcript

Extract VTT transcript from a Zoom recording share URL.

**Input:** Recording share URL, passcode (if required), output file path

**How it works:**
1. Opens the recording page in a browser via Playwright (MCP or CLI)
2. Enters the passcode if needed
3. Captures the VTT transcript endpoint from network requests
4. Fetches the VTT using the authenticated browser session and saves to file

## Installation

```
/plugin install zoom@pokutuna-plugins
```
