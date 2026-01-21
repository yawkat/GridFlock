# GridFlock

A gridfinity-compatible baseplate generator for small printer beds. Cuts the base plate into pieces that fit the printer bed and can be linked together using puzzle-style locking connectors.

Similar projects include GridPlates (DMCA'd) and GRIPS, but GridFlock is an independent, open-source, clean-room implementation. My goal is truly open community development. If you are missing a feature that is available in GridPlates or GRIPS, please create a GitHub ticket.

GridFlock uses [Gridfinity Rebuilt](https://github.com/kennetek/gridfinity-rebuilt-openscad) (under MIT license) for the baseplate cutter.

For inserting magnets, check out [the jig I designed](https://www.printables.com/model/1515309-magnet-insertion-jig-for-gridfinity-gridplates) for GridPlates. It is also compatible with GridFlock.

<img width="2822" height="1069" alt="gridflock-whole" src="https://github.com/user-attachments/assets/0dd6979f-72bd-4a13-b4b9-4bd262ede99d" />

<img width="2822" height="1069" alt="gridflock-closeup" src="https://github.com/user-attachments/assets/af6afa62-9183-45a5-9fda-9f630059736a" />

## Connectors

GridFlock offers two connector options.

### Intersection Puzzle

This mode adds small puzzle-style connectors at cell intersections. This is similar to GridPlates and GRIPS, and relatively easy to print. However, in my experience, these connectors can sometimes lead to gaps between the segments. The shape of these connectors is fixed in [puzzle.svg](https://github.com/yawkat/GridFlock/blob/main/puzzle.svg) and cannot be customized without editing the SVG.

<img width="2822" height="1069" alt="gridflock-intersection" src="https://github.com/user-attachments/assets/046a5f50-2821-48fa-ac45-73d604df7993" />

### Edge Puzzle

The edge puzzle mode uses larger connectors placed at the edges of cells, instead of intersections. This leads to a more accurate fit, but is a bit harder to print, and uses more filament.

* At a segment corner where female connectors are placed on both adjecent sides, the corner could be "cut off" from the rest of the segment. To avoid this, the connector does not use the full height. When *not* using magnets, this can make the connector quite flimsy.
* To avoid interference with the bucket in the neighbouring cell, the male connector has a cutout identical to the bin in that cell. Again, if there is not enough vertical height (no magnets), this can make the male connector flimsy.
* To make the female connectors more sturdy and easier to print, an extra "bar" is added at the magnet level, on those edges where a female connector is placed (only if magnets are enabled). You can see it in the screenshot. With this bar, it may be viable to make the connector full-height and avoid the overhang.
* Unlike the intersection mode, the edge puzzle connectors are highly customizable for your circumstances.

<img width="2822" height="1069" alt="gridflock-edges" src="https://github.com/user-attachments/assets/586d8851-13f0-4330-a18b-4bf64c624223" />

In summary, this connector is a good alternative to the intersection puzzle if the plate has enough vertical height. Try both and see what works best for you. You can also technically enable both at the same time, though I don't know why you would.

## Building

The source file cannot be immediately opened in OpenScad. There is a dependency on Gridfinity Rebuilt, and some polygons are loaded from SVG files.

1. Install [`just`](https://just.systems/) and [`uv`](https://docs.astral.sh/uv/)
2. Clone the repository
3. Initialize the git submodules
4. Run `just paths` to extract the puzzle connector paths from the SVG
5. Now you can open `gridflock.scad` using OpenScad (development build required)

## Why the name?

Since the segments lock together, I considered "GridLock", but that's not a googleable word. I added the F from "Gridfinity" to make the name unique. You can also consider the set of segments that this project generates a "flock".
