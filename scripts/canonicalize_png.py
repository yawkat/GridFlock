import os
import sys
from pathlib import Path

import png
from zopfli.zlib import compress


class _ZopfliCompressor:
    def __init__(self) -> None:
        self.data = bytearray()

    def compress(self, data: bytes) -> bytes:
        self.data.extend(data)
        return b""

    def flush(self) -> bytes:
        return compress(bytes(self.data), numiterations=1)


def canonicalize(path: Path | str) -> None:
    path = Path(path)
    temporary_path = path.with_name(f".{path.name}.canonical.png")
    original_compressobj = png.zlib.compressobj
    try:
        width, height, rows, _ = png.Reader(filename=path).asRGB8()
        # PyPNG always uses PNG filter 0. Substitute its streaming zlib object
        # with Zopfli so compression is deterministic across zlib versions.
        png.zlib.compressobj = lambda *_args, **_kwargs: _ZopfliCompressor()
        with temporary_path.open("wb") as output:
            png.Writer(width, height, greyscale=False, alpha=False).write(output, rows)
        os.replace(temporary_path, path)
    finally:
        png.zlib.compressobj = original_compressobj
        temporary_path.unlink(missing_ok=True)


if __name__ == "__main__":
    for argument in sys.argv[1:]:
        canonicalize(Path(argument))
