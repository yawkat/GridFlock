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
// Disc Height (Thickness) is 3mm
disc_height = 3;
// Disc Chamfer size (mm) for the outer cylinder
disc_chamfer = 1.0;

/* [Cutout Refinement] */
// Rounding radius for the 2D cutouts (the corners)
cut_rounding = 1.0;
// Height of the tapered section at the TOP of the cut
cut_taper_height = 1.0;
// Scaling of the cut-out shape at the top exit (Set < 1.0 for "inward", > 1.0 for "funnel")
cut_taper_scale = 0.9;
// Scale of the straight functional section of the baseplate projection 
projection_scale = 0.95;

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
        }
        _base_preview_fix();
      }
    }
}

// 1x1 GridFlock Baseplate Rig (PLATE - Blue)
module gridflock_baseplate_rig() {
  segment(count=[1, 1], padding=[0, 0, 0, 0], connector=[true, true, true, true]);
}

// Solid Disc Body with Top Chamfer
module disc_body() {
  color([0.5, 0.5, 0.5, jig_alpha])
    union() {
      cylinder(h=disc_height - disc_chamfer, r=disc_radius);
      translate([0, 0, disc_height - disc_chamfer])
        cylinder(h=disc_chamfer, r1=disc_radius, r2=disc_radius - disc_chamfer);
    }
}

// Base shape for cutting from the disc
module base_cut_shape() {
  offset(r=cut_rounding)
    scale([projection_scale, projection_scale, 1])
      projection()
        gridflock_baseplate_rig();
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

  // Disc atop the assembly with REVERSED compound cutouts
  // Meeting face (bottom of disc) is Z=0 to Z=2: Straight
  // Top face is Z=2 to Z=3: Tapered
  translate([0, 0, 0])
    difference() {
      disc_body();

      translate([0, 0, -0.01]) union() {
          // 1. Straight Section (Started at the bottom meeting face)
          linear_extrude(height=disc_height - cut_taper_height + 0.01)
            base_cut_shape();

          // 2. Tapered Section (at the TOP)
          // Starts at disc_height - cut_taper_height
          translate([0, 0, disc_height - cut_taper_height])
            linear_extrude(height=cut_taper_height + 1, scale=cut_taper_scale)
              base_cut_shape();
        }
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
