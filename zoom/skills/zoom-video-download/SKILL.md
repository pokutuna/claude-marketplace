---
name: zoom-video-download
description: Download the video (MP4) from a Zoom recording share page. "zoom video download", "zoom 録画 ダウンロード", "zoom 動画 ダウンロード" などで起動。
compatibility: Requires playwright-cli (or playwright MCP), uv, and curl
allowed-tools: "Bash(uv run *),Bash(playwright-cli *),Bash(curl *),Bash(python3 *),mcp__playwright__browser_navigate,mcp__playwright__browser_snapshot,mcp__playwright__browser_fill_form,mcp__playwright__browser_click,mcp__playwright__browser_evaluate,mcp__playwright__browser_run_code,mcp__playwright__browser_close"
---

# Zoom Recording Video Download

Download the MP4 video from a Zoom recording share page.

A Zoom recording is served as one or more **single MP4 files** (not HLS segments) from
`ssrweb.zoom.us`. The signed URL alone is NOT enough to download — the server also requires the
session **cookies** and a `Referer` header (any `zoom.us` value works; the host need not match the
recording's region). The flow is therefore:

1. Open the recording in a browser (establishes the authenticated session).
2. Enter the passcode if required.
3. Read the highest-resolution `<video>` source URL directly from the play page.
4. Export the browser cookies.
5. Download with `curl` using those cookies + a `Referer` header (curl streams, resumes, and shows
   progress for the large file).

## Required User Input

Ask the user for:
1. **Recording share URL** (e.g. `https://<region>.zoom.us/rec/share/...`)
2. **Passcode** (if the recording is passcode-protected — some recordings need only the URL)
3. **Output file path** (where to save the `.mp4`; default to the recording title)

## Primary path: deterministic helper script (playwright-cli)

When `playwright-cli` is available, run the bundled script — it performs the entire flow
(navigate → passcode → URL extraction → cookie export → curl download) deterministically in one
command:

```bash
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/zoom-video-download/scripts/download_zoom_video.py \
  --url '<recording_share_url>' \
  --output '<output_file_path>' \
  --passcode '<passcode>'   # omit if the recording has no passcode
```

Notes:
- Pass `--passcode` as a single argument; the script JSON-encodes it internally, so
  shell-special characters in the passcode are handled safely. **Single-quote it** so the shell
  does not interpret `#`, `!`, `$`, etc. (e.g. `--passcode '#jZ4R==v'`).
- **Run it in the foreground and wait for it to finish.** The download is several hundred MB and
  can take 1–2 minutes; use a generous command timeout. Do not background it and report before it
  exits — wait for the exit code. The script prints curl progress to stderr and the final saved
  path to stdout. It supports resume (`curl -C -`); re-running continues an interrupted download,
  and re-running on an already-complete file is a no-op success (exit 0). Transient curl errors
  are retried automatically (3 attempts).
- `--keep-open` leaves the browser open (useful for debugging); by default the browser is closed
  as soon as the video URL and cookies are extracted — including on failure (wrong passcode etc.),
  so no stray browser is left behind.
- The script verifies the output is a non-empty MP4 before exiting. Exit codes: `0` success,
  `2` passcode required but not given, `3` no `<video>` source found, `4` download failed
  (curl error / HTTP non-2xx / empty or non-MP4 output), `5` passcode incorrect.

Verify afterwards that the output is a valid MP4 (e.g. `ffprobe`).

If `playwright-cli` is not installed: `npm install -g playwright-cli` (and `uv` for the script).

## Alternative path: playwright MCP (manual steps)

If only the **playwright MCP** server is available (no `playwright-cli`), perform the same flow
with MCP tools. The helper script's logic, step by step:

### 1. Navigate

Call `mcp__playwright__browser_navigate` with the recording share URL. If the page title is
"パスコードが必要" / "Passcode required", do step 2; otherwise skip to step 3.

### 2. Enter passcode

1. `mcp__playwright__browser_snapshot` — find the passcode input and submit button refs
2. `mcp__playwright__browser_fill_form` — fill the passcode
3. `mcp__playwright__browser_click` — click "レコーディングを視聴" / "Watch recording"

The page then navigates to `.../rec/play/...`.

### 3. Read the highest-resolution video URL

Call `mcp__playwright__browser_evaluate` with this function (no need to press Play). A recording
usually has two `<video>` elements — `..._as_<W>x<H>.mp4` (high-res shared screen) and
`..._avo_<W>x<H>.mp4` (low-res speaker overlay); pick the largest by width:

```javascript
() => {
  const vids = Array.from(document.querySelectorAll('video'));
  const scored = vids.map(v => {
    const u = v.currentSrc || v.src;
    const m = u && u.match(/_(\d+)x(\d+)\.mp4/);
    return { url: u, w: m ? parseInt(m[1], 10) : 0 };
  }).filter(x => x.url);
  scored.sort((a, b) => b.w - a.w);
  return scored[0] ? scored[0].url : '';
}
```

If empty, the player may still be loading (retry), or the recording is audio-only / download-disabled.

### 4. Export cookies

Call `mcp__playwright__browser_run_code` with this function and save the returned text to a file
(e.g. `/tmp/zoom_cookies.txt`):

```javascript
async (page) => {
  const cookies = await page.context().cookies();
  const lines = ['# Netscape HTTP Cookie File'];
  for (const c of cookies) {
    const includeSub = c.domain.startsWith('.') ? 'TRUE' : 'FALSE';
    const secure = c.secure ? 'TRUE' : 'FALSE';
    const expires = c.expires && c.expires > 0 ? Math.floor(c.expires) : 0;
    lines.push([c.domain, includeSub, c.path || '/', secure, expires, c.name, c.value].join('\t'));
  }
  return lines.join('\n');
}
```

### 5. Download with curl

```bash
UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36'
curl --fail -C - -o '<output_file_path>' \
  -b /tmp/zoom_cookies.txt \
  -H "Referer: https://zoom.us/" \
  -H "User-Agent: $UA" \
  -w 'DONE http=%{http_code} size=%{size_download} time=%{time_total}s\n' \
  '<video_url>'
```

### 6. Clean up

Call `mcp__playwright__browser_close`; remove the temp cookie file.

## Troubleshooting

- **curl returns 403**: cookies or the `Referer` header are missing/expired. Re-export cookies
  (step 4) while the browser session is still open, and confirm `Referer` is set. The signed URL
  is NOT self-authenticating — both cookies and a `Referer` are required.
- **No `<video>` element / empty URL**: the player may still be loading (retry), or the recording
  is download-disabled or audio-only.
- **Want the speaker overlay too**: each `<video>` is a separate file (`_as_` = shared screen,
  `_avo_` = small speaker overlay). Download both URLs if needed; mux with `ffmpeg` only if you
  specifically need them combined.
- **Signed URL expired mid-download**: the URL has a time limit (`DateLessThan` in its policy). If
  resume fails, re-run to fetch a fresh URL, then resume.
- **Video looks small / very low bitrate**: this is usually normal. The `_as_` track is a
  screen/slide share; for mostly-static content (slides, code) even a 1080p recording can be a few
  hundred kbps. That is the source bitrate, not a wrong-track selection — there is no higher-quality
  source to fetch (Zoom serves only the `_as_` and `_avo_` files, no adaptive/HLS variants).
