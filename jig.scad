// Include GridFlock first to get its variables and modules
include <gridflock.scad>

/* [Jig Settings] */
// Smoothness
$fn = 64;
// Transparency Toggle
show_transparent = true;

/* [Intrusion Simulation] */
// The thickness of the stability bar behind female sockets (mm)
edge_puzzle_magnet_border_width = 2.5;
// Enable the stability bar itself
edge_puzzle_magnet_border = true;

// Puzzle Connector Dimensions (Redefining these for the rig)
edge_puzzle_dim = [10, 2.5];
edge_puzzle_dim_c = [3, 1.2];

// --- Overwrite GridFlock's settings ---
test_pattern = -1;
connector_edge_puzzle = true;
connector_intersection_puzzle = false;

// Force all 4 sides to be "Female" so they all get the stability bars/intrusion
_edge_puzzle_direction_male = [false, false, false, false];
// ---------------------------------------

// Re-use standard Gridfinity modules
include <gridfinity-rebuilt-openscad/src/core/standard.scad>
use <gridfinity-rebuilt-openscad/src/core/base.scad>
use <gridfinity-rebuilt-openscad/src/core/gridfinity-rebuilt-holes.scad>

// Magnet hole options for Refined style
hole_options_refined = bundle_hole_options(refined_hole=true);

// --- MODULES ---

// 1x1 Bin Base Tool (Hidden)
module bin_base_tool_4() {
  hole_pos = (BASE_TOP_DIMENSIONS.x - 2 * _base_profile_max_mm.x) / 2 - HOLE_DISTANCE_FROM_BOTTOM_EDGE;
  difference() {
    union() {
      _base_bridge_solid(BASE_TOP_DIMENSIONS);
      base_solid(BASE_TOP_DIMENSIONS);
    }
    for (a = [0:90:270]) {
      rotate([0, 0, a]) translate([hole_pos, hole_pos, 0]) block_base_hole(hole_options_refined);
      rotate([0, 0, a]) translate([hole_pos, hole_pos, -10]) cylinder(h=25, d=3);
    }
    _base_preview_fix();
  }
}

// 1x1 GridFlock Baseplate Rig
module gridflock_baseplate_rig() {
  segment(count=[1, 1], padding=[0, 0, 0, 0], connector=[true, true, true, true]);
}

// --- FINAL ASSEMBLY ---

module assembly() {
  // Helper (GridFlock Baseplate Rig) flipped upside down
  rotate([180, 0, 0]) {
    gridflock_baseplate_rig();
  }

  /* 
    // Uncomment to re-integrate Bin Base Tool
    translate([0, 0, 0]) rotate([180, 0, 0]) bin_base_tool_4();
    */
}

if (show_transparent) {
  color([0.2, 0.5, 1.0, 0.8]) assembly();
} else {
  assembly();
}

// ECHO calculation for simulation feedback
echo(str("TOTAL BAR INTRUSION DEPTH: ", edge_puzzle_dim.y + edge_puzzle_dim_c.y + edge_puzzle_magnet_border_width, "mm"));
