# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "httpx>=0.27",
# ]
# ///
"""Research X (Twitter) posts via the xAI Grok API's x_search server-side tool.

Calls the xAI Responses API (https://api.x.ai/v1/responses) with the x_search
tool. The caller supplies the whole research instruction as --prompt; what to
look for and how to shape the report is decided there, not here. The schema is
fixed only in shape (report + findings + sources), so citation verification
works no matter what the prompt asks for.

Post-processing:

- Verifies every source URL the model produced against the citations the API
  actually collected. Only X post URLs count as backing, so a news page the
  agent happened to browse cannot stand in for a post.
- Reports sourcing health: how many X posts were cited and quoted, and which
  findings came back with no verified source. A model that answered without
  searching still returns a filled-in schema, so these counters are what
  distinguish that from a real finding.
- Reports usage and billable tool-call counts for cost visibility.

Requires XAI_API_KEY. Run via: uv run search.py --prompt "..." [options]
"""

import argparse
import json
import os
import re
import sys
import time
from typing import Any

import httpx

API_URL = "https://api.x.ai/v1/responses"
DEFAULT_MODEL = "grok-4.3"

STATUS_ID_RE = re.compile(
    r"(?:x|twitter)\.com/(?:i/)?(?:[A-Za-z0-9_]+/)?status(?:es)?/(\d+)"
)
X_URL_RE = re.compile(r"https://(?:x|twitter)\.com/[^\s\"'\\<>)\]]+")

SYSTEM = """\
You are a researcher working over X (Twitter) search results. The user's
message tells you what to research and how to shape the report; follow it.
These rules override it only where they conflict.

Your output is read by another assistant that shows the user your report
together with the actual posts. A finding whose sources carry no quote cannot
be shown, so it is dropped: the posters' own words are what the reader sees.

Grounding:
- Base everything ONLY on posts you actually retrieved via x_search. Never
  invent posts, URLs, or quotes, and never fall back on your own knowledge —
  not even for background you are confident about.
- Search more than once — a single query is never enough. Vary the wording,
  and run the important queries in both mode "Top" and mode "Latest": they
  return different posts. Follow promising posts into their threads.
- Japanese posts do not surface from English queries. When the request wants
  Japanese sources, issue separate queries written in Japanese. Do not rely on
  a `lang:` operator; it is not part of the search tool.
- If the search returns nothing relevant, say so plainly in `report` and
  `coverage_note` and return `findings: []`. An empty result is a valid
  answer; filling the schema from memory is not.

`report`:
- Markdown, in the language the request is written in. Structure it as the
  request asks; otherwise lead with the answer, then the detail.
- Cite posts inline as [@handle](url) so every statement is traceable.

`findings` — one entry per distinct finding the report rests on:
- Anything the report names, it must carry as a finding. If the report
  mentions a model, paper, or claim, that item needs its own entry with its
  own sources. Never leave a name in the report with no finding behind it: a
  reader cannot check it, and it will be reported as unsourced.
- Cover what you found, not just the highlights. If your searches surfaced a
  dozen relevant posts, do not distill them into three entries — a brief entry
  with one good quote beats an omission.
- `point`: the finding, in one or two sentences.
- `detail`: whatever the request asked to record per finding (method,
  languages, benchmark numbers, stance, caveats). Empty if not applicable.
- `links`: URLs the posts point to — papers, repos, model cards, demos. These
  are often the real payload; collect them rather than only the post URL.
- `sources`: the X posts backing this finding. Every source needs a `quote`
  that is a VERBATIM excerpt from that post, in its original language. Copy
  the wording exactly — never paraphrase, clean up, translate, or merge posts.
  Keep quotes short (one or two sentences); trim with an ellipsis instead of
  rewriting. Prefer two or more distinct authors when the posts support it.
  Copy each `url` from the search result itself. Never reconstruct a URL from
  an account name or a post id you remember — a URL that was not in the
  results is discarded along with its quote, losing the whole source.
- Keep minority or contradicting findings rather than dropping them; note the
  disagreement in `detail`.
- Never give counts or percentages of how many people said something. You did
  not see the full population.

`coverage_note`: what you searched (queries, handles, date range) and what you
could not cover. Be concrete about the gaps.
"""

SOURCE_ITEM: dict[str, Any] = {
    "type": "object",
    "properties": {
        "url": {
            "type": "string",
            "description": "URL of the post, as seen in search results",
        },
        "author_handle": {"type": "string", "description": "X handle without @"},
        "date": {
            "type": "string",
            "description": "Post date (YYYY-MM-DD) if known, else empty",
        },
        "quote": {
            "type": "string",
            "description": (
                "Verbatim excerpt from the post, in its original language."
                " Copy the actual wording; never paraphrase or translate here."
            ),
        },
    },
    "required": ["url", "author_handle", "date", "quote"],
    "additionalProperties": False,
}

