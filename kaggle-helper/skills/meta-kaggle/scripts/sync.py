#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///

"""Sync kaggle/meta-kaggle dataset CSV files to ~/.meta-kaggle/."""

import argparse
import csv
import io
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

DATA_DIR = Path.home() / ".meta-kaggle"
METADATA_FILE = DATA_DIR / "metadata.json"
DATASET_REF = "kaggle/meta-kaggle"
TARGET_FILES = [
    "Competitions.csv",
    "Teams.csv",
    "Forums.csv",
    "ForumTopics.csv",
    "ForumMessages.csv",
]


def get_remote_metadata() -> dict:
    """Get dataset metadata from Kaggle API."""
    result = subprocess.run(
        ["kaggle", "datasets", "list", "--search", "meta-kaggle", "--csv", "-v"],
        capture_output=True,
        text=True,
        check=True,
    )
    lines = [l for l in result.stdout.splitlines() if not l.startswith("Warning:")]
    reader = csv.DictReader(io.StringIO("\n".join(lines)))
    for row in reader:
        if row.get("ref") == DATASET_REF:
            return {
                "lastUpdated": row.get("lastUpdated", ""),
            }
    raise RuntimeError(f"Dataset {DATASET_REF} not found in kaggle datasets list")


def get_remote_file_info() -> dict[str, dict]:
    """Get file sizes and creation dates from Kaggle API for target files."""
    info = {}
    page_token = None
    while True:
        cmd = ["kaggle", "datasets", "files", DATASET_REF, "--csv", "-v"]
        if page_token:
            cmd.extend(["--page-token", page_token])
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        lines = result.stdout.splitlines()

        next_token = None
        csv_lines = []
        for line in lines:
            if line.startswith("Warning:"):
                continue
            if line.startswith("Next Page Token = "):
                next_token = line.split("= ", 1)[1].strip()
            else:
                csv_lines.append(line)

        reader = csv.DictReader(io.StringIO("\n".join(csv_lines)))
        for row in reader:
            name = row.get("name", "")
            if name in TARGET_FILES:
                info[name] = {
                    "size": int(row.get("size", 0)),
                    "creationDate": row.get("creationDate", ""),
                }

        if len(info) == len(TARGET_FILES) or not next_token:
            break
        page_token = next_token

    return info


def load_local_metadata() -> dict | None:
    """Load local metadata.json if it exists."""
    if not METADATA_FILE.exists():
        return None
    return json.loads(METADATA_FILE.read_text())


def save_metadata(remote: dict, file_info: dict[str, dict]) -> None:
    """Save metadata with download timestamp and file info."""
    metadata = {
        **remote,
        "downloadedAt": datetime.now(timezone.utc).isoformat(),
        "files": file_info,
    }
    METADATA_FILE.write_text(json.dumps(metadata, indent=2) + "\n")


def is_stale(local: dict | None, remote: dict) -> bool:
    """Check if local data is stale compared to remote."""
    if local is None:
        return True
    if local.get("lastUpdated") != remote.get("lastUpdated"):
        return True
    for f in TARGET_FILES:
        if not (DATA_DIR / f).exists():
            return True
    return False


def files_needing_update(remote_info: dict[str, dict]) -> list[str]:
    """Compare local file sizes with remote to find files that need downloading."""
    needs_update = []
    for filename in TARGET_FILES:
        local_path = DATA_DIR / filename
        if not local_path.exists():
            needs_update.append(filename)
            continue
        local_size = local_path.stat().st_size
        remote = remote_info.get(filename, {})
        remote_size = remote.get("size")
        if remote_size is not None and local_size != remote_size:
            needs_update.append(filename)
    return needs_update


def download_file(filename: str) -> None:
    """Download a single CSV file from Kaggle."""
    print(f"Downloading {filename}...", file=sys.stderr)
    subprocess.run(
        [
            "kaggle",
            "datasets",
            "download",
            "-d",
            DATASET_REF,
            "-f",
            filename,
            "--unzip",
            "-p",
            str(DATA_DIR),
        ],
        check=True,
    )


def cmd_status() -> None:
    """Print current status."""
    local = load_local_metadata()
    remote = get_remote_metadata()
    stale = is_stale(local, remote)

    files = {}
    for f in TARGET_FILES:
        local_path = DATA_DIR / f
        files[f] = {
            "exists": local_path.exists(),
            "localSize": local_path.stat().st_size if local_path.exists() else None,
            "path": str(local_path),
        }

    result = {
        "local": local,
        "remote": remote,
        "stale": stale,
        "files": files,
    }
    print(json.dumps(result, indent=2))


def cmd_sync(force: bool = False) -> None:
    """Sync dataset files."""
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    remote = get_remote_metadata()
    local = load_local_metadata()

    if not force and not is_stale(local, remote):
        result = {
            "status": "up-to-date",
            "lastUpdated": remote["lastUpdated"],
        }
        print(json.dumps(result, indent=2))
        return

    # Get remote file sizes for diff check
    print("Checking file sizes...", file=sys.stderr)
    remote_info = get_remote_file_info()

    if force:
        to_download = TARGET_FILES
    else:
        to_download = files_needing_update(remote_info)

    if not to_download:
        save_metadata(remote, remote_info)
        result = {
            "status": "up-to-date",
            "message": "Dataset updated but all files have same size, no download needed.",
            "lastUpdated": remote["lastUpdated"],
        }
        print(json.dumps(result, indent=2))
        return

    skipped = [f for f in TARGET_FILES if f not in to_download]
    if skipped:
        print(f"Skipping (same size): {', '.join(skipped)}", file=sys.stderr)

    for filename in to_download:
        download_file(filename)

    save_metadata(remote, remote_info)

    result = {
        "status": "updated",
        "lastUpdated": remote["lastUpdated"],
        "downloaded": [str(DATA_DIR / f) for f in to_download],
        "skipped": skipped,
    }
    print(json.dumps(result, indent=2))


def main():
    parser = argparse.ArgumentParser(description="Sync kaggle/meta-kaggle dataset")
    parser.add_argument(
        "--status", action="store_true", help="Show current sync status"
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Force re-download regardless of staleness",
    )
    args = parser.parse_args()

    if args.status:
        cmd_status()
    else:
        cmd_sync(force=args.force)


if __name__ == "__main__":
    main()
