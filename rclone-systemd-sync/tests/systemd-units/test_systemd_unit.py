from rclone_systemd_sync.models.systemd import SystemdServiceUnit, SystemdTimerUnit


def test_service_unit_renders_oneshot_service() -> None:
    unit = SystemdServiceUnit(
        name="documents",
        description="Rclone bisync job for documents",
        exec_start=(
            "/usr/bin/rclone bisync %h/Documents "
            "gdrive-allbano-documents:Documents --recover"
        ),
    )

    assert unit.filename() == "rclone-bisync-documents.service"
    assert unit.render() == (
        "[Unit]\n"
        "Description=Rclone bisync job for documents\n"
        "Wants=network-online.target\n"
        "After=network-online.target\n"
        "\n"
        "[Service]\n"
        "Type=oneshot\n"
        "ExecStart=/usr/bin/rclone bisync %h/Documents "
        "gdrive-allbano-documents:Documents --recover\n"
        "Nice=10\n"
        "IOSchedulingClass=best-effort\n"
        "IOSchedulingPriority=7\n"
        "\n"
        "[Install]\n"
        "WantedBy=default.target\n"
    )


def test_timer_unit_renders_schedule_for_matching_service() -> None:
    unit = SystemdTimerUnit(
        name="documents",
        on_calendar="*:0/15",
    )

    assert unit.filename() == "rclone-bisync-documents.timer"
    assert unit.service_filename() == "rclone-bisync-documents.service"
    assert unit.render() == (
        "[Unit]\n"
        "Description=Run rclone bisync job documents\n"
        "\n"
        "[Timer]\n"
        "OnCalendar=*:0/15\n"
        "Persistent=true\n"
        "Unit=rclone-bisync-documents.service\n"
        "\n"
        "[Install]\n"
        "WantedBy=timers.target\n"
    )
