import asyncio
import os
import re
import shlex
import struct
import zlib

OPENSCAD_PATTERN = re.compile(r"^\s*<!--\s*openscad (.+)\s*-->\s*$")
CONCURRENCY = asyncio.Semaphore(8)
# PNG color types: 0=grayscale, 2=RGB, 3=indexed, 4=grayscale+alpha, 6=RGBA.
CHANNELS_BY_COLOR_TYPE = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}
# OpenSCAD intermittently writes a broken placeholder PNG of this exact size.
OPENSCAD_BROKEN_PNG_SIZE_BYTES = 7763
MAX_RENDER_RETRIES = 5
MAX_DEFLATE_BLOCK_SIZE = 0xFFFF
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def chunk(typ, data):
    return (
        struct.pack(">I", len(data))
        + typ
        + data
        + struct.pack(">I", zlib.crc32(typ + data) & 0xFFFFFFFF)
    )


def bpp_for_filter(bit_depth, color_type):
    """Return bytes-per-pixel for PNG filter reconstruction."""
    channels = CHANNELS_BY_COLOR_TYPE[color_type]
    return max(1, (channels * bit_depth + 7) // 8)


def undo_filter(filter_type, scanline, prev, bpp):
    if filter_type == 0:
        return scanline
    if filter_type == 1:
        out = bytearray(scanline)
        for i in range(len(out)):
            out[i] = (out[i] + (out[i - bpp] if i >= bpp else 0)) & 0xFF
        return bytes(out)
    if filter_type == 2:
        return bytes((scanline[i] + prev[i]) & 0xFF for i in range(len(scanline)))
    if filter_type == 3:
        out = bytearray(scanline)
        for i in range(len(out)):
            left = out[i - bpp] if i >= bpp else 0
            up = prev[i]
            out[i] = (out[i] + ((left + up) // 2)) & 0xFF
        return bytes(out)
    if filter_type == 4:
        out = bytearray(scanline)
        for i in range(len(out)):
            a = out[i - bpp] if i >= bpp else 0
            b = prev[i]
            c = prev[i - bpp] if i >= bpp else 0
            p = a + b - c
            pa = abs(p - a)
            pb = abs(p - b)
            pc = abs(p - c)
            predictor = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
            out[i] = (out[i] + predictor) & 0xFF
        return bytes(out)
    raise ValueError(f"Unsupported PNG filter type: {filter_type}")


def zlib_store(data):
    # Write deterministic store-only DEFLATE blocks to avoid version-dependent
    # compression heuristics from normal DEFLATE encoders.
    out = bytearray(b"\x78\x01")
    pos = 0
    while pos < len(data):
        block = data[pos : pos + MAX_DEFLATE_BLOCK_SIZE]
        pos += len(block)
        final = 1 if pos == len(data) else 0
        out.append(final)
        out.extend(struct.pack("<H", len(block)))
        out.extend(struct.pack("<H", (~len(block)) & 0xFFFF))
        out.extend(block)
    out.extend(struct.pack(">I", zlib.adler32(data) & 0xFFFFFFFF))
    return bytes(out)


def canonicalize_png(path):
    """Re-encode PNGs with filter type 0 to make equivalent pixels byte-identical."""
    with open(path, "rb") as f:
        data = f.read()
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError(f"{path} is not a PNG")

    idat = bytearray()
    ihdr = None
    plte = None
    trns = None
    pos = len(PNG_SIGNATURE)
    while pos < len(data):
        length = struct.unpack(">I", data[pos : pos + 4])[0]
        typ = data[pos + 4 : pos + 8]
        chunk_data = data[pos + 8 : pos + 8 + length]
        pos += 12 + length

        if typ == b"IHDR":
            ihdr = chunk_data
        elif typ == b"PLTE":
            plte = chunk_data
        elif typ == b"tRNS":
            trns = chunk_data
        elif typ == b"IDAT":
            idat.extend(chunk_data)
        elif typ == b"IEND":
            break

    ihdr_fields = struct.unpack(">IIBBBBB", ihdr)
    width, height, bit_depth, color_type, compression, filter_method, interlace = ihdr_fields
    if compression != 0 or filter_method != 0 or interlace != 0:
        raise ValueError(f"Unsupported PNG encoding for {path}")
    row_bytes = (width * CHANNELS_BY_COLOR_TYPE[color_type] * bit_depth + 7) // 8
    bpp = bpp_for_filter(bit_depth, color_type)

    raw = zlib.decompress(bytes(idat))
    expected_size = height * (1 + row_bytes)
    if len(raw) != expected_size:
        raise ValueError(f"Unexpected decompressed size for {path}")

    canonical_scanlines = bytearray()
    prev = bytes(row_bytes)
    pos = 0
    for _ in range(height):
        filter_type = raw[pos]
        pos += 1
        scanline = raw[pos : pos + row_bytes]
        pos += row_bytes
        unfiltered = undo_filter(filter_type, scanline, prev, bpp)
        canonical_scanlines.append(0)
        canonical_scanlines.extend(unfiltered)
        prev = unfiltered

    output = bytearray(PNG_SIGNATURE)
    output.extend(chunk(b"IHDR", ihdr))
    if plte is not None:
        output.extend(chunk(b"PLTE", plte))
    if trns is not None:
        output.extend(chunk(b"tRNS", trns))
    output.extend(chunk(b"IDAT", zlib_store(bytes(canonical_scanlines))))
    output.extend(chunk(b"IEND", b""))

    with open(path, "wb") as f:
        f.write(output)


async def run(cmd, output):
    retries = 0
    while True:
        async with CONCURRENCY:
            print("Running: " + shlex.join(cmd))
            proc = await asyncio.create_subprocess_exec(*cmd)
            await proc.wait()
            assert proc.returncode == 0
        if os.path.getsize(output) == OPENSCAD_BROKEN_PNG_SIZE_BYTES:
            # OpenSCAD occasionally writes a fixed-size broken PNG; retry the render.
            retries += 1
            if retries >= MAX_RENDER_RETRIES:
                raise RuntimeError(f"Render failure for `{shlex.join(cmd)}` after {retries} retries")
            print(f"Render failure for `{shlex.join(cmd)}`, retrying")
            continue
        canonicalize_png(output)
        return


async def main():
    tasks = []
    written = []
    for line in open("README.md"):
        match = OPENSCAD_PATTERN.match(line)
        if match:
            cmd = [
                "openscad",
                "--hardwarnings",
                "--projection=ortho",
                "--colorscheme=Starnight",
                "--render",
                "--imgsize=2500,1000",
                *shlex.split(match.group(1)),
            ]
            # use gridflock.scad if no other file specified
            for c in cmd:
                if ".scad" in c:
                    break
            else:
                cmd.append("gridflock.scad")
            output = cmd[cmd.index("-o") + 1]
            tasks.append(run(cmd, output))
            written.append(output)
    for f in os.listdir("docs/images"):
        if os.path.join("docs/images", f) not in written:
            os.unlink(os.path.join("docs/images", f))
    await asyncio.gather(*tasks)


if __name__ == "__main__":
    asyncio.run(main())
