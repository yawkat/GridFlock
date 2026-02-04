include <gridflock.scad>
include <gridfinity-rebuilt-openscad/src/core/standard.scad>
use <gridfinity-rebuilt-openscad/src/core/base.scad>
include <gridfinity-rebuilt-openscad/src/core/gridfinity-rebuilt-holes.scad>

/* [Export Settings] */

// Part to export
part = "jig"; // [jig, pusher]

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

// Disc Radius
disc_radius = 16;
// Disc Height (Thickness)
disc_height = 4;
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
projection_scale = 1;

/* [Pusher Parameters] */

pusher_width = 30;
pusher_thickness = 4.85;
pusher_handle_height = 15;
pusher_stem_height = 1.85;
pusher_stem_width = 11;

/* [Magnet Parameters] */

magnet_clearance = 1.1;
magnet_outer_r = 3.8 * 1.05;
magnet_inner_r = 3.3 * 1.05;
magnet_hole_height = 20;
magnet_cutout_height = 2.25 * magnet_clearance;

/* [Advanced] */

// Overwrite GridFlock's settings
test_pattern = -1;
connector_edge_puzzle = true;
connector_intersection_puzzle = false;
_edge_puzzle_direction_male = [false, false, false, false];
REFINED_HOLE_BOTTOM_LAYERS=3;

/* [Hidden] */

// Calculate hole position from the bottom edge
_hole_offset = (BASE_TOP_DIMENSIONS.x - 2 * _base_profile_max_mm.x) / 2 - HOLE_DISTANCE_FROM_BOTTOM_EDGE;

// Magnet hole options for Refined style
_hole_options_refined = bundle_hole_options(refined_hole=true);

/* [Modules] */

/**
 * @Summary 1x1 Bin Base Tool (JIG - Red)
 * @Details Represents the functional base of a bin that we want to test against or simulate
 */
module jig_bin_tool() {
  difference() {
    color([1.0, 0.2, 0.2, jig_alpha])
      intersection() {
        // Crop to the specified functional height
        translate([-50, -50, 0]) cube([100, 100, jig_crop_height]);

        difference() {
          union() {
            _base_bridge_solid(BASE_TOP_DIMENSIONS);
            base_solid(BASE_TOP_DIMENSIONS);
          }
          for (a = [0, 180]) {
            rotate([0, 0, a]) translate([_hole_offset, _hole_offset, 0]) block_base_hole(_hole_options_refined);
          }
          translate([0, 0, 4.4]) {
            translate([0, 15, 0]) linear_extrude(height=2) text("Magnet Insertion", size=3.5, halign="center", valign="center");
            translate([0, 7.5, 0]) linear_extrude(height=2) text("Jig", size=3.5, halign="center", valign="center");
            translate([0, 0, 0]) linear_extrude(height=2) text("For", size=3.5, halign="center", valign="center");
            translate([0, -7.5, 0]) linear_extrude(height=2) text("Gridfinity", size=5, halign="center", valign="center");
            translate([0, -15, 0]) linear_extrude(height=2) text("GridFlock", size=5, halign="center", valign="center");
          }
          _base_preview_fix();
        }
      }
  }
}

/**
 * @Summary 1x1 GridFlock Baseplate Rig (PLATE - Blue)
 * @Details The baseplate segment we are testing compatibility with
 */
module jig_baseplate_rig() {
  segment(count=[1, 1], padding=[0, 0, 0, 0], connector=[true, true, true, true]);
}

/**
 * @Summary Solid Disc Body with Top Chamfer
 * @Details The blank disc before any functional cutouts are applied
 */
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
        mirror([0, 1, 0]) rotate([0, 0, a]) translate([_hole_offset, _hole_offset, 0])
              linear_extrude(height=100, center=true)
                projection()
                  block_base_hole(_hole_options_refined);
      }
    }
}

/**
 * @Summary Base shape for cutting from the disc
 * @Details Created by projecting the baseplate rig to 2D
 */
module jig_cutout_profile_2d() {
  offset(r=cut_rounding)
    scale([projection_scale, projection_scale, 1])
      projection()
        jig_baseplate_rig();
}

/**
 * @Summary Visual Assembly of Tool vs Rig
 */
module jig_assembly() {
  // 1. Visual Assembly of Tool vs Rig
  rotate([180, 0, 0]) {
    difference() {
      jig_bin_tool();
      jig_baseplate_rig();
    }
  }

  // 2. The Disc Tool
  // Disc atop the assembly with REVERSED compound cutouts to fit the baseplate
  translate([0, 0, 0])
    difference() {
      jig_disc_blank();

      translate([0, 0, -0.01]) union() {
          // A. Straight Section (Started at the bottom meeting face)
          linear_extrude(height=disc_height - cut_taper_height + 0.01)
            jig_cutout_profile_2d();

          // B. Tapered Section (at the TOP)
          translate([0, 0, disc_height - cut_taper_height])
            linear_extrude(height=cut_taper_height + 1, scale=cut_taper_scale)
              jig_cutout_profile_2d();
        }
    }
}

/**
 * @Summary Pusher output cutout shape
 */
module pusher_output_cutout() {
  linear_extrude(height=pusher_stem_height, center=true, scale=[1, 1])
    square([pusher_width, magnet_inner_r * 2], center=true);
}

minkowski_expand = 0.8;

/**
 * @Summary 2D Trapezoid for the main pusher pin, which pushes the magnet in
 */
module pusher_pin(positive) { 
  translate([0, magnet_top + 0.25]) {
    if (positive) polygon([[-pusher_thickness/2, 0], [-pusher_thickness/2*0.8, pusher_stem_height], [pusher_thickness/2*0.8, pusher_stem_height], [pusher_thickness/2, 0]]);
    else translate([0, pusher_stem_height/2]) square([pusher_thickness-minkowski_expand, pusher_stem_height-minkowski_expand], center=true);
  }
}

