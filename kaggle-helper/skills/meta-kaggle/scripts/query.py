#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["duckdb"]
# ///

"""Query competition-specific meta-kaggle subset using DuckDB."""

import argparse
import json
import sys
from pathlib import Path

import duckdb

DATA_DIR = Path.home() / ".meta-kaggle"
DEFAULT_LIMIT = 50


def get_subset_dir(slug: str) -> Path:
    d = DATA_DIR / slug
    if not d.exists() or not (d / "meta.json").exists():
        print(
            json.dumps(
                {
                    "error": "not_extracted",
                    "message": f"No extracted data for '{slug}'. Run extract.py first.",
                }
            )
        )
        sys.exit(1)
    return d


def connect(subset_dir: Path) -> duckdb.DuckDBPyConnection:
    con = duckdb.connect()
    con.execute(
        f"CREATE VIEW topics AS SELECT * FROM read_parquet('{subset_dir / 'topics.parquet'}')"
    )
    con.execute(
        f"CREATE VIEW messages AS SELECT * FROM read_parquet('{subset_dir / 'messages.parquet'}')"
    )
    teams_path = subset_dir / "teams.parquet"
    if teams_path.exists():
        con.execute(f"CREATE VIEW teams AS SELECT * FROM read_parquet('{teams_path}')")
    return con


def output_json(rows: list[tuple], columns: list[str]) -> None:
    result = [dict(zip(columns, row)) for row in rows]
    print(json.dumps(result, indent=2, default=str))


def cmd_schema(con: duckdb.DuckDBPyConnection) -> None:
    schema = {}
    for table in ["teams", "topics", "messages"]:
        try:
            cols = con.execute(f"DESCRIBE {table}").fetchall()
            schema[table] = [{"name": c[0], "type": c[1]} for c in cols]
        except duckdb.CatalogException:
            pass
    print(json.dumps(schema, indent=2))


DATE_FMT = "'%m/%d/%Y %H:%M:%S'"  # meta-kaggle date format for strptime


def cmd_topics(
    con: duckdb.DuckDBPyConnection,
    search: str | None,
    sort: str,
    since: str | None,
    updated_since: str | None,
    min_score: int | None,
    min_messages: int | None,
    all_topics: bool,
    limit: int,
) -> None:
    sort_map = {
        "score": "Score DESC",
        "messages": "TotalMessages DESC",
        "created": f"strptime(CreationDate, {DATE_FMT}) DESC",
        "updated": f"strptime(LastCommentDate, {DATE_FMT}) DESC",
    }
    order_by = sort_map.get(sort, "Score DESC")
    columns = (
        "Id, Title, Score, TotalViews, TotalMessages, CreationDate, LastCommentDate"
    )

    conditions = []
    params: list = []

    # Default filter: exclude low-quality topics (Score <= 0 AND TotalMessages <= 1)
    # unless --all is specified or explicit min thresholds are given
    if not all_topics and min_score is None and min_messages is None:
        conditions.append("NOT (Score <= 0 AND TotalMessages <= 1)")

    if min_score is not None:
        conditions.append("Score >= ?")
        params.append(min_score)

    if min_messages is not None:
        conditions.append("TotalMessages >= ?")
        params.append(min_messages)

    if search:
        conditions.append("lower(Title) LIKE '%' || lower(?) || '%'")
        params.append(search)

    if since:
        conditions.append(f"strptime(CreationDate, {DATE_FMT}) >= ?::DATE")
        params.append(since)

    if updated_since:
        conditions.append(f"strptime(LastCommentDate, {DATE_FMT}) >= ?::DATE")
        params.append(updated_since)

    where = f"WHERE {' AND '.join(conditions)}" if conditions else ""
    query = f"SELECT {columns} FROM topics {where} ORDER BY {order_by} LIMIT ?"
    params.append(limit)

    rows = con.execute(query, params).fetchall()
    output_json(
        rows,
        [
            "Id",
            "Title",
            "Score",
            "TotalViews",
            "TotalMessages",
            "CreationDate",
            "LastCommentDate",
        ],
    )


def cmd_messages(con: duckdb.DuckDBPyConnection, topic_id: int, limit: int) -> None:
    rows = con.execute(
        "SELECT Id, PostUserId, PostDate, RawMarkdown, Medal, ReplyToForumMessageId FROM messages WHERE ForumTopicId = ? ORDER BY PostDate LIMIT ?",
        [topic_id, limit],
    ).fetchall()
    output_json(
        rows,
        [
            "Id",
            "PostUserId",
            "PostDate",
            "RawMarkdown",
            "Medal",
            "ReplyToForumMessageId",
        ],
    )


def cmd_thread(con: duckdb.DuckDBPyConnection, topic_id: int) -> None:
    """Read a topic as a threaded conversation in Markdown."""
    topic = con.execute(
        "SELECT Id, Title, Score, TotalMessages, CreationDate FROM topics WHERE Id = ?",
        [topic_id],
    ).fetchone()
    if not topic:
        print(
            json.dumps({"error": "not_found", "message": f"Topic {topic_id} not found"})
        )
        return

    rows = con.execute(
        "SELECT Id, PostUserId, PostDate, RawMarkdown, Medal, ReplyToForumMessageId FROM messages WHERE ForumTopicId = ? ORDER BY PostDate",
        [topic_id],
    ).fetchall()

    lines = []
    lines.append(f"# {topic[1]}")
    lines.append(f"Score: {topic[2]} | Messages: {topic[3]} | Created: {topic[4]}")
    lines.append("")

    for row in rows:
        msg_id, user_id, post_date, raw_md, medal, reply_to = row
        medal_str = f" [Medal: {medal}]" if medal else ""
        reply_str = f" (reply to #{reply_to})" if reply_to else ""
        lines.append(
            f"## #{msg_id} by User {user_id} — {post_date}{medal_str}{reply_str}"
        )
        lines.append("")
        lines.append(raw_md or "(no content)")
        lines.append("")
        lines.append("---")
        lines.append("")

    print("\n".join(lines))


