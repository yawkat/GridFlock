include <gridfinity-rebuilt-openscad/src/core/standard.scad>
use <gridfinity-rebuilt-openscad/src/core/base.scad>
use <gridfinity-rebuilt-openscad/src/core/gridfinity-rebuilt-holes.scad>

/* [Jig Parameters] */
// Number of bases along x-axis
gridx = 1;
// Number of bases along y-axis
gridy = 1;

// Magnet hole options
hole_options = bundle_hole_options(
  magnet_hole=true,
  crush_ribs=true,
  chamfer=true
);

// Flip the model 180 degrees to serve as an insertion jig base
rotate([180, 0, 0]) {
  gridfinityBase(
    grid_size=[gridx, gridy],
    hole_options=hole_options
  );
}
