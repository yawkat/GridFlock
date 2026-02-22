include <gridfinity-rebuilt-openscad/src/core/standard.scad>
use <gridfinity-rebuilt-openscad/src/core/bin.scad>
use <gridfinity-rebuilt-openscad/src/core/gridfinity-rebuilt-utility.scad>

$fn=50;

bin1 = new_bin(
    grid_size = [1, 1],
    height_mm = height(3, 0),
);

module click_groove() {
  height = 1.5;
  depth = height/2;
  gap = 0.1;
  translate([0, 2.15+0.25/2, 2.6]) rotate([0, 90, 0]) linear_extrude(30, center=true) polygon([[(1.8-height)/2-gap, -gap], [0.9, depth], [1.8-(1.8-height)/2+gap, -gap]]);
}

module draw_clickgroove_base() {
    difference() {
        bin_render(bin1);

        translate([0, -GRID_DIMENSIONS_MM.y/2]) click_groove();
        translate([0, GRID_DIMENSIONS_MM.y/2]) rotate([0, 0, 180]) click_groove();
        translate([-GRID_DIMENSIONS_MM.x/2, 0]) rotate([0, 0, -90]) click_groove();
        translate([GRID_DIMENSIONS_MM.x/2, 0]) rotate([0, 0, 90]) click_groove();
    }
}

draw_clickgroove_base();