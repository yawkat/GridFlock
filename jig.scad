include <gridfinity-rebuilt-openscad/src/core/standard.scad>
use <gridfinity-rebuilt-openscad/src/core/base.scad>
use <gridfinity-rebuilt-openscad/src/core/gridfinity-rebuilt-holes.scad>

/* [Jig Parameters] */
// Smoothness
$fn = 64;

// Magnet hole options
hole_options = bundle_hole_options(
  refined_hole=true
);

module base_with_two_holes() {
  // Calculate hole position based on standard Gridfinity geometry
  // (Base bottom size / 2) - distance from edge
  hole_pos = (BASE_TOP_DIMENSIONS.x - 2 * _base_profile_max_mm.x) / 2 - HOLE_DISTANCE_FROM_BOTTOM_EDGE;

  difference() {
    union() {
      _base_bridge_solid(BASE_TOP_DIMENSIONS);
      base_solid(BASE_TOP_DIMENSIONS);
    }

    // Top-Right corner hole
    translate([hole_pos, hole_pos, 0])
      rotate([0, 0, 0])
        block_base_hole(hole_options);

    // Bottom-Left corner hole
    translate([-hole_pos, -hole_pos, 0])
      rotate([0, 0, 180])
        block_base_hole(hole_options);

    _base_preview_fix();
  }
}

// Flip the model 180 degrees to serve as an insertion jig base
rotate([180, 0, 0]) {
  base_with_two_holes();
}
