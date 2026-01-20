include <gridfinity-rebuilt-openscad/src/core/gridfinity-baseplate.scad>
use <gridfinity-rebuilt-openscad/src/helpers/list.scad>
include <paths/puzzle.scad>

// The bed size of the printer, e.g. 250x220 for the Prusa Core One
bed_size = [250, 220];
// The size of the grid plate to generate
plate_size = [780, 265];
// If there's not enough space for a full grid cell, squeeze in a half cell (x direction)
do_half_x = true;
// If there's not enough space for a full grid cell, squeeze in a half cell (y direction)
do_half_y = true;
// Corner radius of the generated plate. The default of 4mm matches the corner radius of the gridfinity cell
plate_corner_radius = 4;

// Whether to enable friction-fit magnets for each grid cell
magnets = true;
// Diameter of the magnet slot
magnet_diameter = 5.9;
// Height of the magnet slot
magnet_height = 2.25;

// Connector type for connecting the generated segments
connector_type = 1; // [0:None, 1:Intersection puzzle similar to Gridfinity/GRIPS]

// Edge adjustment values (clockwise: north, east, south, west). These values are *added* to the plate size as padding, i.e. the final plate will end up different than configured in plate_size. This allows you to customize the padding to be asymmetrical. You can also use negative values to "cut" the plate edges if you want to squeeze an extra square out of limited space.
edge_adjust = [0, 0, 0, 0];

/* [Hidden] */

// openscad does not support boolean vectors in the customizer
do_half = [do_half_x, do_half_y];

$fn=40;

_magnet_top = 0.5;
_magnet_bottom = 0.75;
_magnet_extraction_dim = [magnet_diameter/2, magnet_diameter/2+2];

// actual height of a gridfinity profile with no extra clearance.
// gridfinity rebuilt adds extra clearance at the bottom, we cut that out.
_profile_height = 4.65;
_magnet_height = _magnet_top + _magnet_bottom + magnet_height;
_extra_height = magnets ? _magnet_height : 0;

_total_height = _profile_height + _extra_height;

// gap between segments in output
_segment_gap = 10;

_NORTH = 0;
_EAST = 1;
_SOUTH = 2;
_WEST = 3;

// distance of each magnet from the side of the base plate grid cell
_magnet_location = 0.25 + 2.15 + 0.8 + 4.8;
_magnet_border = 2;

_CONNECTOR_NONE = 0;
_CONNECTOR_INTERSECTION_PUZZLE = 1;

/**
 * @Summary Run some code in each corner, with proper rotation, to add magnets
 * @Details From the children's perspective, we are centered at the corner, and 
 *          the center of the cell is in the north-east (+x and +y)
 * @param half Whether this is a half cell, for each direction
 */
module each_cell_corner(half=[false, false]) {
    if (half.x && half.y) {
        translate([-BASEPLATE_DIMENSIONS.x/4, BASEPLATE_DIMENSIONS.y/4]) rotate([0, 0, 270]) children();
    } else if (half.x) {
        // these corners are chosen so that a half-size bin will fit both a vertical and a horizontal half-width slot
        translate([BASEPLATE_DIMENSIONS.x/4, -BASEPLATE_DIMENSIONS.y/2]) rotate([0, 0, 90]) children();
        translate([-BASEPLATE_DIMENSIONS.x/4, BASEPLATE_DIMENSIONS.y/2]) rotate([0, 0, 270]) children();
    } else if (half.y) {
        translate([-BASEPLATE_DIMENSIONS.x/2, -BASEPLATE_DIMENSIONS.y/4]) children();
        translate([BASEPLATE_DIMENSIONS.x/2, BASEPLATE_DIMENSIONS.y/4]) rotate([0, 0, 180]) children();
    } else {
        translate([-BASEPLATE_DIMENSIONS.x/2, -BASEPLATE_DIMENSIONS.y/2]) children();
        translate([BASEPLATE_DIMENSIONS.x/2, -BASEPLATE_DIMENSIONS.y/2]) rotate([0, 0, 90]) children();
        translate([-BASEPLATE_DIMENSIONS.x/2, BASEPLATE_DIMENSIONS.y/2]) rotate([0, 0, 270]) children();
        translate([BASEPLATE_DIMENSIONS.x/2, BASEPLATE_DIMENSIONS.y/2]) rotate([0, 0, 180]) children();
    }
}