// width, height, length
aux_pin_dim = [5, 4, 13.5];
aux_pin_off = 4;
back_pin_dim = [5, 3, 14];

/**
 * @Summary 2D shape of auxiliary pins that absorb some bending force
 */
module aux_pins() {
  for (i = [0,1]) {
    mirror([i,0,0]) translate([-aux_pin_off, -_profile_height-0.25]) polygon([[0, 0], [0, aux_pin_dim.y], [-aux_pin_dim.x, 0]]);
  }
}

frame_strength = 5;
/**
 * @Summary Complete pusher assembly
 */
module pusher_combined(positive=true) {
  // main pin
  rotate([90, 0, 90]) {
    linear_extrude(pusher_stem_width - pusher_stem_height) pusher_pin(positive);
    skew = 1.9;
    translate([0, skew, pusher_stem_width - pusher_stem_height]) linear_extrude(pusher_stem_height, scale=[0.8, 0.7]) translate([0, -skew]) pusher_pin(positive);
  }
  // aux pins
  rotate([90, 0, 90]) linear_extrude(aux_pin_dim.z) aux_pins();
  // back pin
  translate([-frame_strength, -back_pin_dim.x/2, -_profile_height-0.25]) {
    rotate([0, 0, 90]) linear_extrude(back_pin_dim.y) {
      square([back_pin_dim.x, back_pin_dim.z - back_pin_dim.x/2]);
      translate([back_pin_dim.x/2, back_pin_dim.z - back_pin_dim.x/2]) circle(d=back_pin_dim.x);
    } 
  }
  // frame
  rotate([90, 0, 90]) translate([0, 0, -frame_strength]) linear_extrude(frame_strength) {
    handle_thickness = pusher_thickness + 2;
    translate([-handle_thickness / 2, magnet_top]) square([handle_thickness, pusher_handle_height]);
    hull() {
      pusher_pin();
      aux_pins();
    }
  }
}

/**
 * @Summary Pusher main cutout shape
                 */
module pusher_cutout() {
  minkowski() {
    union() pusher_combined(positive=false);
    // this minkowski creates a 1mm gap in all directions
    rotate([0, -90, 0]) linear_extrude(pusher_stem_width) square([minkowski_expand, minkowski_expand], center=true);
  }
}

/**
 * @Summary Magnet hole geometry
 */
module magnet_hole() {
  difference() {
    union() {
      cylinder(h=magnet_hole_height, r=magnet_outer_r, center=true);
      translate([magnet_outer_r / 2, 0, -2]) cube([magnet_outer_r, 14, 16], center=true);
    }
    cylinder(h=magnet_hole_height, r=magnet_inner_r, center=true);
  }
}

/**
 * @Summary Magnet hole cutout geometry
 */
module magnet_hole_cutout() {
  translate([0, -2, -5]) cube([1, 10, magnet_hole_height - 10], center=true);
  cylinder(h=magnet_hole_height, r=magnet_inner_r, center=true);
  translate([5, 0, -magnet_hole_height / 2 + magnet_cutout_height / 2])
    cube([10, magnet_inner_r * 2, magnet_cutout_height], center=true);
}

/**
 * @Summary Complete Jig with Pusher cutouts and Magnets
 */
module jig_with_pusher() {
  // Magnet position relative to center
  mag_pos_x = 8.2;
  mag_pos_z = (6 - 0.4) + (magnet_hole_height - 10) / 2;
  mag_pos_z_hole = 7.5 + (magnet_hole_height - 10) / 2;

  // Cutout positions
  out_pos_x = 22.5;
  out_handle_pos_z = 2 * pusher_stem_height;

  // New offsets
  mag_screw_offset_z = magnet_hole_height / 2;
  pusher_extra_cutout_offset = -magnet_cutout_height;

  union() {
    difference() {
      jig_assembly();

      // 1. Pusher Body Cutout
      // place snug against the magnet cylinder
      rotate([0, 0, 45]) translate([5.5-8.2+mag_pos_x, 0]) pusher_cutout();

      // 2. Output & Handle Cutouts (rotated frame)
      rotate([0, 0, 45]) {
        translate([out_pos_x, 0, pusher_stem_height]) scale(1) pusher_output_cutout();
        translate([-5, 0, out_handle_pos_z]) cube([20, 4.25, pusher_stem_height], center=true);
        translate([mag_pos_x, 0, mag_pos_z]) magnet_hole_cutout();
        translate([mag_pos_x, 0, mag_pos_z - mag_screw_offset_z]) rotate([180, 0, 0]) block_base_hole(_hole_options_refined);
      }
    }

    // Add Pusher (Ghost/Visual)
    %rotate([0, 0, 45]) translate([-2.6+mag_pos_x-pusher_stem_width, 0, 0]) pusher_combined();

    // Add Magnet Holes
    difference() {
      rotate([0, 0, 45]) translate([mag_pos_x, 0, mag_pos_z_hole]) magnet_hole();
      rotate([0, 0, 45]) translate([mag_pos_x, 0, mag_pos_z]) magnet_hole_cutout();
    }
  }
}

/**
 * @Summary Cut a cross section for visualization
 */
module cut_cross_section() {
  difference() {
    children();
    // Cut away half to see inside, rotated 135 degrees
    rotate([0, 0, 135]) translate([0, -60, -50]) cube([60, 120, 150]);
  }
}

if (part == "jig") {
  if (show_cross_section) {
    cut_cross_section() {
      jig_with_pusher();
    }
  } else {
    jig_with_pusher();
  }
} else if (part == "pusher") {
  pusher_combined();
} else {
  echo("Unknown part selected: ", part);
}
