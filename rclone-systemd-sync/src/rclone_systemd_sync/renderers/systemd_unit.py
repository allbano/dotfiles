from __future__ import annotations

from rclone_systemd_sync.models.systemd import SystemdServiceUnit, SystemdTimerUnit


def render_service(unit: SystemdServiceUnit) -> str:
    return unit.render()


def render_timer(unit: SystemdTimerUnit) -> str:
    return unit.render()
