import os
import sys
from pathlib import Path

from PIL import Image, ImageFilter
from PIL.PngImagePlugin import PngInfo


CANONICAL_VERSION = "1"


def canonicalize(path: Path | str) -> None:
    path = Path(path)
    temporary_path = path.with_name(f".{path.name}.canonical.png")
    try:
        with Image.open(path) as image:
            # OpenSCAD produces opaque images. Normalize its isolated rasterization
            # noise once, then mark the deterministic output to keep this idempotent.
            normalized = image.convert("RGB")
            if image.info.get("GridFlockCanonicalVersion") != CANONICAL_VERSION:
                normalized = normalized.filter(ImageFilter.MedianFilter(5))
            metadata = PngInfo()
            metadata.add_text("GridFlockCanonicalVersion", CANONICAL_VERSION)
            normalized.save(
                temporary_path,
                format="PNG",
                optimize=False,
                compress_level=9,
                pnginfo=metadata,
            )
        os.replace(temporary_path, path)
    finally:
        temporary_path.unlink(missing_ok=True)


if __name__ == "__main__":
    for argument in sys.argv[1:]:
        canonicalize(Path(argument))
