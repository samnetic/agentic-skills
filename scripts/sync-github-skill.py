#!/usr/bin/env python3
"""
Sync a skill directory from a GitHub repository path into a local destination.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
from datetime import UTC, datetime
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen

PROJECT_ROOT = Path(__file__).resolve().parent.parent


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Sync a GitHub skill path to a local directory.")
    parser.add_argument("--repo", required=True, help="GitHub repo in owner/name format")
    parser.add_argument("--path", required=True, help="Path inside the repo")
    parser.add_argument("--dest", required=True, help="Local destination directory")
    parser.add_argument("--ref", default="main", help="Git ref/branch/tag (default: main)")
    parser.add_argument(
        "--no-clean",
        action="store_true",
        help="Do not delete destination before syncing",
    )
    parser.add_argument(
        "--metadata-file",
        default=".sync-source.json",
        help="Metadata filename written in destination root",
    )
    parser.add_argument(
        "--allow-outside-root",
        action="store_true",
        help="Allow syncing outside this repository root (unsafe)",
    )
    return parser.parse_args()


def request_json(url: str, token: str | None) -> Any:
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "agentic-skills-sync",
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"

    req = Request(url, headers=headers)
    with urlopen(req) as response:
        return json.loads(response.read().decode("utf-8"))


def download_bytes(url: str, token: str | None) -> bytes:
    headers = {"User-Agent": "agentic-skills-sync"}
    if token and "raw.githubusercontent.com" not in url:
        headers["Authorization"] = f"Bearer {token}"
    req = Request(url, headers=headers)
    with urlopen(req) as response:
        return response.read()


def write_file(target: Path, content: bytes) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(content)
    # Upstream templates rely on executable bit for direct shell execution.
    if target.suffix == ".sh":
        target.chmod(target.stat().st_mode | 0o111)


def sync_contents(
    repo: str,
    remote_path: str,
    ref: str,
    local_dir: Path,
    token: str | None,
) -> int:
    encoded_path = quote(remote_path, safe="/")
    encoded_ref = quote(ref, safe="")
    url = f"https://api.github.com/repos/{repo}/contents/{encoded_path}?ref={encoded_ref}"
    payload = request_json(url, token)
    file_count = 0

    if isinstance(payload, dict):
        if payload.get("type") != "file":
            raise RuntimeError(f"Unsupported payload type at {remote_path}: {payload.get('type')}")
        download_url = payload.get("download_url")
        if not download_url:
            raise RuntimeError(f"Missing download URL for {remote_path}")
        write_file(local_dir, download_bytes(download_url, token))
        return 1

    if not isinstance(payload, list):
        raise RuntimeError(f"Unexpected API response type for {remote_path}")

    local_dir.mkdir(parents=True, exist_ok=True)
    for item in payload:
        item_type = item.get("type")
        item_name = item.get("name")
        item_path = item.get("path")
        if not item_name or not item_path:
            continue

        target = local_dir / item_name
        if item_type == "file":
            download_url = item.get("download_url")
            if not download_url:
                raise RuntimeError(f"Missing download URL for file {item_path}")
            write_file(target, download_bytes(download_url, token))
            file_count += 1
        elif item_type == "dir":
            file_count += sync_contents(repo, item_path, ref, target, token)
        else:
            # Skip symlinks/submodules or unsupported entries.
            continue

    return file_count


def fetch_commit_sha(repo: str, ref: str, token: str | None) -> str:
    encoded_ref = quote(ref, safe="")
    url = f"https://api.github.com/repos/{repo}/commits/{encoded_ref}"
    payload = request_json(url, token)
    sha = payload.get("sha", "")
    if not sha:
        raise RuntimeError(f"Could not resolve commit sha for {repo}@{ref}")
    return sha


def validate_destination(dest: Path, allow_outside_root: bool) -> None:
    if allow_outside_root:
        return

    try:
        dest.relative_to(PROJECT_ROOT)
    except ValueError as exc:
        raise RuntimeError(
            f"Destination must be inside project root: {PROJECT_ROOT} (got {dest}). "
            "Use --allow-outside-root to override."
        ) from exc

    if dest == PROJECT_ROOT:
        raise RuntimeError(f"Refusing to sync into project root directly: {PROJECT_ROOT}")

    if dest in {Path("/").resolve(), Path.home().resolve()}:
        raise RuntimeError(f"Refusing unsafe destination: {dest}")


def main() -> int:
    args = parse_args()
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    dest = Path(args.dest).resolve()

    try:
        validate_destination(dest, args.allow_outside_root)
        if dest.exists() and not args.no_clean:
            if dest.is_dir():
                shutil.rmtree(dest)
            else:
                dest.unlink()

        commit_sha = fetch_commit_sha(args.repo, args.ref, token)
        file_count = sync_contents(args.repo, args.path, args.ref, dest, token)

        metadata = {
            "repo": args.repo,
            "path": args.path,
            "ref": args.ref,
            "commit_sha": commit_sha,
            "synced_at_utc": datetime.now(UTC).isoformat(),
            "files_synced": file_count,
        }
        (dest / args.metadata_file).write_text(
            json.dumps(metadata, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )

        print(f"synced {file_count} files from {args.repo}:{args.path}@{args.ref} -> {dest}")
        print(f"commit_sha={commit_sha}")
        return 0
    except (HTTPError, URLError, RuntimeError, OSError) as exc:
        print(f"sync failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
