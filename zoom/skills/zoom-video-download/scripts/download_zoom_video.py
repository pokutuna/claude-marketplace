# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""Deterministically download the MP4 video from a Zoom recording share page.

Drives `playwright-cli` end-to-end:
  1. open browser + navigate to the share URL
  2. enter the passcode if the page asks for one
  3. read the highest-resolution <video> source URL from the play page
  4. export the session cookies as a Netscape jar
  5. download the MP4 with curl (cookies + Referer header), then sanity-check the file

The signed ssrweb.zoom.us URL is NOT self-authenticating: the server requires both the
session cookies and a Referer header (any zoom.us value works). curl handles streaming,
resume (-C -), and progress for the large file.

Requires: playwright-cli (`npm install -g playwright-cli`) and curl.

Exit codes:
  0  success (output is a non-empty MP4)
  1  a playwright-cli command failed
  2  the page requires a passcode but --passcode was not given
  3  no <video> source found (recording is audio-only or download-disabled)
  4  download failed (curl error / HTTP non-2xx / empty or non-MP4 output)
  5  the passcode appears to be incorrect

Usage:
  uv run --script download_zoom_video.py \
      --url 'https://<region>.zoom.us/rec/share/...' \
      --output 'recording.mp4' \
      [--passcode 'PASSCODE'] \
      [--browser chrome] [--keep-open] [--session NAME]
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import time

# A bare arrow-function expression (NO trailing semicolon) — passed to `playwright-cli eval`.
# Picks the highest-resolution <video> source by the _<W>x<H>.mp4 width in the filename.
PICK_VIDEO_URL_JS = r"""() => {
  const vids = Array.from(document.querySelectorAll('video'));
  const scored = vids.map(v => {
    const u = v.currentSrc || v.src;
    const m = u && u.match(/_(\d+)x(\d+)\.mp4/);
    return { url: u, w: m ? parseInt(m[1], 10) : 0 };
  }).filter(x => x.url);
  scored.sort((a, b) => b.w - a.w);
  return scored[0] ? scored[0].url : ''
}"""

# Bare async arrow-function (NO trailing semicolon) — passed to `playwright-cli run-code`.
# Exports the session cookies as a Netscape cookie jar string.
DUMP_COOKIES_JS = r"""async (page) => {
  const cookies = await page.context().cookies();
  const lines = ['# Netscape HTTP Cookie File'];
  for (const c of cookies) {
    const includeSub = c.domain.startsWith('.') ? 'TRUE' : 'FALSE';
    const secure = c.secure ? 'TRUE' : 'FALSE';
    const expires = c.expires && c.expires > 0 ? Math.floor(c.expires) : 0;
    lines.push([c.domain, includeSub, c.path || '/', secure, expires, c.name, c.value].join('\t'));
  }
  return lines.join('\n')
}"""

PASS_SELECTOR = "input[type=password], input#password, input[name=passwd]"

# Snapshot of the live page: URL, <video> count, and whether a passcode form is shown.
# Issued as a fresh eval per poll tick — a single run-code/eval is pinned to the page it
# started on and never observes a navigation that happens after it, so all waiting and
# polling lives on the Python side.
PAGE_STATE_JS = (
    "() => JSON.stringify({"
    " url: location.href,"
    " video: document.querySelectorAll('video').length,"
    " pass: !!document.querySelector(" + json.dumps(PASS_SELECTOR) + ")"
    " })"
)

UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36"
)


def log(msg: str) -> None:
    print(f"[zoom-dl] {msg}", file=sys.stderr, flush=True)


def pw(
    session: str | None, *args: str, raw: bool = False, check: bool = True
) -> str | None:
    """Run a playwright-cli command and return stdout (stripped).

    With check=False a failure returns None instead of exiting — used by poll loops,
    where an eval can transiently fail mid-navigation ("execution context destroyed").
    """
    cmd = ["playwright-cli"]
    if session:
        cmd.append(f"-s={session}")
    if raw:
        cmd.append("--raw")
    cmd += list(args)
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        if not check:
            return None
        log(f"command failed: {' '.join(cmd[:3])} ... (exit {proc.returncode})")
        log(proc.stderr.strip() or proc.stdout.strip())
        raise SystemExit(1)
    return proc.stdout.strip()


def decode_raw_string(out: str) -> str:
    """`--raw` returns a JSON-quoted string for string results; decode it."""
    out = out.strip()
    if out.startswith('"'):
        return json.loads(out)
    return out


def page_state(session: str | None) -> dict:
    """Read the live page state; transient failures yield {} rather than aborting."""
    out = pw(session, "eval", PAGE_STATE_JS, raw=True, check=False)
    if out is None:
        return {}
    try:
        state = json.loads(decode_raw_string(out))
        return state if isinstance(state, dict) else {}
    except (ValueError, TypeError):
        return {}


def wait_for_state(session: str | None, predicate, timeout_s: float) -> dict | None:
    """Poll the page state until predicate(state) is true; None on timeout."""
    deadline = time.monotonic() + timeout_s
    while True:
        state = page_state(session)
        if state and predicate(state):
            return state
        if time.monotonic() >= deadline:
            return None
        time.sleep(0.5)


def reached_play(state: dict) -> bool:
    return "/rec/play/" in state.get("url", "") or bool(state.get("video", 0))


def looks_like_mp4(path: str) -> bool:
    """Non-empty and an actual MP4 (ISO BMFF 'ftyp' box at offset 4)."""
    try:
        if os.path.getsize(path) == 0:
            return False
        with open(path, "rb") as fh:
            return fh.read(12)[4:8] == b"ftyp"
    except OSError:
        return False