RESULT_SCHEMA: dict[str, Any] = {
    "type": "object",
    "properties": {
        "report": {
            "type": "string",
            "description": (
                "The research report answering the request, in Markdown, in the"
                " language the request was written in. Structure it however the"
                " request asks. Cite posts inline as [@handle](url) so each"
                " statement is traceable."
            ),
        },
        "findings": {
            "type": "array",
            "description": (
                "The individual findings the report is built from, each tied to"
                " the posts that support it. One entry per distinct finding."
            ),
            "items": {
                "type": "object",
                "properties": {
                    "point": {
                        "type": "string",
                        "description": "The finding itself, stated in one or two sentences",
                    },
                    "detail": {
                        "type": "string",
                        "description": (
                            "Whatever the request asked to record for each"
                            " finding (method, languages, benchmark numbers,"
                            " stance, caveats...). Empty if not applicable."
                        ),
                    },
                    "links": {
                        "type": "array",
                        "description": (
                            "URLs the posts point to — papers, repos, model"
                            " cards, demos. Often the real payload of a post."
                        ),
                        "items": {"type": "string"},
                    },
                    "sources": {
                        "type": "array",
                        "description": "X posts backing this finding, with verbatim quotes",
                        "items": SOURCE_ITEM,
                    },
                },
                "required": ["point", "detail", "links", "sources"],
                "additionalProperties": False,
            },
        },
        "coverage_note": {
            "type": "string",
            "description": (
                "What was searched (queries, handles, date range) and what could"
                " not be covered. Be concrete about gaps."
            ),
        },
    },
    "required": ["report", "findings", "coverage_note"],
    "additionalProperties": False,
}


def build_payload(args: argparse.Namespace) -> dict[str, Any]:
    tool: dict[str, Any] = {"type": "x_search"}
    if args.handles:
        tool["allowed_x_handles"] = args.handles
    if args.exclude_handles:
        tool["excluded_x_handles"] = args.exclude_handles
    if args.from_date:
        tool["from_date"] = args.from_date
    if args.to_date:
        tool["to_date"] = args.to_date

    payload: dict[str, Any] = {
        "model": args.model,
        "tools": [tool],
        "store": True,
        "text": {
            "format": {
                "type": "json_schema",
                "name": "x_research_result",
                "schema": RESULT_SCHEMA,
                "strict": True,
            }
        },
    }
    if args.previous_response_id:
        payload["previous_response_id"] = args.previous_response_id
        payload["input"] = [{"role": "user", "content": args.prompt}]
    else:
        payload["input"] = [
            {"role": "system", "content": SYSTEM},
            {"role": "user", "content": args.prompt},
        ]
    if args.max_turns is not None:
        payload["max_turns"] = args.max_turns
    if args.effort:
        payload["reasoning"] = {"effort": args.effort}
    return payload


def collect_citations(data: dict[str, Any]) -> set[str]:
    """Collect ground-truth source URLs from everywhere EXCEPT the model's own
    message text (which may contain fabricated URLs)."""
    urls: set[str] = set()

    for c in data.get("citations") or []:
        if isinstance(c, str):
            urls.add(c)
        elif isinstance(c, dict) and isinstance(c.get("url"), str):
            urls.add(c["url"])

    for item in data.get("output") or []:
        if not isinstance(item, dict):
            continue
        if item.get("type") == "message":
            # only structured annotations, not the text body
            for content in item.get("content") or []:
                for ann in (content or {}).get("annotations") or []:
                    if isinstance(ann, dict) and isinstance(ann.get("url"), str):
                        urls.add(ann["url"])
        else:
            # tool-call items (x_search_call etc.): scrape any X URL they carry
            urls.update(X_URL_RE.findall(json.dumps(item)))

    return urls


def search_calls(data: dict[str, Any]) -> list[dict[str, Any]]:
    """List the X search calls in the output, however the API labels them.

    Sub-tool calls have been observed arriving as `custom_tool_call` with an
    `x_*_search` name rather than as `x_search_call`, so match on either. The
    call's input carries the query the agent actually issued, which is the only
    way to check whether operators written into the prompt reached the tool.
    """
    calls = []
    for item in data.get("output") or []:
        if not isinstance(item, dict):
            continue
        kind = item.get("type") or ""
        name = item.get("name") or ""
        if not (
            kind == "x_search_call"
            or name.startswith(("x_keyword", "x_semantic", "x_user", "x_thread"))
        ):
            continue
        raw = item.get("input")
        if isinstance(raw, str):
            try:
                raw = json.loads(raw)
            except json.JSONDecodeError:
                pass
        calls.append({"tool": name or kind, "input": raw})
    return calls


