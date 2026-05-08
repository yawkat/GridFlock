paths:
    mkdir -p paths
    uv run extract_paths.py puzzle.svg paths/puzzle.scad

test:
    openscad -o /dev/null --export-format=stl test.scad

clean-docs:
    # docs task will delete any images it didn't write
    mkdir -p docs/images

banner name:
    inkscape -w 486 -h 364 docs/{{name}}.svg -o docs/{{name}}.png

banners: (banner "banner-generator-yawkat") (banner "banner-generator-perplexinglabs")

docs:
    #!/usr/bin/env -S uv run --script
    import re
    import shlex
    import subprocess
    import os
    import asyncio
    import struct
    import zlib

    openscad_pattern = re.compile(r"^\s*<!--\s*openscad (.+)\s*-->\s*$")
    concurrency = asyncio.Semaphore(8)

    png_signature = b"\x89PNG\r\n\x1a\n"

    def chunk(typ, data):
        return (
            struct.pack(">I", len(data))
            + typ
            + data
            + struct.pack(">I", zlib.crc32(typ + data) & 0xFFFFFFFF)
        )

    def bpp_for_filter(bit_depth, color_type):
        channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[color_type]
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
        out = bytearray(b"\x78\x01")
        pos = 0
        while pos < len(data):
            block = data[pos : pos + 0xFFFF]
            pos += len(block)
            final = 1 if pos == len(data) else 0
            out.append(final)
            out.extend(struct.pack("<H", len(block)))
            out.extend(struct.pack("<H", 0xFFFF - len(block)))
            out.extend(block)
        out.extend(struct.pack(">I", zlib.adler32(data) & 0xFFFFFFFF))
        return bytes(out)

    def canonicalize_png(path):
        with open(path, "rb") as f:
            data = f.read()
        if not data.startswith(png_signature):
            raise ValueError(f"{path} is not a PNG")

        idat = bytearray()
        ihdr = None
        plte = None
        trns = None
        pos = len(png_signature)
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

        width, height, bit_depth, color_type, compression, filter_method, interlace = struct.unpack(">IIBBBBB", ihdr)
        if compression != 0 or filter_method != 0 or interlace != 0:
            raise ValueError(f"Unsupported PNG encoding for {path}")
        row_bytes = (width * {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[color_type] * bit_depth + 7) // 8
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

        output = bytearray(png_signature)
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
        while True:
            async with concurrency:
                print("Running: " + shlex.join(cmd))
                proc = await asyncio.create_subprocess_exec(*cmd)
                await proc.wait()
                assert proc.returncode == 0
            if os.path.getsize(output) == 7763:
                # render failure, retry
                print(f"Render failure for `{shlex.join(cmd)}`, retrying")
                continue
            canonicalize_png(output)
            return
    
    async def main():
        tasks = []
        written = []
        for line in open("README.md"):
            match = openscad_pattern.match(line)
            if match:
                cmd = ["openscad", "--hardwarnings", "--projection=ortho", "--colorscheme=Starnight", "--render", "--imgsize=2500,1000", *shlex.split(match.group(1))]
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

    asyncio.run(main())

overlay-png name:
    inkscape -w 1600 -h 1200 docs/{{name}}.svg -o build/{{name}}.png

animation file frames delay args overlay: (overlay-png "{{name}}")
    rm -rf build/animate/{{file}}
    mkdir -p build/animate/{{file}}
    openscad --colorscheme=Prusa --imgsize=1600,1200 --render -o build/animate/{{file}}/frame.png -D total_frames={{frames}} --animate {{frames}} {{args}} docs/{{file}}.scad
    mogrify -alpha set -channel alpha -fx "g == 1.0 ? 0 : 1" build/animate/{{file}}/*
    mogrify -draw 'image SrcOver 0,0 1600,1200 build/{{overlay}}.png' build/animate/{{file}}/*
    magick -delay {{delay}} -loop 0 -dispose previous build/animate/{{file}}/* build/{{file}}.gif

title: (overlay-png "caption-title")
    openscad --colorscheme=Prusa --imgsize=1600,1200 --projection=ortho --camera 0,0,0,20,0,40,500 --render -o build/title.png docs/title.scad
    mogrify -alpha set -channel alpha -fx "g == 1.0 ? 0 : 1" build/title.png
    mogrify -draw 'image SrcOver 0,0 1600,1200 build/caption-title.png' build/title.png

#[parallel]
showcase: title (animation "animation-size" "11" "80" "-D magnets=false" "caption-size") (animation "animation-magnets" "3" "100" "" "caption-magnets") (animation "animation-size-smooth" "30" "10" "-D magnets=false --camera 0,0,0,40,0,40,400" "caption-size-smooth")

dir_intersection_fit := "build/printables/Intersection connector fit calibration files"

intersection-fit-tester-one fit:
    mkdir -p "{{dir_intersection_fit}}"
    openscad -o "{{dir_intersection_fit}}/fit-{{fit}}.stl" --export-format=binstl -D magnets=false -D BASEPLATE_DIMENSIONS='[15, 42]' -D 'plate_size=[30, 84]' -D 'bed_size=[25, 1000]' -D intersection_puzzle_fit={{fit}} gridflock.scad

intersection-fit-tester: (intersection-fit-tester-one "0.0") (intersection-fit-tester-one "0.2") (intersection-fit-tester-one "0.4") (intersection-fit-tester-one "0.6") (intersection-fit-tester-one "0.8") (intersection-fit-tester-one "1.0")

clean-printables-zip:
    rm -rf build/printables

dir_magnet_insertion := "build/printables/Magnet Insertion Jig"
dir_source := "build/printables/OpenSCAD Source"
dir_clickgroove := "build/printables/ClickGroove Files"

printables-zip: clean-printables-zip paths (intersection-fit-tester-one "0.0") (intersection-fit-tester-one "0.2") (intersection-fit-tester-one "0.4") (intersection-fit-tester-one "0.6") (intersection-fit-tester-one "0.8") (intersection-fit-tester-one "1.0")
    mkdir -p "{{dir_magnet_insertion}}"
    openscad -o "{{dir_magnet_insertion}}"/jig.stl --hardwarnings --export-format=binstl -D part='"jig"' -D show_cross_section=false mag_insert_jig.scad
    openscad -o "{{dir_magnet_insertion}}"/pusher.stl --hardwarnings --export-format=binstl -D part='"pusher"' mag_insert_jig.scad

    mkdir -p "{{dir_clickgroove}}"
    openscad -o "{{dir_clickgroove}}/ClickGroove Bin Template.stl" --hardwarnings --export-format=binstl clickgroove-base.scad

    mkdir -p "{{dir_source}}"
    cp -r paths gridflock.scad "{{dir_source}}"
    rm -f build/printables.zip
    cd build/printables && zip -r ../printables.zip .

all: paths test showcase docs printables-zip banners
