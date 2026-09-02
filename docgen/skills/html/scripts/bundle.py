#!/usr/bin/env python3
"""Bundle an HTML document and its local assets into one self-contained file.

Usage:
    bundle.py INPUT.html [-o OUTPUT.html] [--offline] [--no-webfonts]

Default output is INPUT with `.bundled.html`. Local stylesheets, images and
scripts are inlined. Remote (http/https) references stay as they are so the
result remains small, unless --offline is given, in which case they are
downloaded and embedded too (fonts included, so expect several MB).
--no-webfonts drops the Google Fonts <link> so the document falls back to system
fonts; combine it with --offline for a compact offline file.

Only the standard library is used.

Processing order is fixed: stylesheets -> images -> scripts. Scripts go last so
that string fragments inside inlined JavaScript (e.g. `<image href="${e}">` in
mermaid) are never mistaken for references.
"""
from __future__ import annotations

import argparse
import base64
import mimetypes
import re
import sys
import urllib.parse
import urllib.request
from pathlib import Path

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")
_cache: dict[str, bytes] = {}


def log(msg: str) -> None:
    print(msg, file=sys.stderr)


def is_remote(ref: str) -> bool:
    return ref.startswith(("http://", "https://", "//"))


def skip(ref: str) -> bool:
    return (not ref or "${" in ref or ref.startswith(("data:", "#", "javascript:", "blob:")))


def fetch(url: str) -> bytes:
    if url.startswith("//"):
        url = "https:" + url
    if url not in _cache:
        if "fonts.gstatic.com" not in url:  # font files are many; count them instead
            log(f"  fetch {url}")
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        with urllib.request.urlopen(req, timeout=60) as r:
            _cache[url] = r.read()
    return _cache[url]


def load(ref: str, base: Path | str, offline: bool) -> bytes | None:
    """Return the bytes behind ref, or None when it should be left alone."""
    if skip(ref):
        return None
    if is_remote(ref) or (isinstance(base, str) and not ref.startswith("/")):
        if not offline:
            return None
        url = ref if is_remote(ref) else urllib.parse.urljoin(base, ref)
        return fetch(url)
    path = (Path(base) / ref.split("?")[0].split("#")[0]).resolve()
    if not path.is_file():
        log(f"  warning: not found, left as-is: {ref}")
        return None
    return path.read_bytes()


def data_uri(data: bytes, ref: str, fallback: str = "application/octet-stream") -> str:
    clean = ref.split("?")[0].split("#")[0]
    mime = mimetypes.guess_type(clean)[0] or fallback
    if clean.endswith(".woff2"):
        mime = "font/woff2"
    elif clean.endswith(".woff"):
        mime = "font/woff"
    return f"data:{mime};base64,{base64.b64encode(data).decode('ascii')}"


ATTR_RE = re.compile(r'([a-zA-Z-]+)\s*=\s*("([^"]*)"|\'([^\']*)\'|([^\s"\'>]+))')


def attrs(tag: str) -> dict[str, str]:
    out = {}
    for m in ATTR_RE.finditer(tag):
        out[m.group(1).lower()] = m.group(3) if m.group(3) is not None else (
            m.group(4) if m.group(4) is not None else m.group(5))
    return out


def strip_attrs(tag: str, names: set[str]) -> str:
    def repl(m: re.Match) -> str:
        return "" if m.group(1).lower() in names else m.group(0)
    inner = ATTR_RE.sub(repl, tag)
    return re.sub(r"\s+", " ", inner).strip()


# ---- CSS -------------------------------------------------------------------

CSS_URL_RE = re.compile(r'url\(\s*(["\']?)([^)"\']+)\1\s*\)')
CSS_IMPORT_RE = re.compile(r'@import\s+(?:url\()?["\']?([^"\')\s;]+)["\']?\)?\s*[^;]*;')