/**
 * @Summary Draw a grid cell centered on 0,0
 * @param half Whether this is a half cell, for each direction
 */
module cell(half=[false, false]) {
    difference() {
        union() {
            difference() {
                translate(-[BASEPLATE_DIMENSIONS.x/(half.x?4:2), BASEPLATE_DIMENSIONS.y/(half.y?4:2), _extra_height]) cube([BASEPLATE_DIMENSIONS.x/(half.x?2:1), BASEPLATE_DIMENSIONS.y/(half.y?2:1), _total_height]);
                translate([0, 0, _profile_height - BASEPLATE_HEIGHT - _extra_height + 0.001]) baseplate_cutter([BASEPLATE_DIMENSIONS.x/(half.x?2:1), BASEPLATE_DIMENSIONS.y/(half.y?2:1)], BASEPLATE_HEIGHT + _extra_height);
            }
            if (magnets) {
                translate([0, 0, -_magnet_height]) each_cell_corner(half) {
                    linear_extrude(height = _magnet_height) {
                        total_bounds = _magnet_location + magnet_diameter/2 + _magnet_border;
                        square([_magnet_location, total_bounds]);
                        square([total_bounds, _magnet_location]);
                        translate([_magnet_location, _magnet_location]) circle(r=magnet_diameter/2+_magnet_border);
                    }
                }
            }
        }
        if (magnets) {
            translate([0, 0, -_magnet_height]) each_cell_corner(half) {
                translate([_magnet_location, _magnet_location]) {
                    rot_slot = half.x == half.y ? -45 : -90;
                    translate([0, 0, _magnet_bottom]) linear_extrude(magnet_height) {
                        circle(magnet_diameter/2);
                        rotate([0, 0, rot_slot]) translate([-magnet_diameter/2, 0]) square([magnet_diameter, magnet_diameter/2 + _magnet_border]);
                    }
                    rotate([0, 0, rot_slot]) linear_extrude(magnet_height + _magnet_bottom) {
                        translate([-_magnet_extraction_dim.x/2, -_magnet_extraction_dim.y]) square(_magnet_extraction_dim);
                        translate([0, -_magnet_extraction_dim.y]) circle(_magnet_extraction_dim.x/2);
                        circle(_magnet_extraction_dim.x/2);
                    }
                }
            }
        }
    }
}

/**
 * Raw polygon for the male puzzle connector. (Note: Only one half)
 */
module puzzle_male_0() {
    scale(1/128*4) translate([-128, -128]) polygon(svg_path_puzzle_svg_male);
}

/**
 * Cleaned polygon for the male puzzle connector. In particular, we need 
 * to cut the parts of the polygon that overlap with the bin.
 */
module puzzle_male(positive) {
    difference() {
        if (positive) {
            puzzle_male_0();
        } else {
            hull() puzzle_male_0();
        }
        translate([-4, -4]) circle(4);
    }
}

/**
 * Raw polygon for the female connector. (Note: Only one half)
 */
module puzzle_female_0() {
    mirror([1, 0]) scale(1/128*4) translate([-128, -128]) polygon(svg_path_puzzle_svg_female);
}

/**
 * Cleaned polygon for the female puzzle connector. The female polygon 
 * is a negative, so we need to do some inversion here.
 */
module puzzle_female(positive) {
    if (positive) {
        difference() {
            hull() puzzle_female_0();
            puzzle_female_0();
        }
    } else {
        puzzle_female_0();
    }
}

/**
 * @Summary Get the index of the last cell in a segment
 * @param count The number of cells on each axis
 */
function last_cell(count) = 
    assert(count.x % 0.5 == 0)
    assert(count.y % 0.5 == 0)
    [floor(count.x - 0.25), floor(count.y - 0.25)];

/**
 * @Summary In the segment coordinate system, translate to the center of a particular cell
 * @param size The size of the segment
 * @param count The number of cells on each axis
 * @param padding The padding of the segment (for each edge)
 * @param index The index of the cell
 */
module navigate_cell(size, count, padding, index) {
    halfx = index.x == count.x - 0.5;
    halfy = index.y == count.y - 0.5;
    translate([-size.x/2 + padding[_WEST] + (index.x + (halfx ? 0.25 : 0.5)) * BASEPLATE_DIMENSIONS.x, -size.y/2 + padding[_SOUTH] + (index.y + (halfy ? 0.25 : 0.5)) * BASEPLATE_DIMENSIONS.y]) children();
}

