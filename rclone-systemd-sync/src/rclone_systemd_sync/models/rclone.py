from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum


class RcloneMode(StrEnum):
    BISYNC = "bisync"
    SYNC = "sync"
    COPY = "copy"


class ConflictResolve(StrEnum):
    NEWER = "newer"
    OLDER = "older"
    LARGER = "larger"
    SMALLER = "smaller"
    NONE = "none"


class ConflictLoser(StrEnum):
    NUM = "num"
    PATH1 = "path1"
    PATH2 = "path2"
    DELETE = "delete"


@dataclass(frozen=True)
class RcloneBisyncOptions:
    create_empty_src_dirs: bool = False
    drive_skip_gdocs: bool = False
    drive_skip_shortcuts: bool = False
    resilient: bool = False
    recover: bool = False
    max_lock: str | None = None
    max_delete: int | None = None
    conflict_resolve: ConflictResolve | None = None
    conflict_loser: ConflictLoser | None = None
    track_renames: bool = False
    transfers: int | None = None
    checkers: int | None = None
    drive_chunk_size: str | None = None
    verbose: bool = False
    debug: bool = False
    log_file: str | None = None
    log_level: str | None = None

    def to_args(self) -> list[str]:
        args: list[str] = []

        if self.create_empty_src_dirs:
            args.append("--create-empty-src-dirs")
        if self.drive_skip_gdocs:
            args.append("--drive-skip-gdocs")
        if self.drive_skip_shortcuts:
            args.append("--drive-skip-shortcuts")
        if self.resilient:
            args.append("--resilient")
        if self.recover:
            args.append("--recover")
        if self.max_lock:
            args.extend(["--max-lock", self.max_lock])
        if self.max_delete is not None:
            args.extend(["--max-delete", str(self.max_delete)])
        if self.conflict_resolve:
            args.extend(["--conflict-resolve", self.conflict_resolve.value])
        if self.conflict_loser:
            args.extend(["--conflict-loser", self.conflict_loser.value])
        if self.track_renames:
            args.append("--track-renames")
        if self.transfers is not None:
            args.extend(["--transfers", str(self.transfers)])
        if self.checkers is not None:
            args.extend(["--checkers", str(self.checkers)])
        if self.drive_chunk_size:
            args.extend(["--drive-chunk-size", self.drive_chunk_size])
        if self.debug:
            args.append("-vv")
        elif self.verbose:
            args.append("-v")
        if self.log_file:
            args.extend(["--log-file", self.log_file])
        if self.log_level:
            args.extend(["--log-level", self.log_level])

        return args


@dataclass(frozen=True)
class RcloneCommand:
    mode: RcloneMode
    remote_name: str
    local_path: str
    remote_path: str
    options: RcloneBisyncOptions
    rclone_bin: str = "/usr/bin/rclone"

    @property
    def full_remote_path(self) -> str:
        return f"{self.remote_name}:{self.remote_path}"

    def to_argv(self) -> list[str]:
        return [
            self.rclone_bin,
            self.mode.value,
            self.local_path,
            self.full_remote_path,
            *self.options.to_args(),
        ]

    def to_systemd_exec_start(self) -> str:
        return systemd_join_args(self.to_argv())


def systemd_join_args(args: list[str]) -> str:
    return " ".join(_systemd_escape_arg(arg) for arg in args)


def _systemd_escape_arg(arg: str) -> str:
    if arg == "":
        return '""'

    needs_quotes = any(char.isspace() for char in arg) or any(
        char in arg for char in ('"', "\\")
    )
    if not needs_quotes:
        return arg

    escaped = arg.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'
