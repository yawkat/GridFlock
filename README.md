# GridFlock

A gridfinity-compatible baseplate generator for small printer beds. Cuts the base plate into pieces that fit the printer bed and can be linked together using puzzle-style locking connectors.

Similar projects include GridPlates (DMCA'd) and GRIPS, but GridFlock is an independent, open-source, clean-room implementation. My goal is truly open community development. If you are missing a feature that is available in GridPlates or GRIPS, please create a GitHub ticket.

GridFlock uses [Gridfinity Rebuilt](https://github.com/kennetek/gridfinity-rebuilt-openscad) (under MIT license) for the baseplate cutter.

For inserting magnets, check out [the jig I designed](https://www.printables.com/model/1515309-magnet-insertion-jig-for-gridfinity-gridplates) for GridPlates. It is also compatible with GridFlock.

## Building

The source file cannot be immediately opened in OpenScad. There is a dependency on Gridfinity Rebuilt, and some polygons are loaded from SVG files.

1. Install [`just`](https://just.systems/) and [`uv`](https://docs.astral.sh/uv/)
2. Clone the repository
3. Initialize the git submodules
4. Run `just paths` to extract the puzzle connector paths from the SVG
5. Now you can open `gridflock.scad` using OpenScad (development build required)

## Why the name?

Since the segments lock together, I considered "GridLock", but that's not a googleable word. I added the F from "Gridfinity" to make the name unique. You can also consider the set of segments that this project generates a "flock".
