paths:
    mkdir -p paths
    uv run extract_paths.py puzzle.svg paths/puzzle.scad

test:
    openscad -o /dev/null --export-format=stl test.scad

clean-docs:
    rm -rf docs/images
    mkdir -p docs/images

docs: clean-docs
    #!/usr/bin/env -S uv run --script
    import re
    import shlex
    import subprocess
    openscad_pattern = re.compile(r"^\s*<!--\s*openscad (.+)\s*-->\s*$")
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
            print("Running: " + shlex.join(cmd))
            subprocess.run(cmd, check=True)

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

intersection-fit-tester-one fit:
    mkdir -p build/intersection-fit-tester
    openscad -o build/intersection-fit-tester/fit-{{fit}}.stl --export-format=binstl -D magnets=false -D BASEPLATE_DIMENSIONS='[15, 42]' -D 'plate_size=[30, 84]' -D 'bed_size=[25, 1000]' -D intersection_puzzle_fit={{fit}} gridflock.scad

intersection-fit-tester: (intersection-fit-tester-one "0.0") (intersection-fit-tester-one "0.2") (intersection-fit-tester-one "0.4") (intersection-fit-tester-one "0.6") (intersection-fit-tester-one "0.8") (intersection-fit-tester-one "1.0")


mag-insert-jig:
    mkdir -p build
    openscad -o build/mag_insert_jig.stl --export-format=binstl -D part=\"jig\" -D show_cross_section=false mag_insert_jig.scad

mag-insert-pusher:
    mkdir -p build
    openscad -o build/mag_insert_pusher.stl --export-format=binstl -D part=\"pusher\" mag_insert_jig.scad

mag-insert: mag-insert-jig mag-insert-pusher

all: paths test showcase docs mag-insert
