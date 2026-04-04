#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["duckdb"]
# ///

"""Extract competition-specific subset from meta-kaggle dataset."""

import argparse
import json
import sys
from pathlib import Path

import duckdb

DATA_DIR = Path.home() / ".meta-kaggle"
TARGET_CSVS = [
    "Competitions.csv",
    "Teams.csv",
    "Forums.csv",
    "ForumTopics.csv",
    "ForumMessages.csv",
]


def check_data_exists() -> bool:
    for f in TARGET_CSVS:
        if not (DATA_DIR / f).exists():
            return False
    return True


def find_competition(con: duckdb.DuckDBPyConnection, slug: str) -> dict | None:
    """Find competition by slug (case-insensitive partial match)."""
    row = con.execute(
        "SELECT Id, Slug, Title, ForumId FROM Competitions WHERE lower(Slug) = lower(?)",
        [slug],
    ).fetchone()
    if row:
        return {"Id": row[0], "Slug": row[1], "Title": row[2], "ForumId": row[3]}
    # Fallback: partial match
    rows = con.execute(
        "SELECT Id, Slug, Title, ForumId FROM Competitions WHERE lower(Slug) LIKE '%' || lower(?) || '%' LIMIT 10",
        [slug],
    ).fetchall()
    if len(rows) == 1:
        return {
            "Id": rows[0][0],
            "Slug": rows[0][1],
            "Title": rows[0][2],
            "ForumId": rows[0][3],
        }
    if rows:
        print(
            json.dumps(
                {
                    "error": "ambiguous_slug",
                    "message": f"Multiple competitions match '{slug}'",
                    "candidates": [
                        {"Id": r[0], "Slug": r[1], "Title": r[2]} for r in rows
                    ],
                },
                indent=2,
            )
        )
        return None
    print(
        json.dumps(
            {"error": "not_found", "message": f"No competition found for '{slug}'"}
        )
    )
    return None


def find_forum_for_competition(
    con: duckdb.DuckDBPyConnection, comp: dict
) -> int | None:
    """Try to find forum for a competition without ForumId by matching slug/title in Forums table."""
    slug = comp["Slug"]
    title = comp["Title"]

    # Try exact slug match in Forums.Title
    row = con.execute(
        "SELECT Id, Title FROM Forums WHERE lower(Title) = lower(?)", [slug]
    ).fetchone()
    if row:
        print(
            f"Found forum by slug match: Id={row[0]}, Title='{row[1]}'",
            file=sys.stderr,
        )
        return row[0]

    # Try exact title match in competition-related parent forums (5=Active, 8=Past, 52=InClass)
    row = con.execute(
        "SELECT Id, Title FROM Forums WHERE lower(Title) = lower(?) AND ParentForumId IN (5, 8, 52)",
        [title],
    ).fetchone()
    if row:
        print(
            f"Found forum by title match: Id={row[0]}, Title='{row[1]}'",
            file=sys.stderr,
        )
        return row[0]

    # Try title match across all forums
    row = con.execute(
        "SELECT Id, Title, ParentForumId FROM Forums WHERE lower(Title) = lower(?)",
        [title],
    ).fetchone()
    if row:
        print(
            f"Found forum by title match (ParentForumId={row[2]}): Id={row[0]}, Title='{row[1]}'",
            file=sys.stderr,
        )
        return row[0]

    # Show candidates for manual selection
    rows = con.execute(
        "SELECT Id, Title, ParentForumId FROM Forums WHERE lower(Title) LIKE '%' || lower(?) || '%' LIMIT 20",
        [slug.replace("-", "%")],
    ).fetchall()
    if rows:
        print(
            json.dumps(
                {
                    "warning": "no_exact_forum_match",
                    "message": f"No exact forum match for '{slug}'. Candidates:",
                    "candidates": [
                        {"Id": r[0], "Title": r[1], "ParentForumId": r[2]} for r in rows
                    ],
                },
                indent=2,
            ),
            file=sys.stderr,
        )
    return None


