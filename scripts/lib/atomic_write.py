"""Atomic file replacement for spec state (BUG-2026-11-03-atomic-yaml-writes, #181).

`Path.write_text()` truncates the destination first and then streams the new
bytes into it. Any concurrent reader — the dashboard snapshot loop, a subagent,
a background gate — can observe the file after the truncate and before the last
chunk lands, and fails with `yaml.scanner.ScannerError` on a file that a moment
later is perfectly valid. Interrupting the agent mid-write leaves the file
truncated for good.

`atomic_write_text()` never exposes a partial file: the bytes go to a temporary
file in the same directory, are flushed and fsynced, and only then replace the
destination with `os.replace()` (a single atomic rename on POSIX). Readers see
the old content or the new content, never a mix.

Same-directory temp file is required: `os.replace` is atomic only within one
filesystem, and `tempfile.mkstemp(dir=...)` guarantees that.
"""

from __future__ import annotations

import os
import stat
import tempfile
from pathlib import Path


def atomic_write_bytes(path: str | Path, data: bytes, mode: int | None = None) -> None:
    """Replace `path` with `data` atomically. Preserves the target's mode."""
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)

    if mode is None and target.exists():
        mode = stat.S_IMODE(target.stat().st_mode)

    fd, tmp_name = tempfile.mkstemp(dir=str(target.parent), prefix=f".{target.name}.", suffix=".tmp")
    try:
        with os.fdopen(fd, "wb") as handle:
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
        if mode is not None:
            os.chmod(tmp_name, mode)
        os.replace(tmp_name, target)
    except BaseException:
        try:
            os.unlink(tmp_name)
        except OSError:
            pass
        raise

    _fsync_dir(target.parent)


def atomic_write_text(path: str | Path, text: str, encoding: str = "utf-8", mode: int | None = None) -> None:
    """Atomic replacement for `Path.write_text()`."""
    atomic_write_bytes(path, text.encode(encoding), mode=mode)


def _fsync_dir(directory: Path) -> None:
    """Persist the rename itself. Best-effort: not every platform allows it."""
    flags = getattr(os, "O_DIRECTORY", 0)
    try:
        dir_fd = os.open(str(directory), os.O_RDONLY | flags)
    except OSError:
        return
    try:
        os.fsync(dir_fd)
    except OSError:
        pass
    finally:
        os.close(dir_fd)
