paths:
    mkdir -p paths
    uv run extract_paths.py puzzle.svg paths/puzzle.scad

test:
    openscad -o /dev/null --export-format=stl test.scad