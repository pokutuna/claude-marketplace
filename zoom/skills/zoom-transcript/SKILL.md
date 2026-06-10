---
name: zoom-transcript
description: Extract VTT transcript from a Zoom recording share page. "zoom transcript", "zoom 文字起こし" などで起動。
metadata:
  author: pokutuna
  compatibility: Requires playwright-cli or playwright MCP server (@playwright/mcp)
allowed-tools: "Bash(playwright-cli open *),Bash(playwright-cli goto *),Bash(playwright-cli snapshot *),Bash(playwright-cli fill *),Bash(playwright-cli click *),Bash(playwright-cli network *),Bash(playwright-cli run-code *),Bash(playwright-cli close *),mcp__playwright__browser_navigate,mcp__playwright__browser_snapshot,mcp__playwright__browser_fill_form,mcp__playwright__browser_click,mcp__playwright__browser_network_requests,mcp__playwright__browser_run_code,mcp__playwright__browser_close"
---

# Zoom Transcript Extraction

Extract VTT transcripts from Zoom recording share pages using Playwright.

## Prerequisites Check

This skill supports two Playwright backends. Detect which is available:

1. **playwright MCP** — `mcp__playwright__browser_navigate` tool exists → use MCP tools
2. **playwright-cli** — `playwright-cli --version` succeeds → use CLI commands

If neither is available, tell the user to install one:
- MCP: `npx @playwright/mcp` (configure in `.mcp.json`)
- CLI: `npm install -g playwright-cli`

## Required User Input

Ask the user for:
1. **Recording share URL** (e.g. `https://<region>.zoom.us/rec/share/...`)
2. **Passcode** (if the recording is passcode-protected)
3. **Output file path** (where to save the VTT transcript)

## Procedure

Each step shows both backends. Use whichever is available.

### Step 1: Open browser and navigate

**MCP:**
Call `mcp__playwright__browser_navigate` with the recording share URL.

**CLI:**
```bash
playwright-cli open --browser=chrome
playwright-cli goto '<recording_share_url>'
```

### Step 2: Enter passcode (if required)

Take a snapshot to identify form element refs, then fill and submit.

**MCP:**
1. `mcp__playwright__browser_snapshot`
2. `mcp__playwright__browser_fill_form` — ref of passcode input, value = passcode
3. `mcp__playwright__browser_click` — ref of submit button

**CLI:**
```bash
playwright-cli snapshot
playwright-cli fill <passcode_input_ref> '<passcode>'
playwright-cli click <submit_button_ref>
```

Wait for the recording page to load, then take another snapshot to confirm.

### Step 3: Find VTT transcript endpoint

**MCP:**
Call `mcp__playwright__browser_network_requests`.

**CLI:**
```bash
playwright-cli network
```

Look for a request matching `type=transcript` in the URL:
```
[GET] https://...zoom.us/rec/play/vtt?type=transcript&fid=...&action=play => [200]
```

Copy the full URL. If not found, the recording may not have a transcript — inform the user.

### Step 4: Fetch VTT and save

Use `run-code` to fetch the VTT via the authenticated browser session.

**MCP:**
Call `mcp__playwright__browser_run_code` with code:
```javascript
async ({ page }) => {
  const resp = await page.request.get('<vtt_url>');
  return await resp.text();
}
```

The result is the VTT text. Write it to the output file.

**CLI:**
```bash
playwright-cli run-code "async page => {
  const resp = await page.request.get('<vtt_url>');
  return await resp.text();
}" > /tmp/zoom_vtt_raw.txt
```

The output format: first line is `### Result`, second line is the JSON-encoded VTT string.
Decode the JSON string and write to the output file:

```bash
python3 -c "
import json, sys
lines = open(sys.argv[1]).read().split('\n')
print(json.loads(lines[1]))
" /tmp/zoom_vtt_raw.txt > '<output_file_path>'
rm -f /tmp/zoom_vtt_raw.txt
```

### Step 5: Clean up

**MCP:** Call `mcp__playwright__browser_close`.

**CLI:**
```bash
playwright-cli close
```

Report the output file path to the user.

## Troubleshooting

- **No `type=transcript` in network log**: The recording may not have audio transcription enabled. Check for `type=cc` (closed captions) as a fallback.
- **VTT fetch returns error**: The session cookie may have expired. Re-navigate to the recording page and retry.
- **Passcode form not found**: The recording may not require a passcode, or the page structure may differ. Take a snapshot to inspect.