/**
 * @Summary In the segment coordinate system, translate to a corner of a particular cell
 * @param size The size of the segment
 * @param count The number of cells on each axis
 * @param padding The padding of the segment (for each edge)
 * @param index The index of the cell
 * @param diry The y direction of the corner (north or south)
 * @param dirx The x direction of the corner (east or west)
 */
module navigate_corner(size, count, padding, index, diry, dirx) {
    assert(diry == _NORTH || diry == _SOUTH);
    assert(dirx == _EAST || dirx == _WEST);
    half = [index.x == count.x - 0.5, index.y == count.y - 0.5];
    navigate_cell(size, count, padding, index) translate([
        dirx == _WEST ? -BASEPLATE_DIMENSIONS.x/(half.x?4:2) : BASEPLATE_DIMENSIONS.x/(half.x?4:2), 
        diry == _SOUTH ? -BASEPLATE_DIMENSIONS.y/(half.y?4:2) : BASEPLATE_DIMENSIONS.y/(half.y?4:2)
    ]) children();
}

/**
 * @Summary Draw the segment connectors (2D)
 * @Details Draw all the segment connectors in 2D, once for the whole segment. 
 *          This is done in two passes (negative and positive): The negative
 *          pass cuts out room from the plate, and the positive pass adds the 
            tabs.
 * @param positive true if this is the positive pass
 * @param count The number of cells on each axis
 * @param size The size of the segment (incl. padding)
 * @param padding The padding of the segment (for each edge)
 * @param connector The connector configuration (for each edge)
 */
module segment_connectors(positive, count, size, padding, connector) {
    if (connector_type == _CONNECTOR_INTERSECTION_PUZZLE) {
        // for the normal case, we iterate over the cells at the edge of the segment, and add two half-connectors for each cell.
        last = last_cell(count);
        for (ix = [0:1:last.x]) {
            // north and south connectors
            skip_first = ix == 0 && connector[_WEST];
            skip_last = ix == last.x && connector[_EAST];
            if (connector[_SOUTH]) {
                if (!skip_first) navigate_corner(size, count, padding, [ix, 0], _SOUTH, _WEST) mirror([1, 0]) rotate([0, 0, -90]) puzzle_female(positive);
                if (!skip_last) navigate_corner(size, count, padding, [ix, 0], _SOUTH, _EAST) rotate([0, 0, -90]) puzzle_female(positive);
            }
            if (connector[_NORTH]) {
                if (!skip_first) navigate_corner(size, count, padding, [ix, last.y], _NORTH, _WEST) rotate([0, 0, 90]) puzzle_male(positive);
                if (!skip_last) navigate_corner(size, count, padding, [ix, last.y], _NORTH, _EAST) mirror([1, 0]) rotate([0, 0, 90]) puzzle_male(positive);
            }
        }
        for (iy = [0:1:last.y]) {
            // east and west connectors
            halfy = iy == count.y - 0.5;
            if (connector[_WEST]) {
                navigate_corner(size, count, padding, [0, iy], _SOUTH, _WEST) rotate([0, 0, 180]) puzzle_female(positive);
                navigate_corner(size, count, padding, [0, iy], _NORTH, _WEST) mirror([0, 1]) rotate([0, 0, 180]) puzzle_female(positive);
            }
            if (connector[_EAST]) {
                navigate_corner(size, count, padding, [last.x, iy], _SOUTH, _EAST) mirror([0, 1]) puzzle_male(positive);
                navigate_corner(size, count, padding, [last.x, iy], _NORTH, _EAST) puzzle_male(positive);
            }
        }
        // At the corners of the segment, we now only have half-connectors. But if we have padding, there may be space for a full connector after all.
        // We add half-connectors at the corners and cut them to fit the plate.
        intersection() {
            translate([-size.x/2, -size.y/2 - 20]) square([size.x, size.y + 40]);
            union() {
                if (!connector[_WEST]) {
                    if (connector[_SOUTH]) navigate_corner(size, count, padding, [0, 0], _SOUTH, _WEST) rotate([0, 0, -90]) puzzle_female(positive);
                    if (connector[_NORTH]) navigate_corner(size, count, padding, [0, last.y], _NORTH, _WEST) mirror([1, 0]) rotate([0, 0, 90]) puzzle_male(positive);
                }
                if (!connector[_EAST]) {
                    if (connector[_SOUTH]) navigate_corner(size, count, padding, [last.x, 0], _SOUTH, _EAST) mirror([1, 0]) rotate([0, 0, -90]) puzzle_female(positive);
                    if (connector[_NORTH]) navigate_corner(size, count, padding, [last.x, last.y], _NORTH, _EAST) rotate([0, 0, 90]) puzzle_male(positive);
                }
            }
        }
        intersection() {
            translate([-size.x/2 - 20, -size.y/2]) square([size.x + 40, size.y]);
            union() {
                if (!connector[_SOUTH]) {
                    if (connector[_WEST]) navigate_corner(size, count, padding, [0, 0], _SOUTH, _WEST) mirror([0, 1]) rotate([0, 0, 180]) puzzle_female(positive);
                    if (connector[_EAST]) navigate_corner(size, count, padding, [last.x, 0], _SOUTH, _EAST) puzzle_male(positive);
                }
                if (!connector[_NORTH]) {
                    if (connector[_WEST]) navigate_corner(size, count, padding, [0, last.y], _NORTH, _WEST) rotate([0, 0, 180]) puzzle_female(positive);
                    if (connector[_EAST]) navigate_corner(size, count, padding, [last.x, last.y], _NORTH, _EAST) mirror([0, 1]) puzzle_male(positive);
                }
            }
        }
    }
}

