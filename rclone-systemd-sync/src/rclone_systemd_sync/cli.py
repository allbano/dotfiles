from __future__ import annotations

from pathlib import Path
from typing import Annotated

import typer

from rclone_systemd_sync.models.rclone import (
    ConflictLoser,
    ConflictResolve,
    RcloneBisyncOptions,
    RcloneCommand,
    RcloneMode,
)
from rclone_systemd_sync.models.jobs import RcloneJob
from rclone_systemd_sync.models.systemd import SystemdTimerUnit
from rclone_systemd_sync.services.filesystem import (
    default_systemd_user_dir,
    write_unit_file,
)
from rclone_systemd_sync.services.systemctl import systemctl_user, timer_unit_name


app = typer.Typer(no_args_is_help=True)
config_app = typer.Typer(no_args_is_help=True)
systemd_app = typer.Typer(no_args_is_help=True)

app.add_typer(config_app, name="config")
app.add_typer(systemd_app, name="systemd")


NameArgument = Annotated[str, typer.Argument(help="Nome logico do job. Ex: documents")]
OutputDirOption = Annotated[
    Path,
    typer.Option(
        "--output-dir",
        help="Diretorio onde os arquivos systemd user serao gerados.",
    ),
]


@config_app.command("service")
def config_service(
    name: NameArgument,
    remote_name: Annotated[
        str, typer.Argument(help="Nome do remote rclone. Ex: gdrive-allbano-documents")
    ],
    local_path: Annotated[str, typer.Argument(help="Caminho local. Ex: %h/Documents")],
    remote_path: Annotated[str, typer.Argument(help="Pasta remota. Ex: Documents")],
    mode: Annotated[RcloneMode, typer.Option("--mode")] = RcloneMode.BISYNC,
    create_empty_src_dirs: Annotated[
        bool, typer.Option("--create-empty-src-dirs")
    ] = False,
    drive_skip_gdocs: Annotated[bool, typer.Option("--drive-skip-gdocs")] = False,
    drive_skip_shortcuts: Annotated[bool, typer.Option("--drive-skip-shortcuts")] = False,
    resilient: Annotated[bool, typer.Option("--resilient")] = False,
    recover: Annotated[bool, typer.Option("--recover")] = False,
    max_lock: Annotated[str | None, typer.Option("--max-lock")] = None,
    max_delete: Annotated[int | None, typer.Option("--max-delete")] = None,
    conflict_resolve: Annotated[
        ConflictResolve | None, typer.Option("--conflict-resolve")
    ] = None,
    conflict_loser: Annotated[
        ConflictLoser | None, typer.Option("--conflict-loser")
    ] = None,
    track_renames: Annotated[bool, typer.Option("--track-renames")] = False,
    transfers: Annotated[int | None, typer.Option("--transfers")] = None,
    checkers: Annotated[int | None, typer.Option("--checkers")] = None,
    drive_chunk_size: Annotated[str | None, typer.Option("--drive-chunk-size")] = None,
    verbose: Annotated[bool, typer.Option("-v", "--verbose")] = False,
    debug: Annotated[bool, typer.Option("--debug")] = False,
    log_file: Annotated[str | None, typer.Option("--log-file")] = None,
    log_level: Annotated[str | None, typer.Option("--log-level")] = None,
    rclone_bin: Annotated[str, typer.Option("--rclone-bin")] = "/usr/bin/rclone",
    output_dir: OutputDirOption = default_systemd_user_dir(),
) -> None:
    options = RcloneBisyncOptions(
        create_empty_src_dirs=create_empty_src_dirs,
        drive_skip_gdocs=drive_skip_gdocs,
        drive_skip_shortcuts=drive_skip_shortcuts,
        resilient=resilient,
        recover=recover,
        max_lock=max_lock,
        max_delete=max_delete,
        conflict_resolve=conflict_resolve,
        conflict_loser=conflict_loser,
        track_renames=track_renames,
        transfers=transfers,
        checkers=checkers,
        drive_chunk_size=drive_chunk_size,
        verbose=verbose,
        debug=debug,
        log_file=log_file,
        log_level=log_level,
    )
    rclone_command = RcloneCommand(
        mode=mode,
        remote_name=remote_name,
        local_path=local_path,
        remote_path=remote_path,
        options=options,
        rclone_bin=rclone_bin,
    )
    job = RcloneJob(
        name=name,
        command=rclone_command,
    )
    service = job.service_unit()

    service_path = write_unit_file(output_dir, service.filename(), service.render())
    typer.echo(f"Generated: {service_path}")


@config_app.command("timer")
def config_timer(
    name: NameArgument,
    on_boot_sec: Annotated[str | None, typer.Option("--on-boot-sec")] = None,
    on_unit_active_sec: Annotated[
        str | None, typer.Option("--on-unit-active-sec")
    ] = None,
    on_calendar: Annotated[str | None, typer.Option("--on-calendar")] = None,
    persistent: Annotated[bool, typer.Option("--persistent/--no-persistent")] = True,
    output_dir: OutputDirOption = default_systemd_user_dir(),
) -> None:
    timer = SystemdTimerUnit(
        name=name,
        on_boot_sec=on_boot_sec,
        on_unit_active_sec=on_unit_active_sec,
        on_calendar=on_calendar,
        persistent=persistent,
    )

    timer_path = write_unit_file(output_dir, timer.filename(), timer.render())
    typer.echo(f"Generated: {timer_path}")


@systemd_app.command("reload")
def systemd_reload() -> None:
    result = systemctl_user("daemon-reload")
    _finish_systemctl(result.returncode, result.stdout, result.stderr, "Reloaded systemd user daemon")


@systemd_app.command("enable")
def systemd_enable(
    name: NameArgument,
    now: Annotated[bool, typer.Option("--now/--no-now")] = True,
) -> None:
    args = ["enable"]
    if now:
        args.append("--now")
    args.append(timer_unit_name(name))

    result = systemctl_user(*args)
    _finish_systemctl(
        result.returncode,
        result.stdout,
        result.stderr,
        f"Enabled {timer_unit_name(name)}",
    )


def _finish_systemctl(
    returncode: int,
    stdout: str,
    stderr: str,
    success_message: str,
) -> None:
    if returncode != 0:
        message = stderr.strip() or stdout.strip() or "systemctl failed"
        typer.secho(message, err=True, fg=typer.colors.RED)
        raise typer.Exit(returncode)

    output = stdout.strip()
    typer.echo(output or success_message)
