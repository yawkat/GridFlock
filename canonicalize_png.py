import os
import sys
from pathlib import Path

from PIL import Image


def canonicalize(path: Path | str) -> None:
    path = Path(path)
    temporary_path = path.with_name(f".{path.name}.canonical.png")
    try:
        with Image.open(path) as image:
            # Strip encoder-specific metadata and normalize the pixel format. The
            # renderer itself is made deterministic by softpipe and OpenSCAD's
            # predictible-output feature.
            normalized = image.convert("RGB")
            normalized.save(
                temporary_path,
                format="PNG",
                optimize=False,
                compress_level=9,
            )
        os.replace(temporary_path, path)
    finally:
        temporary_path.unlink(missing_ok=True)


if __name__ == "__main__":
    for argument in sys.argv[1:]:
        canonicalize(Path(argument))
