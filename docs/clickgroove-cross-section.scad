include <../gridflock.scad>
test_pattern = -1;
plate_size = [42, 42];
click = true;
click_style = 1;
use <../clickgroove-base.scad>

module proj() {
    rotate([0, 0, 90]) projection(cut=true) rotate([0, 90, 0]) children();
}

color("#dd5c2b") translate([0.2, 0, 0]) proj() main();
color("#3f5178") proj() draw_clickgroove_base();
