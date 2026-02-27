#!/usr/bin/env python3
"""Deterministic checks for memory path normalization + allowlist policy."""

from __future__ import annotations

import re
import urllib.parse
from pathlib import PurePosixPath

DAILY_RE = re.compile(r"^memory/[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$")
WEEKLY_RE = re.compile(r"^memory/weekly/[0-9]{4}-W[0-9]{2}\.md$")


def normalize_memory_path(raw: str) -> str:
    s = urllib.parse.unquote(raw)
    s = s.replace("\\", "/")
    while "//" in s:
        s = s.replace("//", "/")
    norm = str(PurePosixPath(s))
    if norm.startswith("/"):
        norm = norm[1:]
    return norm


def is_allowed_memory_path(raw: str) -> bool:
    decoded = urllib.parse.unquote(raw).replace("\\", "/")
    if "../" in decoded or decoded.startswith("..") or "/./" in decoded:
        return False
    canonical = normalize_memory_path(raw)
    if canonical.startswith("../") or canonical == "..":
        return False
    if DAILY_RE.fullmatch(canonical):
        return True
    if WEEKLY_RE.fullmatch(canonical):
        return True
    return False


def run() -> None:
    cases = [
        ("memory/2026-02-26.md", True),
        ("memory/weekly/2026-W09.md", True),
        ("memory/2026-02-26-1448.md", False),
        ("memory/2026-02-26-missed-question.md", False),
        ("memory/weekly/2026-W9.md", False),
        ("memory\\2026-02-26.md", True),
        ("memory/../memory/2026-02-26.md", False),
        ("memory/2026-02-26.MD", False),
        ("memory/2026-02-26.markdown", False),
        ("some/other/memory/2026-02-26.md", False),
        ("memory%2F2026-02-26.md", True),
    ]

    failed: list[str] = []
    for raw, expected in cases:
        actual = is_allowed_memory_path(raw)
        if actual != expected:
            failed.append(f"{raw!r}: expected {expected}, got {actual}")

    if failed:
        raise SystemExit("\n".join(failed))

    print("all memory path guard checks passed")


if __name__ == "__main__":
    run()