/**
 * @Summary Draw the shape of a segment corner depending on connector configuration
 * @Details The corner is square if there is an adjacent connector, and rounded if there is not
 * @param posy The y corner position (north or south)
 * @param posx The x corner position (east or west)
 * @param connector The connector configuration
 */
module segment_corner(posy=_NORTH, posx=_WEST, connector=[false, false, false, false]) {
    assert(posy == _NORTH || posy == _SOUTH);
    assert(posx == _EAST || posx == _WEST);
    if (connector[posx] || connector[posy]) {
        square(size = [plate_corner_radius*2, plate_corner_radius*2], center=true);
    } else {
        circle(r = plate_corner_radius);
    }
}

/**
 * @Summary Model a segment, which is piece of the plate without breaks
 * @param count The number of cells in this segment, on each axis
 * @param padding The padding, for each side
 * @param connector Whether to add a connector, for each side
 */
module segment(count=[1, 1], padding=[0, 0, 0, 0], connector=[false, false, false, false]) {
    size = [
        BASEPLATE_DIMENSIONS.x * count.x + padding[_EAST] + padding[_WEST],
        BASEPLATE_DIMENSIONS.y * count.y + padding[_NORTH] + padding[_SOUTH],
    ];
    intersection() {
        translate([0, 0, -_extra_height]) linear_extrude(height = _total_height) difference() {
            // basic plate with rounded corners
            hull() {
                translate([-size.x/2+plate_corner_radius, -size.y/2+plate_corner_radius]) segment_corner(_SOUTH, _WEST, connector);
                translate([size.x/2-plate_corner_radius, -size.y/2+plate_corner_radius]) segment_corner(_SOUTH, _EAST, connector);
                translate([size.x/2-plate_corner_radius, size.y/2-plate_corner_radius]) segment_corner(_NORTH, _EAST, connector);
                translate([-size.x/2+plate_corner_radius, size.y/2-plate_corner_radius]) segment_corner(_NORTH, _WEST, connector);
            };
            segment_connectors(false, count, size, padding, connector);
        }
        union() {
            // padding cubes
            translate([0, 0, -_extra_height]) {
                if (padding[_NORTH] > 0) translate([-size.x/2, size.y/2-padding[_NORTH]]) cube([size.x, padding[_NORTH], _total_height]);
                if (padding[_EAST] > 0) translate([size.x/2-padding[_EAST], -size.y/2]) cube([padding[_EAST], size.y, _total_height]);
                if (padding[_SOUTH] > 0) translate([-size.x/2, -size.y/2]) cube([size.x, padding[_SOUTH], _total_height]);
                if (padding[_WEST] > 0) translate([-size.x/2, -size.y/2]) cube([padding[_WEST], size.y, _total_height]);
            }
            // cells
            last = last_cell(count);
            for (ix = [0:1:last.x]) for (iy = [0:1:last.y]) navigate_cell(size, count, padding, [ix, iy]) {
                cell([ix == count.x - 0.5, iy == count.y - 0.5]);
            };
        };
    };
    translate([0, 0, -_extra_height]) linear_extrude(height = _total_height) segment_connectors(true, count, size, padding, connector);
}

