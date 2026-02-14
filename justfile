paths:
    mkdir -p paths
    uv run extract_paths.py puzzle.svg paths/puzzle.scad

test:
    openscad -o /dev/null --export-format=stl test.scad

clean-docs:
    # docs task will delete any images it didn't write
    mkdir -p docs/images

docs:
    #!/usr/bin/env -S uv run --script
    import re
    import shlex
    import subprocess
    import os
    import asyncio

    openscad_pattern = re.compile(r"^\s*<!--\s*openscad (.+)\s*-->\s*$")
    concurrency = asyncio.Semaphore(8)

    async def run(cmd, output):
        async with concurrency:
            print("Running: " + shlex.join(cmd))
            proc = await asyncio.create_subprocess_exec(*cmd)
            await proc.wait()
            assert proc.returncode == 0
        if os.path.getsize(output) == 7763:
            # render failure, retry
            print(f"Render failure for `{shlex.join(cmd)}`, retrying")
            await run(cmd, output)
    
    async def main():
        tasks = []
        written = []
        for line in open("README.md"):
            match = openscad_pattern.match(line)
            if match:
                cmd = ["openscad", "--projection=ortho", "--colorscheme=Starnight", "--render", "--imgsize=2500,1000", *shlex.split(match.group(1))]
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
                os.unlink(f)
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

printables-zip: clean-printables-zip paths (intersection-fit-tester-one "0.0") (intersection-fit-tester-one "0.2") (intersection-fit-tester-one "0.4") (intersection-fit-tester-one "0.6") (intersection-fit-tester-one "0.8") (intersection-fit-tester-one "1.0")
    mkdir -p "{{dir_magnet_insertion}}"
    openscad -o "{{dir_magnet_insertion}}"/jig.stl --export-format=binstl -D part='"jig"' -D show_cross_section=false mag_insert_jig.scad
    openscad -o "{{dir_magnet_insertion}}"/pusher.stl --export-format=binstl -D part='"pusher"' mag_insert_jig.scad
    mkdir -p "{{dir_source}}"
    cp -r paths gridflock.scad "{{dir_source}}"
    rm -f build/printables.zip
    cd build/printables && zip -r ../printables.zip .
    

all: paths test showcase docs printables-zip
