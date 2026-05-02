from pathlib import Path

from typer.testing import CliRunner

from rclone_systemd_sync.cli import app


runner = CliRunner()


def test_config_service_writes_systemd_service(tmp_path: Path) -> None:
    result = runner.invoke(
        app,
        [
            "config",
            "service",
            "documents",
            "gdrive-allbano-documents",
            "%h/Documents",
            "Documents",
            "--mode",
            "bisync",
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
            "--verbose",
            "--log-file",
            "%h/.local/state/rclone/logs/documents-bisync.log",
            "--output-dir",
            str(tmp_path),
        ],
    )

    service_path = tmp_path / "rclone-bisync-documents.service"
    assert result.exit_code == 0
    assert f"Generated: {service_path}" in result.output
    assert service_path.read_text(encoding="utf-8") == (
        "[Unit]\n"
        "Description=Rclone bisync job for documents\n"
        "Wants=network-online.target\n"
        "After=network-online.target\n"
        "\n"
        "[Service]\n"
        "Type=oneshot\n"
        "ExecStart=/usr/bin/rclone bisync %h/Documents "
        "gdrive-allbano-documents:Documents --create-empty-src-dirs "
        "--drive-skip-gdocs --drive-skip-shortcuts --resilient --recover "
        "--max-lock 2m --max-delete 20 --conflict-resolve newer "
        "--conflict-loser num --track-renames --transfers 4 --checkers 8 "
        "--drive-chunk-size 16Mi -v --log-file "
        "%h/.local/state/rclone/logs/documents-bisync.log\n"
        "Nice=10\n"
        "IOSchedulingClass=best-effort\n"
        "IOSchedulingPriority=7\n"
        "\n"
        "[Install]\n"
        "WantedBy=default.target\n"
    )


def test_config_timer_writes_systemd_timer(tmp_path: Path) -> None:
    result = runner.invoke(
        app,
        [
            "config",
            "timer",
            "documents",
            "--on-boot-sec",
            "5min",
            "--on-unit-active-sec",
            "30min",
            "--persistent",
            "--output-dir",
            str(tmp_path),
        ],
    )

    timer_path = tmp_path / "rclone-bisync-documents.timer"
    assert result.exit_code == 0
    assert f"Generated: {timer_path}" in result.output
    assert timer_path.read_text(encoding="utf-8") == (
        "[Unit]\n"
        "Description=Run rclone bisync job documents\n"
        "\n"
        "[Timer]\n"
        "OnBootSec=5min\n"
        "OnUnitActiveSec=30min\n"
        "Persistent=true\n"
        "Unit=rclone-bisync-documents.service\n"
        "\n"
        "[Install]\n"
        "WantedBy=timers.target\n"
    )


def test_systemd_enable_calls_user_timer(monkeypatch) -> None:
    calls: list[tuple[str, ...]] = []

    class Result:
        returncode = 0
        stdout = ""
        stderr = ""

    def fake_systemctl_user(*args: str) -> Result:
        calls.append(args)
        return Result()

    monkeypatch.setattr("rclone_systemd_sync.cli.systemctl_user", fake_systemctl_user)

    result = runner.invoke(app, ["systemd", "enable", "documents"])

    assert result.exit_code == 0
    assert calls == [("enable", "--now", "rclone-bisync-documents.timer")]
    assert "Enabled rclone-bisync-documents.timer" in result.output
