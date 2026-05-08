from rclone_systemd_sync.models.rclone import (
    ConflictLoser,
    ConflictResolve,
    RcloneBisyncOptions,
    RcloneCommand,
    RcloneMode,
    systemd_join_args,
)


def test_rclone_bisync_options_map_to_cli_args() -> None:
    options = RcloneBisyncOptions(
        create_empty_src_dirs=True,
        drive_skip_gdocs=True,
        drive_skip_shortcuts=True,
        resilient=True,
        recover=True,
        max_lock="2m",
        max_delete=20,
        conflict_resolve=ConflictResolve.NEWER,
        conflict_loser=ConflictLoser.NUM,
        track_renames=True,
        transfers=4,
        checkers=8,
        drive_chunk_size="16Mi",
        verbose=True,
        log_file="%h/.local/state/rclone/logs/documents-bisync.log",
    )

    assert options.to_args() == [
        "--create-empty-src-dirs",
        "--drive-skip-gdocs",
        "--drive-skip-shortcuts",
        "--resilient",
        "--recover",
        "--max-lock",
        "2m",
        "--max-delete",
        "20",
        "--conflict-resolve",
        "newer",
        "--conflict-loser",
        "num",
        "--track-renames",
        "--transfers",
        "4",
        "--checkers",
        "8",
        "--drive-chunk-size",
        "16Mi",
        "-v",
        "--log-file",
        "%h/.local/state/rclone/logs/documents-bisync.log",
    ]


def test_rclone_command_renders_systemd_exec_start() -> None:
    command = RcloneCommand(
        mode=RcloneMode.BISYNC,
        remote_name="gdrive-allbano-documents",
        local_path="%h/Documents",
        remote_path="Documents",
        options=RcloneBisyncOptions(
            create_empty_src_dirs=True,
            drive_skip_gdocs=True,
            recover=True,
            max_delete=20,
            verbose=True,
        ),
    )

    assert command.to_systemd_exec_start() == (
        "/usr/bin/rclone bisync %h/Documents "
        "gdrive-allbano-documents:Documents --create-empty-src-dirs "
        "--drive-skip-gdocs --recover --max-delete 20 -v"
    )


def test_systemd_join_args_quotes_whitespace() -> None:
    assert systemd_join_args(["/usr/bin/rclone", "bisync", "%h/My Documents"]) == (
        '/usr/bin/rclone bisync "%h/My Documents"'
    )