def extract(con: duckdb.DuckDBPyConnection, comp: dict, output_dir: Path) -> None:
    """Extract competition subset to parquet files."""
    output_dir.mkdir(parents=True, exist_ok=True)
    forum_id = comp["ForumId"]

    if forum_id is None:
        # Fallback: search Forums by competition slug or title
        forum_id = find_forum_for_competition(con, comp)
        if forum_id is None:
            print(
                json.dumps(
                    {
                        "error": "no_forum",
                        "message": f"Competition '{comp['Slug']}' has no ForumId and no matching forum found.",
                        "competition": comp,
                    },
                    indent=2,
                )
            )
            return

    comp_id = comp["Id"]

    # Extract teams for competition
    teams_path = str(output_dir / "teams.parquet")
    con.execute(
        f"COPY (SELECT * FROM Teams WHERE CompetitionId = {comp_id}) TO '{teams_path}' (FORMAT PARQUET)"
    )
    team_count = con.execute(
        "SELECT count(*) FROM Teams WHERE CompetitionId = ?", [comp_id]
    ).fetchone()[0]

    # Extract forum topics
    topics_path = str(output_dir / "topics.parquet")
    con.execute(
        f"COPY (SELECT * FROM ForumTopics WHERE ForumId = {forum_id}) TO '{topics_path}' (FORMAT PARQUET)"
    )
    topic_count = con.execute(
        "SELECT count(*) FROM ForumTopics WHERE ForumId = ?", [forum_id]
    ).fetchone()[0]

    # Extract forum messages for those topics
    messages_path = str(output_dir / "messages.parquet")
    con.execute(
        f"COPY (SELECT fm.* FROM ForumMessages fm JOIN ForumTopics ft ON fm.ForumTopicId = ft.Id WHERE ft.ForumId = {forum_id}) TO '{messages_path}' (FORMAT PARQUET)"
    )
    message_count = con.execute(
        "SELECT count(*) FROM ForumMessages fm JOIN ForumTopics ft ON fm.ForumTopicId = ft.Id WHERE ft.ForumId = ?",
        [forum_id],
    ).fetchone()[0]
    meta = {
        "competitionId": comp_id,
        "slug": comp["Slug"],
        "title": comp["Title"],
        "forumId": forum_id,
        "teamCount": team_count,
        "topicCount": topic_count,
        "messageCount": message_count,
    }
    (output_dir / "meta.json").write_text(json.dumps(meta, indent=2) + "\n")

    print(
        json.dumps(
            {
                "status": "extracted",
                "outputDir": str(output_dir),
                **meta,
            },
            indent=2,
        )
    )


def cmd_list_extracted() -> None:
    """List already extracted competitions."""
    results = []
    for d in sorted(DATA_DIR.iterdir()):
        meta_file = d / "meta.json"
        if d.is_dir() and meta_file.exists():
            meta = json.loads(meta_file.read_text())
            results.append(meta)
    print(json.dumps(results, indent=2))


def main():
    parser = argparse.ArgumentParser(
        description="Extract competition subset from meta-kaggle"
    )
    parser.add_argument("slug", nargs="?", help="Competition slug to extract")
    parser.add_argument(
        "--list", action="store_true", help="List already extracted competitions"
    )
    parser.add_argument(
        "--update", action="store_true", help="Force re-extract even if exists"
    )
    args = parser.parse_args()

    if args.list:
        cmd_list_extracted()
        return

    if not args.slug:
        parser.print_help()
        sys.exit(1)

    if not check_data_exists():
        print(
            json.dumps(
                {
                    "error": "data_missing",
                    "message": "Source CSV files not found. Run sync.py first.",
                },
                indent=2,
            )
        )
        sys.exit(1)

    con = duckdb.connect()
    for csv_name in TARGET_CSVS:
        table_name = csv_name.replace(".csv", "")
        con.execute(
            f"CREATE VIEW {table_name} AS SELECT * FROM read_csv('{DATA_DIR / csv_name}', auto_detect=true, sample_size=10000)"
        )

    comp = find_competition(con, args.slug)
    if not comp:
        sys.exit(1)

    output_dir = DATA_DIR / comp["Slug"]
    if output_dir.exists() and not args.update:
        meta_file = output_dir / "meta.json"
        if meta_file.exists():
            meta = json.loads(meta_file.read_text())
            print(
                json.dumps(
                    {
                        "status": "already_exists",
                        "message": f"Subset already exists. Use --update to re-extract.",
                        "outputDir": str(output_dir),
                        **meta,
                    },
                    indent=2,
                )
            )
            return

    extract(con, comp, output_dir)


if __name__ == "__main__":
    main()