def inline_css(css: str, base: Path | str, offline: bool) -> str:
    def imp(m: re.Match) -> str:
        data = load(m.group(1), base, offline)
        if data is None:
            return m.group(0)
        nested_base = css_base(m.group(1), base)
        return inline_css(data.decode("utf-8", "replace"), nested_base, offline)

    css = CSS_IMPORT_RE.sub(imp, css)

    def url(m: re.Match) -> str:
        ref = m.group(2).strip()
        data = load(ref, base, offline)
        if data is None:
            return m.group(0)
        return f"url({data_uri(data, ref)})"

    return CSS_URL_RE.sub(url, css)


def css_base(ref: str, base: Path | str) -> Path | str:
    """Base for resolving url() inside a stylesheet found at ref."""
    if is_remote(ref):
        return ref if ref.startswith("http") else "https:" + ref
    if isinstance(base, str):
        return urllib.parse.urljoin(base, ref)
    return (Path(base) / ref.split("?")[0]).resolve().parent


# ---- HTML ------------------------------------------------------------------

LINK_RE = re.compile(r"<link\b([^>]*)>", re.I)
IMG_RE = re.compile(r"<img\b([^>]*)>", re.I)
SCRIPT_RE = re.compile(r"<script\b([^>]*)>\s*</script>", re.I)
FONTS_HOSTS = ("fonts.googleapis.com", "fonts.gstatic.com")


def process(html: str, base: Path, offline: bool, no_webfonts: bool) -> str:
    # 1. stylesheets
    def link(m: re.Match) -> str:
        a = attrs(m.group(1))
        href = a.get("href", "")
        if no_webfonts and any(h in href for h in FONTS_HOSTS):
            return ""
        rel = a.get("rel", "").lower().split()
        if "stylesheet" not in rel:
            if no_webfonts and "preconnect" in rel and any(h in href for h in FONTS_HOSTS):
                return ""
            return m.group(0)
        data = load(href, base, offline)
        if data is None:
            return m.group(0)
        css = inline_css(data.decode("utf-8", "replace"), css_base(href, base), offline)
        css = css.replace("</style", "<\\/style")
        media = f' media="{a["media"]}"' if a.get("media") else ""
        return f"<style{media}>\n{css}\n</style>"

    html = LINK_RE.sub(link, html)

    # 2. images
    def img(m: re.Match) -> str:
        a = attrs(m.group(1))
        src = a.get("src", "")
        data = load(src, base, offline)
        if data is None:
            return m.group(0)
        rest = strip_attrs(m.group(1), {"src"})
        return f'<img src="{data_uri(data, src, "image/png")}" {rest}>'.replace(" >", ">")

    html = IMG_RE.sub(img, html)

    # 3. scripts (last, see module docstring)
    def script(m: re.Match) -> str:
        a = attrs(m.group(1))
        src = a.get("src", "")
        data = load(src, base, offline)
        if data is None:
            return m.group(0)
        js = data.decode("utf-8", "replace").replace("</script", "<\\/script")
        rest = strip_attrs(m.group(1), {"src", "async", "defer", "crossorigin", "integrity"})
        open_tag = f"<script {rest}>" if rest else "<script>"
        return f"{open_tag}\n{js}\n</script>"

    html = SCRIPT_RE.sub(script, html)
    return html


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("input", type=Path)
    ap.add_argument("-o", "--output", type=Path)
    ap.add_argument("--offline", action="store_true", help="embed remote (CDN) assets too")
    ap.add_argument("--no-webfonts", action="store_true", help="drop the Google Fonts link")
    ns = ap.parse_args()

    src: Path = ns.input.resolve()
    if not src.is_file():
        log(f"not found: {src}")
        return 66
    out: Path = ns.output.resolve() if ns.output else src.with_suffix(".bundled.html")
    if out == src:
        log("output must differ from input")
        return 64

    log(f"bundle {src.name}" + (" (offline)" if ns.offline else ""))
    html = process(src.read_text(encoding="utf-8"), src.parent, ns.offline, ns.no_webfonts)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(html, encoding="utf-8")
    fonts = sum(1 for u in _cache if "fonts.gstatic.com" in u)
    if fonts:
        log(f"  fetched {fonts} font files")
    log(f"wrote {out} ({out.stat().st_size / 1024:.0f} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
