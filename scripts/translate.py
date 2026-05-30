#!/usr/bin/env -S uv run python
"""
translate.py — Incremental translation detection and cache management.

Does NOT call any translation API directly. Instead, it:
  1. --detect : scans zh posts, compares against cache, prints files that need
     translation (new or modified since last translation).
  2. --mark-done : updates cache after translation is done (marks files as
     translated so they won't be re-translated next time).

Translation itself is done by Claude Code (via the /translate skill), which
has DeepSeek API already configured.

Cache: scripts/.translate_cache/  (MD5 hash per file)

Usage:
  uv run python scripts/translate.py --detect          # list files needing translation
  uv run python scripts/translate.py --mark-done <...> # mark file(s) as translated
  uv run python scripts/translate.py --reset           # clear all cache
  uv run python scripts/translate.py --status          # show translation coverage
"""

import hashlib
import json
import os
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = ROOT_DIR / "hugo" / "content.zh" / "posts"
DST_DIR = ROOT_DIR / "hugo" / "content.en" / "posts"
CACHE_DIR = ROOT_DIR / "scripts" / ".translate_cache"


def file_hash(path: Path) -> str:
    """MD5 hash of file content."""
    return hashlib.md5(path.read_bytes()).hexdigest()


def detect() -> list[dict]:
    """
    Find files that need translation.
    Returns list of {"rel": "relative/path.md", "reason": "new"|"modified"}.
    """
    if not SRC_DIR.is_dir():
        print("[translate] No source directory found. Run sync.sh first.", file=sys.stderr)
        return []

    results = []
    for md in sorted(SRC_DIR.rglob("*.md")):
        rel = str(md.relative_to(SRC_DIR))
        cache_file = CACHE_DIR / file_hash(md)

        if not cache_file.exists():
            # Either new file or content changed since last translate
            reason = "modified" if (DST_DIR / rel).exists() else "new"
            results.append({"rel": rel, "reason": reason})

    return results


def mark_done(paths: list[str]) -> int:
    """Write cache entries for translated files. Returns count updated."""
    count = 0
    for p in paths:
        src = SRC_DIR / p
        if not src.exists():
            print(f"[translate] WARNING: source not found: {p}", file=sys.stderr)
            continue
        h = file_hash(src)
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        (CACHE_DIR / h).write_text(p, encoding="utf-8")  # store rel path for debugging
        count += 1
    return count


def show_status():
    """Print translation coverage status."""
    if not SRC_DIR.is_dir():
        print("No source directory.")
        return

    total = 0
    translated = 0
    for md in sorted(SRC_DIR.rglob("*.md")):
        total += 1
        rel = str(md.relative_to(SRC_DIR))
        h = file_hash(md)
        cache_file = CACHE_DIR / h
        en_file = DST_DIR / rel

        if cache_file.exists() and en_file.exists():
            translated += 1
            print(f"  [OK]  {rel}")
        elif en_file.exists() and not cache_file.exists():
            print(f"  [!]  {rel}  (stale — modified since last translate)")
        else:
            print(f"  [--] {rel}  (no translation)")

    pct = (translated / total * 100) if total > 0 else 0
    print(f"\n{translated}/{total} up to date ({pct:.0f}%)")


def main():
    if "--detect" in sys.argv:
        files = detect()
        if not files:
            print("[translate] All files up to date.")
            return
        # Output as JSON for machine parsing
        print(json.dumps(files, ensure_ascii=False, indent=2))
        # Also print human-readable summary to stderr
        new = sum(1 for f in files if f["reason"] == "new")
        mod = sum(1 for f in files if f["reason"] == "modified")
        print(f"[translate] {len(files)} file(s) need translation ({new} new, {mod} modified)", file=sys.stderr)

    elif "--mark-done" in sys.argv:
        idx = sys.argv.index("--mark-done")
        paths = sys.argv[idx + 1:]
        if not paths:
            print("[translate] Usage: translate.py --mark-done <file1> [file2 ...]", file=sys.stderr)
            sys.exit(1)
        n = mark_done(paths)
        print(f"[translate] Marked {n} file(s) as translated.")

    elif "--reset" in sys.argv:
        if CACHE_DIR.exists():
            import shutil
            shutil.rmtree(CACHE_DIR)
            print("[translate] Cache cleared.")
        else:
            print("[translate] No cache to clear.")

    elif "--status" in sys.argv:
        show_status()

    else:
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()
