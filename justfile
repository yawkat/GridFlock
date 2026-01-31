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
            cmd = ("openscad", "--projection=ortho", "--colorscheme=Starnight", "--render", "--imgsize=2500,1000", *shlex.split(match.group(1)), "gridflock.scad")
            print("Running: " + shlex.join(cmd))
            subprocess.run(cmd, check=True)
