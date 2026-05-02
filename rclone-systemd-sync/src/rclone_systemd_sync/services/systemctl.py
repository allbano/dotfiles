from __future__ import annotations

import subprocess


def systemctl_user(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["systemctl", "--user", *args],
        check=False,
        text=True,
        capture_output=True,
    )


def timer_unit_name(job_name: str) -> str:
    return f"rclone-bisync-{job_name}.timer"
