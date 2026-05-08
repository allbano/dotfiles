from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class SystemdServiceUnit:
    name: str
    description: str
    exec_start: str
    after: str = "network-online.target"
    wants: str = "network-online.target"
    nice: int = 10
    io_scheduling_class: str = "best-effort"
    io_scheduling_priority: int = 7

    def filename(self) -> str:
        return f"rclone-bisync-{self.name}.service"

    def render(self) -> str:
        return "\n".join(
            [
                "[Unit]",
                f"Description={self.description}",
                f"Wants={self.wants}",
                f"After={self.after}",
                "",
                "[Service]",
                "Type=oneshot",
                f"ExecStart={self.exec_start}",
                f"Nice={self.nice}",
                f"IOSchedulingClass={self.io_scheduling_class}",
                f"IOSchedulingPriority={self.io_scheduling_priority}",
                "",
                "[Install]",
                "WantedBy=default.target",
                "",
            ]
        )


@dataclass(frozen=True)
class SystemdTimerUnit:
    name: str
    on_boot_sec: str | None = None
    on_unit_active_sec: str | None = None
    on_calendar: str | None = None
    persistent: bool = True

    def filename(self) -> str:
        return f"rclone-bisync-{self.name}.timer"

    def service_filename(self) -> str:
        return f"rclone-bisync-{self.name}.service"

    def render(self) -> str:
        timer_lines: list[str] = []

        if self.on_boot_sec:
            timer_lines.append(f"OnBootSec={self.on_boot_sec}")
        if self.on_unit_active_sec:
            timer_lines.append(f"OnUnitActiveSec={self.on_unit_active_sec}")
        if self.on_calendar:
            timer_lines.append(f"OnCalendar={self.on_calendar}")

        timer_lines.append(f"Persistent={_systemd_bool(self.persistent)}")
        timer_lines.append(f"Unit={self.service_filename()}")

        return "\n".join(
            [
                "[Unit]",
                f"Description=Run rclone bisync job {self.name}",
                "",
                "[Timer]",
                *timer_lines,
                "",
                "[Install]",
                "WantedBy=timers.target",
                "",
            ]
        )


def _systemd_bool(value: bool) -> str:
    return "true" if value else "false"
