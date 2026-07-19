import hashlib
import os
import platform
import shutil
import stat
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path


OPENSCAD_VERSION = "2026.07.16"
OPENSCAD_URL = (
    f"https://files.openscad.org/snapshots/"
    f"OpenSCAD-{OPENSCAD_VERSION}-x86_64.AppImage"
)
OPENSCAD_SHA256 = "85000c7839cf96ca824511d9da38091683e3c6f71a390205ef4dd07e62ed97b4"


def _cache_parent() -> Path:
    xdg_cache_home = os.environ.get("XDG_CACHE_HOME")
    if xdg_cache_home:
        return Path(xdg_cache_home) / "gridflock"
    return Path.home() / ".cache" / "gridflock"


def _download(destination: Path) -> None:
    digest = hashlib.sha256()
    print(f"Downloading OpenSCAD {OPENSCAD_VERSION} AppImage", file=sys.stderr)
    with urllib.request.urlopen(OPENSCAD_URL) as response, destination.open("wb") as output:
        while chunk := response.read(1024 * 1024):
            digest.update(chunk)
            output.write(chunk)
    actual_sha256 = digest.hexdigest()
    if actual_sha256 != OPENSCAD_SHA256:
        raise RuntimeError(
            f"OpenSCAD AppImage checksum mismatch: expected {OPENSCAD_SHA256}, "
            f"got {actual_sha256}"
        )
    destination.chmod(destination.stat().st_mode | stat.S_IXUSR)


def openscad_path() -> Path:
    if platform.system() != "Linux" or platform.machine() not in {"x86_64", "AMD64"}:
        raise RuntimeError("The pinned OpenSCAD AppImage requires x86_64 Linux")

    cache_parent = _cache_parent()
    cache_directory = cache_parent / f"openscad-{OPENSCAD_VERSION}-{OPENSCAD_SHA256[:12]}"
    executable = cache_directory / "AppRun"
    if executable.is_file():
        return executable

    cache_parent.mkdir(parents=True, exist_ok=True)
    temporary_directory = Path(tempfile.mkdtemp(prefix="openscad-", dir=cache_parent))
    try:
        appimage = temporary_directory / "OpenSCAD.AppImage"
        _download(appimage)
        subprocess.run(
            [appimage, "--appimage-extract"],
            cwd=temporary_directory,
            check=True,
            stdout=subprocess.DEVNULL,
        )
        extracted = temporary_directory / "squashfs-root"
        try:
            extracted.rename(cache_directory)
        except FileExistsError:
            # Another concurrent invocation populated the same immutable cache.
            pass
    finally:
        shutil.rmtree(temporary_directory, ignore_errors=True)

    if not executable.is_file():
        raise RuntimeError("OpenSCAD AppImage extraction did not produce AppRun")
    return executable


if __name__ == "__main__":
    executable = openscad_path()
    os.execv(executable, [str(executable), *sys.argv[1:]])