/**
 * @Summary Calculate the minimum number of segments required to print this axis
 * @param axis_norm The number of cells in this axis, may have 0.5 added to indicate a half cell
 * @param bed_norm The bed size, normalized by cell size
 * @param start_padding_norm The extra padding at the start of the axis, normalized by cell size
 * @param start_padding_norm The extra padding at the end of the axis, normalized by cell size
 */
function segments_per_axis(axis_norm, bed_norm, start_padding_norm, end_padding_norm) = 
    axis_norm + start_padding_norm + end_padding_norm <= bed_norm ? 1 :
    let(
        start_count = floor(bed_norm - start_padding_norm),
        has_half = (axis_norm%1) != 0,
        end_count = min(floor(bed_norm - end_padding_norm - (has_half ? 0.5 : 0)) + (has_half ? 0.5 : 0), axis_norm - start_count),
        remaining_count = axis_norm - start_count - end_count
    ) ceil(remaining_count / floor(bed_norm)) + 2;

/**
 * @Summary Calculate an ideal axis plan.
 * @Details An ideal axis plan uses the fewest possible segments, and keeps segments roughly the same size.
 * @param axis_norm The number of cells in this axis, may have 0.5 added to indicate a half cell
 * @param bed_norm The bed size, normalized by cell size
 * @param start_padding_norm The extra padding at the start of the axis, normalized by cell size
 * @param start_padding_norm The extra padding at the end of the axis, normalized by cell size
 * @return A vector containing the number of cells in each planned segment
 */
function plan_axis_ideal(axis_norm, bed_norm, start_padding_norm, end_padding_norm) =
    let(
        total_size = axis_norm + start_padding_norm + end_padding_norm,
        segment_count = segments_per_axis(axis_norm, bed_norm, start_padding_norm, end_padding_norm),
    ) [for (i = [0:segment_count - 1]) let(
        ideal_start = total_size * i / segment_count,
        ideal_end = total_size * (i + 1) / segment_count,
        count = (i == segment_count - 1 ? axis_norm : round(ideal_end - start_padding_norm)) - round(ideal_start - start_padding_norm)
    ) count];

/**
 * @Summary Calculate an incremental axis plan.
 * @Details An incremental axis plan uses the maximum number of cells for each segment, and then sizes the final segment to contain the remaining cells.
 * @param axis_norm The number of cells in this axis, may have 0.5 added to indicate a half cell
 * @param bed_norm The bed size, normalized by cell size
 * @param start_padding_norm The extra padding at the start of the axis, normalized by cell size
 * @param start_padding_norm The extra padding at the end of the axis, normalized by cell size
 * @param force_first If set, forcibly change the size of the first segment
 * @return A vector containing the number of cells in each planned segment
 */
function plan_axis_incremental(axis_norm, bed_norm, start_padding_norm, end_padding_norm, force_first=undef) = 
    axis_norm + start_padding_norm + end_padding_norm <= bed_norm ? [axis_norm] :
    let(
        // make a preliminary first segement
        first_p = force_first == undef ? floor(bed_norm - start_padding_norm) : force_first,
        mid = floor(bed_norm),
        // make a preliminary end segment
        end_p = (axis_norm - first_p - 0.25) % mid + 0.25,
        // is the end segment too small, i.e. a single half-cell?
        shift = end_p < 1,
        // if the end segment was too small, shrink the first segment a bit to give the end segment a better size
        first = shift ? first_p - 1 : first_p,
        // recalculate end segment size
        end = (axis_norm - first - 0.25) % mid + 0.25
    ) [for(i = 0, pos = 0; pos < axis_norm; i = i + 1, pos = first + mid * (i - 1)) 
        i == 0 ? first : pos + mid >= axis_norm ? end : mid];

/**
 * @Summary Calculate the sum of a vector's elements, up to the until index (exclusive)
 */
function sum_sub_vector(vector, until) = 
    [for (i = 0, sum = 0; i <= until; sum = (i == until ? undef : sum + vector[i]), i = i + 1) sum][until];

