import struct
import sys
import zlib
from pathlib import Path

from PIL import Image


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
LENGTH_BASES = (
    3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43,
    51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258,
)
LENGTH_EXTRA_BITS = (
    0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3,
    3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0,
)


class _BitWriter:
    def __init__(self) -> None:
        self.output = bytearray()
        self.bits = 0
        self.bit_count = 0

    def write(self, value: int, width: int) -> None:
        self.bits |= value << self.bit_count
        self.bit_count += width
        while self.bit_count >= 8:
            self.output.append(self.bits & 0xFF)
            self.bits >>= 8
            self.bit_count -= 8

    def finish(self) -> bytes:
        if self.bit_count:
            self.output.append(self.bits & 0xFF)
        return bytes(self.output)


def _reverse_bits(value: int, width: int) -> int:
    result = 0
    for _ in range(width):
        result = (result << 1) | (value & 1)
        value >>= 1
    return result


def _write_fixed_symbol(writer: _BitWriter, symbol: int) -> None:
    if symbol <= 143:
        code, width = 0x30 + symbol, 8
    elif symbol <= 255:
        code, width = 0x190 + symbol - 144, 9
    elif symbol <= 279:
        code, width = symbol - 256, 7
    else:
        code, width = 0xC0 + symbol - 280, 8
    writer.write(_reverse_bits(code, width), width)


def _write_length(writer: _BitWriter, length: int) -> None:
    for index, (base, extra_bits) in enumerate(
        zip(LENGTH_BASES, LENGTH_EXTRA_BITS, strict=True)
    ):
        maximum = base + (1 << extra_bits) - 1
        if length <= maximum:
            _write_fixed_symbol(writer, 257 + index)
            writer.write(length - base, extra_bits)
            # Distance one uses fixed distance symbol zero with no extra bits.
            writer.write(0, 5)
            return
    raise ValueError(f"Invalid deflate match length: {length}")


def _deterministic_zlib(data: bytes) -> bytes:
    """Encode a deterministic fixed-Huffman deflate stream.

    PNG's Sub filter turns the large flat areas in documentation renders into
    runs of zeroes. Encoding those runs as distance-one matches keeps the files
    compact without relying on the host zlib implementation.
    """
    writer = _BitWriter()
    writer.write(1, 1)  # Final block.
    writer.write(1, 2)  # Fixed-Huffman block.

    position = 0
    while position < len(data):
        value = data[position]
        run_end = position + 1
        while run_end < len(data) and data[run_end] == value:
            run_end += 1

        if position == 0 or data[position - 1] != value:
            _write_fixed_symbol(writer, value)
            position += 1

        remaining = run_end - position
        while remaining >= 3:
            length = min(remaining, 258)
            if remaining - length in {1, 2}:
                length -= 3 - (remaining - length)
            _write_length(writer, length)
            position += length
            remaining -= length
        while position < run_end:
            _write_fixed_symbol(writer, value)
            position += 1

    _write_fixed_symbol(writer, 256)
    deflate = writer.finish()
    checksum = zlib.adler32(data) & 0xFFFFFFFF
    return b"\x78\x01" + deflate + struct.pack(">I", checksum)


def _chunk(kind: bytes, data: bytes) -> bytes:
    checksum = zlib.crc32(kind + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", checksum)


def _png_bytes(image: Image.Image) -> bytes:
    image = image.convert("RGB")
    pixels = image.tobytes()
    stride = image.width * 3
    filtered = bytearray()
    for row_start in range(0, len(pixels), stride):
        row = pixels[row_start : row_start + stride]
        filtered.append(1)  # Sub filter.
        for index, value in enumerate(row):
            left = row[index - 3] if index >= 3 else 0
            filtered.append((value - left) & 0xFF)

    header = struct.pack(">IIBBBBB", image.width, image.height, 8, 2, 0, 0, 0)
    return b"".join(
        (
            PNG_SIGNATURE,
            _chunk(b"IHDR", header),
            _chunk(b"IDAT", _deterministic_zlib(bytes(filtered))),
            _chunk(b"IEND", b""),
        )
    )


def canonicalize(path: Path | str, reference: Path | str | None = None) -> bool:
    """Canonicalize ``path``, unless its pixels already match ``reference``.

    Returns whether the caller should replace the reference with the result.
    Keeping an identical checked-in reference avoids rewriting legacy PNGs just
    to migrate their encoding. New or visually changed images use the fully
    deterministic encoder above.
    """
    path = Path(path)
    with Image.open(path) as source:
        normalized = source.convert("RGB")
        size = normalized.size
        pixels = normalized.tobytes()

    if reference is not None:
        reference_path = Path(reference)
        if reference_path.is_file():
            with Image.open(reference_path) as existing:
                existing = existing.convert("RGB")
                if existing.size == size and existing.tobytes() == pixels:
                    return False

    temporary_path = path.with_name(f".{path.name}.canonical.png")
    try:
        image = Image.frombytes("RGB", size, pixels)
        temporary_path.write_bytes(_png_bytes(image))
        temporary_path.replace(path)
    finally:
        temporary_path.unlink(missing_ok=True)
    return True


if __name__ == "__main__":
    for argument in sys.argv[1:]:
        canonicalize(Path(argument))