def cmd_solutions(con: duckdb.DuckDBPyConnection, limit: int) -> None:
    patterns = [
        "solution",
        "1st place",
        "2nd place",
        "3rd place",
        "4th place",
        "5th place",
        "gold",
        "silver",
        "bronze",
        "winning",
        "write-up",
        "writeup",
        "approach",
        "top %",
    ]
    conditions = " OR ".join([f"lower(Title) LIKE '%{p}%'" for p in patterns])
    rows = con.execute(
        f"SELECT Id, Title, Score, TotalViews, TotalMessages, CreationDate FROM topics WHERE {conditions} ORDER BY Score DESC LIMIT ?",
        [limit],
    ).fetchall()
    output_json(
        rows, ["Id", "Title", "Score", "TotalViews", "TotalMessages", "CreationDate"]
    )


def cmd_search_messages(
    con: duckdb.DuckDBPyConnection, keyword: str, limit: int
) -> None:
    rows = con.execute(
        """SELECT m.Id, m.ForumTopicId, t.Title as TopicTitle, m.PostDate, m.RawMarkdown, m.Medal
        FROM messages m
        JOIN topics t ON m.ForumTopicId = t.Id
        WHERE lower(coalesce(m.RawMarkdown, m.Message)) LIKE '%' || lower(?) || '%'
        ORDER BY m.PostDate DESC
        LIMIT ?""",
        [keyword, limit],
    ).fetchall()
    output_json(
        rows,
        ["Id", "ForumTopicId", "TopicTitle", "PostDate", "RawMarkdown", "Medal"],
    )


def cmd_sql(con: duckdb.DuckDBPyConnection, query: str) -> None:
    result = con.execute(query)
    columns = [desc[0] for desc in result.description]
    rows = result.fetchall()
    output_json(rows, columns)


def main():
    parser = argparse.ArgumentParser(description="Query meta-kaggle competition subset")
    parser.add_argument("slug", help="Competition slug")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("schema", help="Show table schemas")

    p_topics = sub.add_parser("topics", help="List forum topics")
    p_topics.add_argument("--search", help="Search keyword in title")
    p_topics.add_argument(
        "--sort",
        choices=["score", "messages", "created", "updated"],
        default="score",
        help="Sort order (default: score)",
    )
    p_topics.add_argument(
        "--since", help="Filter topics created on or after this date (YYYY-MM-DD)"
    )
    p_topics.add_argument(
        "--updated-since",
        help="Filter topics with comments on or after this date (YYYY-MM-DD)",
    )
    p_topics.add_argument(
        "--min-score", type=int, default=None, help="Minimum Score threshold"
    )
    p_topics.add_argument(
        "--min-messages",
        type=int,
        default=None,
        help="Minimum TotalMessages threshold",
    )
    p_topics.add_argument(
        "--all",
        action="store_true",
        dest="all_topics",
        help="Include all topics (disable default quality filter)",
    )
    p_topics.add_argument("--limit", type=int, default=DEFAULT_LIMIT)

    p_msgs = sub.add_parser("messages", help="Get messages for a topic")
    p_msgs.add_argument("topic_id", type=int, help="ForumTopic Id")
    p_msgs.add_argument("--limit", type=int, default=DEFAULT_LIMIT)

    p_sol = sub.add_parser("solutions", help="Find solution-related topics")
    p_sol.add_argument("--limit", type=int, default=DEFAULT_LIMIT)

    p_search = sub.add_parser("search", help="Search keyword in messages")
    p_search.add_argument("keyword", help="Search keyword")
    p_search.add_argument("--limit", type=int, default=DEFAULT_LIMIT)

    p_thread = sub.add_parser(
        "thread", help="Read a topic as threaded Markdown conversation"
    )
    p_thread.add_argument("topic_id", type=int, help="ForumTopic Id")

    p_sql = sub.add_parser("sql", help="Run arbitrary SQL")
    p_sql.add_argument("query", help="SQL query")

    args = parser.parse_args()
    subset_dir = get_subset_dir(args.slug)
    con = connect(subset_dir)

    match args.command:
        case "schema":
            cmd_schema(con)
        case "topics":
            cmd_topics(
                con,
                args.search,
                args.sort,
                args.since,
                args.updated_since,
                args.min_score,
                args.min_messages,
                args.all_topics,
                args.limit,
            )
        case "messages":
            cmd_messages(con, args.topic_id, args.limit)
        case "thread":
            cmd_thread(con, args.topic_id)
        case "solutions":
            cmd_solutions(con, args.limit)
        case "search":
            cmd_search_messages(con, args.keyword, args.limit)
        case "sql":
            cmd_sql(con, args.query)


if __name__ == "__main__":
    main()