module main() {
    plate_count = [
        floor(plate_size.x / BASEPLATE_DIMENSIONS.x * (do_half.x ? 2 : 1)) / (do_half.x ? 2 : 1),
        floor(plate_size.y / BASEPLATE_DIMENSIONS.y * (do_half.y ? 2 : 1)) / (do_half.y ? 2 : 1)
    ];
    plate_padding_sum = [
        plate_size.x - plate_count.x * BASEPLATE_DIMENSIONS.x,
        plate_size.y - plate_count.y * BASEPLATE_DIMENSIONS.y
    ];
    plate_padding = [ // TODO: adjustable
        plate_padding_sum.y / 2, // NORTH
        plate_padding_sum.x / 2, // EAST
        plate_padding_sum.y / 2, // SOUTH
        plate_padding_sum.x / 2, // WEST
    ] + edge_adjust;
    // keep some margin on the edge of the bed clear for the connectors
    connector_margin = connector_type == _CONNECTOR_INTERSECTION_PUZZLE ? 3.5 : 0;
    // for the x axis, we only need a single plan, so we can use the ideal algorithm.
    plan_x = plan_axis_ideal(axis_norm=plate_count.x, bed_norm=(bed_size.x - connector_margin)/BASEPLATE_DIMENSIONS.x, start_padding_norm=plate_padding[_WEST]/BASEPLATE_DIMENSIONS.x, end_padding_norm=plate_padding[_EAST]/BASEPLATE_DIMENSIONS.x);
    // for the y axis, we need to avoid 4-way gap intersections, so we need two plans.
    plan_y_1 = plan_axis_incremental(axis_norm=plate_count.y, bed_norm=(bed_size.y - connector_margin)/BASEPLATE_DIMENSIONS.y, start_padding_norm=plate_padding[_SOUTH]/BASEPLATE_DIMENSIONS.y, end_padding_norm=plate_padding[_NORTH]/BASEPLATE_DIMENSIONS.y);
    plan_y_2 = len(plan_y_1) <= 1 ? plan_y_1 : plan_axis_incremental(axis_norm=plate_count.y, bed_norm=(bed_size.y - connector_margin)/BASEPLATE_DIMENSIONS.y, start_padding_norm=plate_padding[_SOUTH]/BASEPLATE_DIMENSIONS.y, end_padding_norm=plate_padding[_NORTH]/BASEPLATE_DIMENSIONS.y, force_first=plan_y_1[0] - 1);
    for (segix = [0:len(plan_x) - 1]) {
        plan_y = segix % 2 == 0 ? plan_y_1 : plan_y_2;
        for (segiy = [0:len(plan_y) - 1]) {
            translate([
                (sum_sub_vector(plan_x, segix) + plan_x[segix]/2) * BASEPLATE_DIMENSIONS.x + segix * _segment_gap + (segix == 0 ? 0 : plate_padding[_WEST]),
                (sum_sub_vector(plan_y, segiy) + plan_y[segiy]/2) * BASEPLATE_DIMENSIONS.y + segiy * _segment_gap + (segiy == 0 ? 0 : plate_padding[_SOUTH]),
                0
            ]) segment(count=[plan_x[segix], plan_y[segiy]], padding=[
                segiy == len(plan_y) - 1 ? plate_padding[_NORTH] : 0,
                segix == len(plan_x) - 1 ? plate_padding[_EAST] : 0,
                segiy == 0 ? plate_padding[_SOUTH] : 0,
                segix == 0 ? plate_padding[_WEST] : 0,
            ], connector=[
                segiy != len(plan_y) - 1,
                segix != len(plan_x) - 1,
                segiy != 0,
                segix != 0
            ]);
        }
    }
}

module test_pattern_padding() {
    translate([30, 30]) segment(count = [1, 1], padding=[5, 0, 0, 0], connector = [false, true, false, true]);
    translate([-30, 30]) segment(count = [1, 1], padding=[0, 5, 0, 0], connector = [true, false, true, false]);
    translate([30, -30]) segment(count = [1, 1], padding=[0, 0, 5, 0], connector = [false, true, false, true]);
    translate([-30, -30]) segment(count = [1, 1], padding=[0, 0, 0, 5], connector = [true, false, true, false]);
}

module test_pattern_half() {
    segment(count = [1.5, 1.5], connector = [true, true, true, true]);
}

main();
//test_pattern_half();
//test_pattern_padding();


