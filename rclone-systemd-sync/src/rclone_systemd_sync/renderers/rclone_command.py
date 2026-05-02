from __future__ import annotations

from rclone_systemd_sync.models.rclone import RcloneCommand, systemd_join_args


def render_exec_start(command: RcloneCommand) -> str:
    return systemd_join_args(command.to_argv())