def extract_message_text(data: dict[str, Any]) -> str | None:
    for item in data.get("output") or []:
        if isinstance(item, dict) and item.get("type") == "message":
            for content in item.get("content") or []:
                if isinstance(content, dict) and content.get("type") == "output_text":
                    return content.get("text")
    return None


def status_ids(urls: set[str] | list[str]) -> set[str]:
    return {m for u in urls for m in STATUS_ID_RE.findall(u)}


def verify_urls(
    claimed: list[str], citation_urls: set[str], citation_ids: set[str]
) -> tuple[list[str], list[str]]:
    """Split claimed URLs into (verified, unverified) against citations.

    Only X post URLs can back a finding: this skill reports what was said on X,
    so a non-X citation (a news page the agent happened to browse) must not
    launder a claim past verification just by appearing in `citations`.
    """
    verified, unverified = [], []
    for url in claimed:
        ids = STATUS_ID_RE.findall(url)
        if ids and set(ids) <= citation_ids:
            verified.append(url)
        else:
            unverified.append(url)
    return verified, unverified


def verify_sources(
    sources: list[dict[str, Any]], citation_urls: set[str], citation_ids: set[str]
) -> tuple[list[dict[str, Any]], list[str]]:
    """Keep only sources whose post URL is backed by citations.

    A quote is only worth showing if the post it came from was really seen, so
    an unverified source is dropped whole rather than kept without its URL.
    """
    kept, dropped = [], []
    for src in sources:
        if not isinstance(src, dict):
            continue
        url = src.get("url", "")
        verified, unverified = verify_urls([url], citation_urls, citation_ids)
        if verified:
            kept.append(src)
        else:
            dropped.extend(unverified)
    return kept, dropped