def grab_video_url_and_cookies(args) -> tuple[str, str]:
    """Browser part of the flow: navigate, passcode, pick URL, export cookies."""
    log("navigating to share URL")
    pw(args.session, "goto", args.url)

    # Wait until the page reveals what it is: a passcode form, or the play page.
    # Checking the passcode input just once right after goto races a slow load and
    # misreads "no passcode needed".
    state = (
        wait_for_state(
            args.session, lambda s: s.get("pass") or reached_play(s), timeout_s=15
        )
        or {}
    )

    if state.get("pass"):
        if not args.passcode:
            log("page requires a passcode but --passcode was not provided")
            raise SystemExit(2)
        log("entering passcode")
        # Fill the passcode and submit. Keep this run-code call to JUST the submit: a single
        # run-code function is pinned to its starting page, so polling page.url() *inside* it
        # never observes the post-submit navigation. We poll from Python instead (below),
        # issuing a fresh `eval` each tick so we always read the current page.
        fill_js = (
            "async (page) => {"
            "  await page.fill("
            + json.dumps(PASS_SELECTOR)
            + ", "
            + json.dumps(args.passcode)
            + ");"
            "  await page.keyboard.press('Enter');"
            "  return true"
            "}"
        )
        pw(args.session, "run-code", fill_js, raw=True)

        # A correct passcode lands on /rec/play/ (a <video> follows a moment later);
        # a wrong one stays on the passcode form.
        if wait_for_state(args.session, reached_play, timeout_s=30) is None:
            log("passcode appears to be incorrect (did not reach the play page)")
            raise SystemExit(5)

    log("reading highest-resolution video URL")
    # The <video> element can attach a moment after the play page loads, so poll briefly.
    video_url = ""
    deadline = time.monotonic() + 15
    while time.monotonic() < deadline:
        out = pw(args.session, "eval", PICK_VIDEO_URL_JS, raw=True, check=False)
        video_url = decode_raw_string(out) if out else ""
        if video_url:
            break
        time.sleep(0.5)
    if not video_url:
        log(
            "no <video> source found — recording may be audio-only or download-disabled"
        )
        raise SystemExit(3)
    log(f"video URL: {video_url[:80]}...")

    cookie_jar_text = decode_raw_string(
        pw(args.session, "run-code", DUMP_COOKIES_JS, raw=True) or ""
    )
    return video_url, cookie_jar_text


def download(video_url: str, cookie_path: str, output: str) -> None:
    """Download with curl (resume + retries). Raises SystemExit(4) on failure."""
    curl_cmd = [
        "curl",
        "--fail",  # non-2xx -> exit 22, and do NOT write the error body into the output file
        "-C",
        "-",
        "-o",
        output,
        "-b",
        cookie_path,
        "-H",
        "Referer: https://zoom.us/",
        "-H",
        f"User-Agent: {UA}",
        "-w",
        "DONE http=%{http_code} size=%{size_download} time=%{time_total}s\n",
        video_url,
    ]
    for attempt in range(1, 4):
        # Progress goes to stderr (passes through); the -w summary goes to stdout.
        proc = subprocess.run(curl_cmd, stdout=subprocess.PIPE, text=True)
        summary = proc.stdout.strip()
        if summary:
            log(summary)
        if proc.returncode == 0:
            return
        m = re.search(r"http=(\d+)", summary)
        http_code = m.group(1) if m else ""
        # 416 on resume means the file is already complete — re-running after a
        # successful download is a no-op, not an error.
        if http_code == "416" and looks_like_mp4(output):
            log("file is already fully downloaded")
            return
        if attempt < 3:
            log(
                f"curl failed (exit {proc.returncode}, http={http_code or '?'}); "
                f"retrying ({attempt}/2)"
            )
            time.sleep(2)
    log(
        "curl failed after retries — the signed URL may have expired or cookies are "
        "invalid; re-run to fetch a fresh URL (the download resumes where it left off)"
    )
    raise SystemExit(4)


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Download a Zoom recording video via playwright-cli + curl."
    )
    ap.add_argument("--url", required=True, help="Recording share URL")
    ap.add_argument("--output", required=True, help="Output .mp4 file path")
    ap.add_argument("--passcode", default=None, help="Passcode (if required)")
    ap.add_argument(
        "--browser",
        default="chrome",
        help="Browser for playwright-cli open (default: chrome)",
    )
    ap.add_argument("--session", default=None, help="playwright-cli session name (-s)")
    ap.add_argument(
        "--keep-open", action="store_true", help="Do not close the browser at the end"
    )
    args = ap.parse_args()
    # Normalize early so curl and makedirs use the same absolute path regardless of cwd.
    args.output = os.path.abspath(args.output)

    log(f"opening browser ({args.browser})")
    pw(args.session, "open", f"--browser={args.browser}")
    try:
        video_url, cookie_jar_text = grab_video_url_and_cookies(args)
    finally:
        # Close even on failure so a wrong passcode / missing video doesn't leave a
        # stray browser behind. The cookies stay valid after close; curl doesn't need
        # the browser.
        if not args.keep_open:
            log("closing browser")
            pw(args.session, "close", check=False)

    with tempfile.NamedTemporaryFile(
        "w", suffix=".txt", delete=False, prefix="zoom_cookies_"
    ) as f:
        f.write(cookie_jar_text + "\n")
        cookie_path = f.name

    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    try:
        log(f"downloading to {args.output}")
        download(video_url, cookie_path, args.output)
    finally:
        os.unlink(cookie_path)

    if not looks_like_mp4(args.output):
        log(
            "downloaded file is empty or does not look like an MP4; the server may "
            "have returned an error page instead of the video"
        )
        raise SystemExit(4)

    log("done")
    print(args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
