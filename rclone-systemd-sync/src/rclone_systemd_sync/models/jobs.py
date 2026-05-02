from __future__ import annotations

from dataclasses import dataclass

from rclone_systemd_sync.models.rclone import RcloneCommand
from rclone_systemd_sync.models.systemd import SystemdServiceUnit, SystemdTimerUnit


@dataclass(frozen=True)
class RcloneJob:
    name: str
    command: RcloneCommand

    def service_unit(self) -> SystemdServiceUnit:
        return SystemdServiceUnit(
            name=self.name,
            description=f"Rclone {self.command.mode.value} job for {self.name}",
            exec_start=self.command.to_systemd_exec_start(),
        )

    def timer_unit(
        self,
        *,
        on_boot_sec: str | None = None,
        on_unit_active_sec: str | None = None,
        on_calendar: str | None = None,
        persistent: bool = True,
    ) -> SystemdTimerUnit:
        return SystemdTimerUnit(
            name=self.name,
            on_boot_sec=on_boot_sec,
            on_unit_active_sec=on_unit_active_sec,
            on_calendar=on_calendar,
            persistent=persistent,
        )
