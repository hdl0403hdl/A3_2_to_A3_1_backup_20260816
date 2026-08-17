#!/usr/bin/env python3
"""Create a deterministic inventory and SHA-256 manifest for a snapshot tree."""

from __future__ import annotations

import argparse
import hashlib
import os
import stat
from pathlib import Path


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(4 * 1024 * 1024), b""):
            value.update(block)
    return value.hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", type=Path)
    parser.add_argument("inventory", type=Path)
    parser.add_argument("sha256", type=Path)
    args = parser.parse_args()
    root = args.root.resolve()
    rows: list[str] = ["relative_path\ttype\tmode\tsize\tmtime_ns\tlink_target\tsha256"]
    sums: list[str] = []
    for path in sorted(root.rglob("*"), key=lambda p: os.fsencode(str(p.relative_to(root)))):
        rel = path.relative_to(root).as_posix()
        info = path.lstat()
        mode = stat.S_IMODE(info.st_mode)
        if path.is_symlink():
            kind, target, checksum = "symlink", os.readlink(path), ""
        elif path.is_file():
            kind, target, checksum = "file", "", digest(path)
            sums.append(f"{checksum}  {rel}")
        elif path.is_dir():
            kind, target, checksum = "directory", "", ""
        else:
            kind, target, checksum = "other", "", ""
        rows.append(
            f"{rel}\t{kind}\t{mode:04o}\t{info.st_size}\t{info.st_mtime_ns}\t"
            f"{target}\t{checksum}"
        )
    args.inventory.write_text("\n".join(rows) + "\n", encoding="utf-8")
    args.sha256.write_text("\n".join(sums) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()

