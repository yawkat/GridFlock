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
DISTANCE_BASES = (
    1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257,
    385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289,
    16385, 24577,
)
DISTANCE_EXTRA_BITS = (
    0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8,
    8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13,
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


def _write_match(writer: _BitWriter, length: int, distance: int) -> None:
    for index, (base, extra_bits) in enumerate(
        zip(LENGTH_BASES, LENGTH_EXTRA_BITS, strict=True)
    ):
        maximum = base + (1 << extra_bits) - 1
        if length <= maximum:
            _write_fixed_symbol(writer, 257 + index)
            writer.write(length - base, extra_bits)
            break
    else:
        raise ValueError(f"Invalid deflate match length: {length}")

    for symbol, (base, extra_bits) in enumerate(
        zip(DISTANCE_BASES, DISTANCE_EXTRA_BITS, strict=True)
    ):
        maximum = base + (1 << extra_bits) - 1
        if distance <= maximum:
            writer.write(_reverse_bits(symbol, 5), 5)
            writer.write(distance - base, extra_bits)
            break
    else:
        raise ValueError(f"Invalid deflate match distance: {distance}")


def _deterministic_zlib(data: bytes) -> bytes:
    """Encode a deterministic fixed-Huffman deflate stream.

    The match finder deliberately considers exactly one previous position for
    each three-byte sequence. This keeps both its decisions and its output
    independent of the host zlib implementation.
    """
    writer = _BitWriter()
    writer.write(1, 1)  # Final block.
    writer.write(1, 2)  # Fixed-Huffman block.

    previous_positions: dict[int, int] = {}
    position = 0
    data_length = len(data)
    while position < data_length:
        match_length = 0
        match_distance = 0
        if position + 2 < data_length:
            key = (data[position] << 16) | (data[position + 1] << 8) | data[position + 2]
            previous = previous_positions.get(key)
            if previous is not None and position - previous <= 32768:
                maximum = min(258, data_length - position)
                while (
                    match_length < maximum
                    and data[previous + match_length] == data[position + match_length]
                ):
                    match_length += 1
                if match_length >= 3:
                    match_distance = position - previous

        consumed = match_length if match_length >= 3 else 1
        if match_length >= 3:
            _write_match(writer, match_length, match_distance)
        else:
            _write_fixed_symbol(writer, data[position])

        update_end = min(position + consumed, data_length - 2)
        for update_position in range(position, update_end):
            key = (
                (data[update_position] << 16)
                | (data[update_position + 1] << 8)
                | data[update_position + 2]
            )
            previous_positions[key] = update_position
        position += consumed

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


def canonicalize(path: Path | str) -> None:
    path = Path(path)
    with Image.open(path) as source:
        normalized = source.convert("RGB")
        size = normalized.size
        pixels = normalized.tobytes()

    temporary_path = path.with_name(f".{path.name}.canonical.png")
    try:
        image = Image.frombytes("RGB", size, pixels)
        temporary_path.write_bytes(_png_bytes(image))
        temporary_path.replace(path)
    finally:
        temporary_path.unlink(missing_ok=True)


if __name__ == "__main__":
    for argument in sys.argv[1:]:
        canonicalize(Path(argument))
