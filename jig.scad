// Include GridFlock first to get its variables and modules
include <gridflock.scad>

/* [Jig Settings] */
// Smoothness
$fn = 64;
// Visualize Cross Section
show_cross_section = true;
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

// --- Derived Constants ---

// Magnet hole options for Refined style
hole_options_refined = bundle_hole_options(refined_hole=true);

// Calculate hole position from the bottom edge
// Depends on variables from gridfinity-rebuilt-openscad
hole_offset = (BASE_TOP_DIMENSIONS.x - 2 * _base_profile_max_mm.x) / 2 - HOLE_DISTANCE_FROM_BOTTOM_EDGE;

// --- MODULES ---

// 1x1 Bin Base Tool (JIG - Red)
// Represents the functional base of a bin that we want to test against or simulate
module jig_bin_tool() {
  color([1.0, 0.2, 0.2, jig_alpha]) // RED
    intersection() {
      // Crop to the specified functional height
      translate([-50, -50, 0]) cube([100, 100, jig_crop_height]);

      difference() {
        union() {
          _base_bridge_solid(BASE_TOP_DIMENSIONS);
          base_solid(BASE_TOP_DIMENSIONS);
        }
        for (a = [0, 180]) {
          rotate([0, 0, a]) translate([hole_offset, hole_offset, 0]) block_base_hole(hole_options_refined);
        }
        _base_preview_fix();
      }
    }
}

// 1x1 GridFlock Baseplate Rig (PLATE - Blue)
// The baseplate segment we are testing compatibility with
module jig_baseplate_rig() {
  segment(count=[1, 1], padding=[0, 0, 0, 0], connector=[true, true, true, true]);
}

// Solid Disc Body with Top Chamfer
// The blank disc before any functional cutouts are applied
module jig_disc_blank() {
  color([0.5, 0.5, 0.5, jig_alpha])
    difference() {
      union() {
        cylinder(h=disc_height - disc_chamfer, r=disc_radius);
        translate([0, 0, disc_height - disc_chamfer])
          cylinder(h=disc_chamfer, r1=disc_radius, r2=disc_radius - disc_chamfer);
      }
      // Add magnet/screw holes to the disc itself
      for (a = [0, 180]) {
        mirror([0, 1, 0]) rotate([0, 0, a]) translate([hole_offset, hole_offset, 0])
              linear_extrude(height=100, center=true)
                projection()
                  block_base_hole(hole_options_refined);
      }
    }
}

// Base shape for cutting from the disc
// Created by protecting the baseplate rig to 2D
module jig_cutout_profile_2d() {
  offset(r=cut_rounding)
    scale([projection_scale, projection_scale, 1])
      projection()
        jig_baseplate_rig();
}

// --- FINAL ASSEMBLY ---

module jig_assembly() {
  // 1. Visual Assembly of Tool vs Rig
  // Rotated 180 to show "upside down" usage typical for baseplates?
  // Or just to orient it nicely for viewing.
  rotate([180, 0, 0]) {
    difference() {
      jig_bin_tool();
      jig_baseplate_rig();
    }
    %jig_baseplate_rig(); // Ghost of the rig
  }

  // 2. The Disc Tool
  // Disc atop the assembly with REVERSED compound cutouts to fit the baseplate
  // Meeting face (bottom of disc) is Z=0 to Z=2: Straight cut
  // Top face is Z=2 to Z=3: Tapered cut
  translate([0, 0, 0])
    difference() {
      jig_disc_blank();

      translate([0, 0, -0.01]) union() {
          // A. Straight Section (Started at the bottom meeting face)
          linear_extrude(height=disc_height - cut_taper_height + 0.01)
            jig_cutout_profile_2d();

          // B. Tapered Section (at the TOP)
          // Starts at disc_height - cut_taper_height
          translate([0, 0, disc_height - cut_taper_height])
            linear_extrude(height=cut_taper_height + 1, scale=cut_taper_scale)
              jig_cutout_profile_2d();
        }
    }
}

// --- Main Execution ---

if (show_cross_section) {
  difference() {
    jig_assembly();
    // Cut away half to see inside, rotated 45 degrees
    rotate([0, 0, 135]) translate([0, -60, -50]) cube([60, 120, 150]);
  }
} else {
  jig_assembly();
}

echo(str("TOTAL BAR INTRUSION DEPTH: ", edge_puzzle_dim.y + edge_puzzle_dim_c.y + edge_puzzle_magnet_border_width, "mm"));