def postprocess(
    parsed: dict[str, Any], citation_urls: set[str]
) -> tuple[dict[str, Any], list[str]]:
    """Drop sources whose posts are not backed by citations; return their URLs."""
    citation_ids = status_ids(citation_urls)
    dropped: list[str] = []

    for entry in parsed.get("findings") or []:
        if not isinstance(entry, dict):
            continue
        kept, gone = verify_sources(
            entry.get("sources") or [], citation_urls, citation_ids
        )
        entry["sources"] = kept
        dropped.extend(gone)

    return parsed, dropped


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--prompt", help="the research instruction sent to Grok")
    src.add_argument(
        "--prompt-file",
        help="read the research instruction from this file (or - for stdin)",
    )
    ap.add_argument("--model", default=DEFAULT_MODEL)
    ap.add_argument("--from", dest="from_date", help="ISO8601 start date (YYYY-MM-DD)")
    ap.add_argument(
        "--to",
        dest="to_date",
        help="ISO8601 end date (YYYY-MM-DD; may be exclusive — pass the next day"
        " to be sure the last day is covered)",
    )
    ap.add_argument(
        "--handles",
        type=lambda s: [h.lstrip("@") for h in s.split(",") if h.strip()],
        help="comma-separated handles: only search these accounts (max 20)",
    )
    ap.add_argument(
        "--exclude-handles",
        type=lambda s: [h.lstrip("@") for h in s.split(",") if h.strip()],
        help="comma-separated handles to exclude (max 20; exclusive with --handles)",
    )
    ap.add_argument(
        "--max-turns",
        type=int,
        default=5,
        help="cap agentic turns; default 5 (~$0.5-0.8). Raise and re-run if the"
        " report says coverage was thin; leaving it uncapped makes cost unbounded",
    )
    ap.add_argument(
        "--effort",
        choices=["none", "low", "medium", "high"],
        help="reasoning effort (model-dependent; omit for default)",
    )
    ap.add_argument(
        "--previous-response-id",
        help="continue a stored conversation (follow-up without re-searching)",
    )
    ap.add_argument("--raw-out", help="write the full API response JSON to this file")
    ap.add_argument("--timeout", type=float, default=600.0)
    ap.add_argument(
        "--retries",
        type=int,
        default=2,
        help="retries on 5xx/429 (transient server errors); default 2",
    )
    args = ap.parse_args()

    api_key = os.environ.get("XAI_API_KEY")
    if not api_key:
        print(
            "error: XAI_API_KEY is not set. Create a key at"
            " https://console.x.ai (API Keys) and export it.",
            file=sys.stderr,
        )
        return 2
    if args.handles and args.exclude_handles:
        print(
            "error: --handles and --exclude-handles cannot be used together.",
            file=sys.stderr,
        )
        return 2

    if args.prompt_file:
        if args.prompt_file == "-":
            args.prompt = sys.stdin.read()
        else:
            with open(args.prompt_file) as f:
                args.prompt = f.read()
    if not args.prompt.strip():
        print("error: the prompt is empty.", file=sys.stderr)
        return 2

    payload = build_payload(args)
    # 5xx and 429 are transient often enough to be worth retrying: a failed run
    # still burns the search-tool billing, which dominates the cost.
    resp = None
    for attempt in range(args.retries + 1):
        if attempt:
            delay = 2**attempt
            print(
                f"retrying in {delay}s ({attempt}/{args.retries})...",
                file=sys.stderr,
            )
            time.sleep(delay)
        try:
            resp = httpx.post(
                API_URL,
                headers={"Authorization": f"Bearer {api_key}"},
                json=payload,
                timeout=args.timeout,
            )
        except httpx.HTTPError as e:
            print(f"error: request failed: {e}", file=sys.stderr)
            if attempt == args.retries:
                return 1
            continue
        if resp.status_code == 200:
            break
        print(f"error: HTTP {resp.status_code}: {resp.text[:2000]}", file=sys.stderr)
        if resp.status_code < 500 and resp.status_code != 429:
            return 1
        if attempt == args.retries:
            return 1
    if resp is None or resp.status_code != 200:
        return 1
    data = resp.json()

    if args.raw_out:
        with open(args.raw_out, "w") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

    text = extract_message_text(data)
    if text is None:
        print("error: no message output in response", file=sys.stderr)
        print(json.dumps(data, ensure_ascii=False)[:2000], file=sys.stderr)
        return 1
    try:
        parsed = json.loads(text)
    except json.JSONDecodeError as e:
        print(f"error: output is not valid JSON ({e})", file=sys.stderr)
        print(text[:2000], file=sys.stderr)
        return 1

    citation_urls = collect_citations(data)
    calls = search_calls(data)
    parsed, dropped = postprocess(parsed, citation_urls)

    x_citations = sorted(u for u in citation_urls if X_URL_RE.match(u))
    findings = [f for f in parsed.get("findings") or [] if isinstance(f, dict)]
    unsourced = [f.get("point", "") for f in findings if not f.get("sources")]
    quoted_posts = {
        s.get("url")
        for f in findings
        for s in f.get("sources") or []
        if isinstance(s, dict) and s.get("quote")
    }
    linked = sorted(
        {
            u
            for f in findings
            for u in f.get("links") or []
            if isinstance(u, str) and u.startswith("http")
        }
    )

    result = {
        "prompt": args.prompt,
        "model": args.model,
        "result": parsed,
        "citations": {
            "x": x_citations,
            "other": sorted(citation_urls - set(x_citations)),
        },
        "linked_urls": linked,
        "dropped_unverified_urls": sorted(set(dropped)),
        "search_calls": calls,
        "sourcing": {
            "search_call_count": len(calls),
            "x_citation_count": len(x_citations),
            "finding_count": len(findings),
            "quoted_post_count": len(quoted_posts),
            "unsourced_findings": unsourced,
        },
        "response_id": data.get("id"),
        "usage": data.get("usage"),
        "server_side_tool_usage": data.get("server_side_tool_usage"),
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))

    # The API reports status "completed" even when the agent burns every turn on
    # searching and never writes the report, so an empty result is only visible
    # here: searches were billed, output is a schema-valid shell.
    if calls and not findings and not (parsed.get("report") or "").strip():
        print(
            f"warning: the agent made {len(calls)} search call(s) and collected"
            f" {len(x_citations)} X citation(s), but returned an empty report"
            " with no findings. The turn budget was most likely spent before"
            f" it wrote anything. Re-run with --max-turns {args.max_turns * 2};"
            " the searches were still billed.",
            file=sys.stderr,
        )

    if not x_citations and calls:
        print(
            f"warning: the agent made {len(calls)} X search call(s) but the"
            " response carried no X citations, so nothing could be verified"
            " and every source was dropped. This is a citation-harvesting"
            " failure, not necessarily a fabricated answer — inspect"
            " --raw-out before judging the content.",
            file=sys.stderr,
        )
    elif not x_citations:
        print(
            "warning: no X search calls and no X citations. The model answered"
            " from its own knowledge — do not present this as an X finding,"
            " even where a finding carries a non-X source URL.",
            file=sys.stderr,
        )
    if unsourced:
        print(
            f"warning: {len(unsourced)} finding(s) have no verified source"
            " post. The model asserted them without X evidence that survived"
            " citation checking.",
            file=sys.stderr,
        )
    if dropped:
        print(
            f"warning: {len(set(dropped))} URL(s) produced by the model were"
            " not present in citations and were dropped as unverified.",
            file=sys.stderr,
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
