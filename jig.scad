// Include GridFlock first to get its variables and modules
include <gridflock.scad>

/* [Jig Settings] */
// Smoothness
$fn = 64;
// Visualize Cross Section
show_cross_section = false;
// Transparency Level
jig_alpha = 1.0;
// Height of the functional part of the bin to keep
jig_crop_height = 4.75;

/* [Disc Parameters] */
// Disc Radius is 16mm
disc_radius = 16;
// Disc Height is 3mm
disc_height = 3;
// Scale of the baseplate projection used to cut the disc (1.0 = exact fit)
projection_scale = 0.95; // [0.8:0.01:1.5]

/* [Intrusion Simulation] */
edge_puzzle_magnet_border_width = 2.5;
edge_puzzle_magnet_border = true;
edge_puzzle_dim = [10, 2.5];
edge_puzzle_dim_c = [3, 1.2];

// --- Overwrite GridFlock's settings ---
test_pattern = -1;
connector_edge_puzzle = true;
connector_intersection_puzzle = false;
_edge_puzzle_direction_male = [false, false, false, false];
// ---------------------------------------

// Re-use standard Gridfinity modules
include <gridfinity-rebuilt-openscad/src/core/standard.scad>
use <gridfinity-rebuilt-openscad/src/core/base.scad>
use <gridfinity-rebuilt-openscad/src/core/gridfinity-rebuilt-holes.scad>

// Magnet hole options for Refined style
hole_options_refined = bundle_hole_options(refined_hole=true);

// --- MODULES ---

// 1x1 Bin Base Tool (JIG - Red)
module bin_base_tool_2() {
  hole_pos = (BASE_TOP_DIMENSIONS.x - 2 * _base_profile_max_mm.x) / 2 - HOLE_DISTANCE_FROM_BOTTOM_EDGE;

  color([1.0, 0.2, 0.2, jig_alpha]) // RED
    intersection() {
      translate([-50, -50, 0]) cube([100, 100, jig_crop_height]);

      difference() {
        union() {
          _base_bridge_solid(BASE_TOP_DIMENSIONS);
          base_solid(BASE_TOP_DIMENSIONS);
        }
        for (a = [0, 180]) {
          rotate([0, 0, a]) translate([hole_pos, hole_pos, 0]) block_base_hole(hole_options_refined);
          rotate([0, 0, a]) translate([hole_pos, hole_pos, -10]) cylinder(h=25, d=3);
        }
        _base_preview_fix();
      }
    }
}

// 1x1 GridFlock Baseplate Rig (PLATE - Blue)
module gridflock_baseplate_rig() {
  segment(count=[1, 1], padding=[0, 0, 0, 0], connector=[true, true, true, true]);
}

// Solid Disc Body
module disc_body() {
  color([0.5, 0.5, 0.5, jig_alpha])
    cylinder(h=disc_height, r=disc_radius);
}

// --- FINAL ASSEMBLY ---

module assembly() {
  rotate([180, 0, 0]) {
    difference() {
      bin_base_tool_2();
      gridflock_baseplate_rig();
    }
    %gridflock_baseplate_rig();
  }

  // Disc atop the assembly with SCALED projection subtraction
  translate([0, 0, 0])
    difference() {
      disc_body();
      // We scale the projection from [0,0,0] origin
      translate([0, 0, -1])
        linear_extrude(height=disc_height + 2)
          scale([projection_scale, projection_scale, 1])
            projection()
              gridflock_baseplate_rig();
    }
}

// Main execution
if (show_cross_section) {
  difference() {
    assembly();
    translate([0, -60, -50]) cube([60, 120, 150]);
  }
} else {
  assembly();
}

echo(str("TOTAL BAR INTRUSION DEPTH: ", edge_puzzle_dim.y + edge_puzzle_dim_c.y + edge_puzzle_magnet_border_width, "mm"));
echo(str("PROJECTION SCALE: ", projection_scale));
