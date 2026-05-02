from __future__ import annotations

from pathlib import Path


def default_systemd_user_dir() -> Path:
    return Path.home() / ".config/systemd/user"


def write_unit_file(output_dir: Path, filename: str, content: str) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / filename
    output_path.write_text(content, encoding="utf-8")
    return output_path
