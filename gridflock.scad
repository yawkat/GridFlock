include <gridfinity-rebuilt-openscad/src/core/gridfinity-baseplate.scad>
use <gridfinity-rebuilt-openscad/src/helpers/list.scad>
include <paths/puzzle.scad>

// The bed size of the printer, e.g. 250x220 for the Prusa Core One
bed_size = [250, 220];
// The size of the grid plate to generate
plate_size = [371, 254];
// If there's not enough space for a full grid cell, squeeze in a half cell (x direction)
do_half_x = true;
// If there's not enough space for a full grid cell, squeeze in a half cell (y direction)
do_half_y = true;
// Thickness of the optional solid base
solid_base = 0;
// Chamfer at the bottom edge of the plate. Configurable for each edge individually (clockwise: north, east, south, west)
bottom_chamfer = [0, 0, 0, 0];

/* [Magnets] */

// Whether to enable friction-fit magnets for each grid cell
magnets = true;
// Magnet style
magnet_style = 1; // [0:Glue from top, 1:Press-Fit]
// Diameter of the magnet slot
magnet_diameter = 5.9;
// Height of the magnet slot
magnet_height = 2.25;
// Wall above the magnet. Should be small for maximum magnet strength
magnet_top = 0.5;
// Floor below the magnet. Not structurally important, should be small to minimize filament use
magnet_bottom = 0.75;

/* [Intersection Puzzle Connector] */

// Enable the intersection puzzle plate connector. This is similar to GridPlates/GRIPS. Small puzzle connectors are added cell intersections.
connector_intersection_puzzle = true;

/* [Edge Puzzle Connector] */

// Enable the edge puzzle plate connector. This connector is a bit cleaner, but is harder to print, especially when magnets are disabled (not enough vertical space). It's also more customizable, so you can tune the fit to your printer.
connector_edge_puzzle = false;

// Number of puzzle connectors per cell
edge_puzzle_count = 1;
// Dimensions of the male puzzle connector (main piece)
edge_puzzle_dim = [10, 2.5];
// Dimensions of the male puzzle connector (bridge to plate)
edge_puzzle_dim_c = [3, 1.2];
// Clearance of the puzzle connector. The female side is larger than the above dimensions by this amount
edge_puzzle_gap = 0.15;
// If magnets are enabled, use the vertical space to add a border to the female puzzle socket, for added stability and better printability
edge_puzzle_magnet_border = true;
// Size of the added border
edge_puzzle_magnet_border_width = 2.5;
// Height of the edge puzzle connector (female side, male is smaller by edge_puzzle_height_male_delta). You can set this to the full height, but make sure that no pieces of the segment remain unconnected!
edge_puzzle_height_female = 2.25;
// Male side of the edge puzzle connector is smaller than the female side by this amount
edge_puzzle_height_male_delta = 0.25;

/* [Numbering] */

// Enable numbering of the segements, embossed in a corner
numbering = true;
// Depth of the embossing
number_depth = 0.5;
// Font size of the numbers
number_size = 3;
// Font
number_font = "sans-serif";
// When a segment is very narrow, use this reduced number size. Should rarely be relevant
number_squeeze_size = 2;

/* [Plate wall] */

// Plate wall thickness. Can be specified for each direction individually (north, east, south, west). Note that this is *added* to the plate_size
plate_wall_thickness = [0, 0, 0, 0];
// Plate wall height. The first value is the height above the plate, the second value the height below the plate
plate_wall_height = [0, 0];

/* [Advanced] */

// Corner radius of the generated plate. The default of 4mm matches the corner radius of the gridfinity cell
plate_corner_radius = 4;
// Edge adjustment values (clockwise: north, east, south, west). These values are *added* to the plate size as padding, i.e. the final plate will end up different than configured in plate_size. This allows you to customize the padding to be asymmetrical. You can also use negative values to "cut" the plate edges if you want to squeeze an extra square out of limited space.
edge_adjust = [0, 0, 0, 0];
// In the y direction, segment sizes are determined by a simple algorithm that only resizes the first and last segments. The number of rows for the first segment alternate to avoid 4-way intersections. You can override the number of rows in the start segment for the odd and even columns with this property 
y_row_count_first = [0, 0]; 
// Test patterns
test_pattern = 0; // [0:None, 1:Half, 2:Padding, 3:Numbering, 4:Wall]

/* [Hidden] */

_MAGNET_GLUE_TOP = 0;
_MAGNET_PRESS_FIT = 1;

// openscad does not support boolean vectors in the customizer
do_half = [do_half_x, do_half_y];

$fn=40;

// dimensions of the magnet extraction slot
_magnet_extraction_dim = [magnet_diameter/2, magnet_diameter/2+2];
// dimensions of the magnet extraction slot in negative mode. This is used to cut out slots out of the edge puzzle connector. This is a bit smaller to make the edge puzzle connector less frail
_magnet_extraction_dim_negative = [magnet_diameter/2, magnet_diameter/2];

// actual height of a gridfinity profile with no extra clearance.
// gridfinity rebuilt adds extra clearance at the bottom, we cut that out. This is the height for z>0
_profile_height = 4.65;
// height of the magnet level
_magnet_level_height = (magnet_style == _MAGNET_PRESS_FIT ? magnet_top : 0) + magnet_bottom + magnet_height;
// total height of the non-bin levels (magnets, solid base). These are placed at z<0
_extra_height = (magnets ? _magnet_level_height : 0) + solid_base;

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

// Distance between edge connector pieces, if multiple configured
_edge_puzzle_stagger = edge_puzzle_dim.x + 2;
// Which edges have male connectors?
_edge_puzzle_direction_male = [true, true, false, false];

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
 * @param positive This flag is false when this cell is used for cutting instead of additively. When cutting, we can simplify the geometry in ways that would waste filament for additive mode
 */
module cell(half=[false, false], connector=[false, false, false, false], positive=true) {
    size = [BASEPLATE_DIMENSIONS.x/(half.x?2:1), BASEPLATE_DIMENSIONS.y/(half.y?2:1)];
    difference() {
        union() {
            difference() {
                translate([-size.x/2, -size.y/2, -_extra_height]) cube([size.x, size.y, _total_height]);
                // baseplate_cutter accepts a height parameter. _profile_height is the actual profile part of this. The remainder is "dead" space below the profile that the bin does not use. That's where e.g. magnets are placed.
                // The problem is that the height parameter must be at least BASEPLATE_HEIGHT, which is slightly larger than _profile_height, so there is some "mandatory" dead space.
                cutter_height = _profile_height + _extra_height - solid_base + 0.001; // the +0.001 fixes what appears to be some floating point issue
                translate([0, 0, _profile_height - cutter_height]) {
                    if (cutter_height >= BASEPLATE_HEIGHT) {
                        baseplate_cutter(size, cutter_height);
                    } else if (cutter_height >= _total_height) {
                        // we can simply move down a little bit, the additional cutting will only cut air anyway.
                        translate([0, 0, cutter_height - BASEPLATE_HEIGHT]) baseplate_cutter(size, BASEPLATE_HEIGHT);
                    } else {
                        // we need to manually remove the dead space from the cut
                        intersection() {
                            translate([0, 0, cutter_height - BASEPLATE_HEIGHT]) baseplate_cutter(size, BASEPLATE_HEIGHT);
                            translate([-size.x/2, -size.y/2]) cube([size.x, size.y, cutter_height]);
                        }
                    }
                }
            }
            if (magnets) {
                translate([0, 0, -_magnet_level_height]) linear_extrude(height = _magnet_level_height) {
                    if (positive) {
                        each_cell_corner(half) {
                            total_bounds = _magnet_location + magnet_diameter/2 + _magnet_border;
                            square([_magnet_location, total_bounds]);
                            square([total_bounds, _magnet_location]);
                            translate([_magnet_location, _magnet_location]) circle(r=magnet_diameter/2+_magnet_border);
                        }
                        if (connector_edge_puzzle && edge_puzzle_magnet_border) {
                            bw = edge_puzzle_dim.y + edge_puzzle_dim_c.y + edge_puzzle_magnet_border_width;
                            translate(-size/2) {
                                if (connector[_SOUTH] && !_edge_puzzle_direction_male[_SOUTH]) square([size.x, bw]);
                                if (connector[_WEST] && !_edge_puzzle_direction_male[_WEST]) square([bw, size.y]);
                            }
                            if (connector[_NORTH] && !_edge_puzzle_direction_male[_NORTH]) translate([-size.x/2, size.y/2-bw]) square([size.x, bw]);
                            if (connector[_EAST] && !_edge_puzzle_direction_male[_EAST]) translate([size.x/2-bw, -size.y/2]) square([bw, size.y]);
                        }
                    } else {
                        translate(-BASEPLATE_DIMENSIONS/2) square([BASEPLATE_DIMENSIONS.x, BASEPLATE_DIMENSIONS.y]);
                    }
                }
            }
        }
        if (magnets) {
            each_cell_corner(half) {
                translate([_magnet_location, _magnet_location]) {
                    rot_slot = half.x == half.y ? -45 : -90;
                    // magnet slot
                    translate([0, 0, -_magnet_level_height + magnet_bottom]) linear_extrude(magnet_height) {
                        circle(magnet_diameter/2);
                        if (magnet_style == _MAGNET_PRESS_FIT) rotate([0, 0, rot_slot]) translate([-magnet_diameter/2, 0]) square([magnet_diameter, magnet_diameter/2 + _magnet_border]);
                    }
                    if (magnet_style == _MAGNET_PRESS_FIT) {
                        // magnet extraction slot
                        rotate([0, 0, rot_slot]) translate([0, 0, -_extra_height]) linear_extrude(_extra_height - _magnet_level_height + magnet_bottom + magnet_height) {
                            extraction_dim = positive ? _magnet_extraction_dim : _magnet_extraction_dim_negative;
                            translate([-extraction_dim.x/2, -extraction_dim.y]) square(extraction_dim);
                            translate([0, -extraction_dim.y]) circle(extraction_dim.x/2);
                            circle(extraction_dim.x/2);
                        }
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
 * @Summary Get the position of a particular cell on one axis (1D)
 * @param dimension The cell dimension on this axis
 * @param size The segment size on this axis
 * @param count The number of cells on this axis
 * @param padding_start The start padding on this axis
 * @param index The index of this cell on this axis (may be < 0 or >= size also)
 */
function cell_axis_position(dimension, size, count, padding_start, index) =
    let(
        half = index == count - 0.5,
        // if we go outside the count, and we have a half cell, we need to go back half a cell
        adj = index > count && (count % 1) == 0.5 ? 0.5 : 0
    ) -size/2 + padding_start + (index + (half ? 0.25 : 0.5) - adj) * dimension;

/**
 * @Summary In the segment coordinate system, translate to the center of a particular cell
 * @param size The size of the segment
 * @param count The number of cells on each axis
 * @param padding The padding of the segment (for each edge)
 * @param index The index of the cell (can also be negative or >= count)
 */
module navigate_cell(size, count, padding, index) {
    translate([
        cell_axis_position(BASEPLATE_DIMENSIONS.x, size.x, count.x, padding[_WEST], index.x), 
        cell_axis_position(BASEPLATE_DIMENSIONS.y, size.y, count.y, padding[_SOUTH], index.y)
    ]) children();
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
 * @Summary In the segment coordinate system, translate to an edge of a particular cell
 * @param size The size of the segment
 * @param count The number of cells on each axis
 * @param padding The padding of the segment (for each edge)
 * @param index The index of the cell
 * @param dir The edge to navigate to (N/E/S/W)
 */
module navigate_edge(size, count, padding, index, dir) {
    half = [index.x == count.x - 0.5, index.y == count.y - 0.5];
    navigate_cell(size, count, padding, index) translate([
        (dir == _WEST ? -1 : dir == _EAST ? 1 : 0) * BASEPLATE_DIMENSIONS.x / (half.x ? 4 : 2),
        (dir == _SOUTH ? -1 : dir == _NORTH ? 1 : 0) * BASEPLATE_DIMENSIONS.y / (half.y ? 4 : 2)
    ]) children();
}

/**
 * @Summary Draw the segment intersection connectors (2D)
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
module segment_intersection_connectors(positive, count, size, padding, connector) {
    last = last_cell(count);
    // for the normal case, we iterate over the cells at the edge of the segment, and add two half-connectors for each cell.
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

/**
 * @Summary Draw the segment edge connectors (2D)
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
module segment_edge_connectors(positive, count, size, padding, connector) {
    last = last_cell(count);
    for (ix = [0:1:last.x]) {
        half = ix == count.x - 0.5;
        if (connector[_SOUTH]) navigate_edge(size, count, padding, [ix, 0], _SOUTH) edge_puzzle(positive, _edge_puzzle_direction_male[_SOUTH], half);
        if (connector[_NORTH]) navigate_edge(size, count, padding, [ix, last.y], _NORTH) mirror([0, 1]) edge_puzzle(positive, _edge_puzzle_direction_male[_NORTH], half);
    }
    for (iy = [0:1:last.y]) {
        half = iy == count.y - 0.5;
        if (connector[_WEST]) navigate_edge(size, count, padding, [0, iy], _WEST) mirror([1, 0]) rotate([0, 0, 90]) edge_puzzle(positive, _edge_puzzle_direction_male[_WEST], half);
        if (connector[_EAST]) navigate_edge(size, count, padding, [last.x, iy], _EAST) rotate([0, 0, 90]) edge_puzzle(positive, _edge_puzzle_direction_male[_EAST], half);
    }
}

/**
 * @Summary Draw a rounded bar
 * @Details This is a rectangle that is rounded at the start and end of the x direction. The full bar fits into the given size
 * @param size The bounds of the bar
 */
module round_bar_x(size) {
    translate([size.y/2, 0]) square([size.x - size.y, size.y]);
    translate([size.y/2, size.y/2]) circle(size.y/2);
    translate([size.x-size.y/2, size.y/2]) circle(size.y/2);
}

/**
 * @Summary Draw a negative rounded bar
 * @Details This is a rectangle that is *negatively* rounded (i.e. circles cut out) at the start and end of the x direction. The full bar fits into the given size
 * @param size The bounds of the bar
 */
module round_bar_x_neg(size) {
    difference() {
        translate([-size.y/2, 0]) square([size.x + size.y, size.y]);
        translate([-size.y/2, size.y/2]) circle(size.y/2);
        translate([size.x+size.y/2, size.y/2]) circle(size.y/2);
    }
}

/**
 * @Summary Draw the edge puzzle connector for a single cell side (2D)
 * @Details This function operates as if on the south edge: The male side extends into the south direction, the female goes into the north direction. For other orientations, rotate/mirror as needed
 * @param positive Whether this is the positive pass of the edge puzzle drawing
 * @param male Whether this side has a male connector
 * @param half Whether this edge is half size
 */
module edge_puzzle(positive, male, half) {
    count_here = half ? max(1, floor(edge_puzzle_count/2)) : edge_puzzle_count;
    for (i = [0:1:count_here-1]) translate([(-(count_here-1)/2+i)*_edge_puzzle_stagger, 0]) {
        if (male) {
            if (positive) {
                translate([-edge_puzzle_dim_c.x/2, -edge_puzzle_dim_c.y]) round_bar_x_neg([edge_puzzle_dim_c.x, edge_puzzle_dim_c.y]);
                translate([-edge_puzzle_dim.x/2, -edge_puzzle_dim_c.y-edge_puzzle_dim.y]) round_bar_x([edge_puzzle_dim.x, edge_puzzle_dim.y]);
            }
        } else {
            if (!positive) {
                translate([-edge_puzzle_dim_c.x/2-edge_puzzle_gap, 0]) round_bar_x_neg([edge_puzzle_dim_c.x+edge_puzzle_gap*2, edge_puzzle_dim_c.y-edge_puzzle_gap]);
                translate([-edge_puzzle_dim.x/2-edge_puzzle_gap, edge_puzzle_dim_c.y-edge_puzzle_gap]) round_bar_x([edge_puzzle_dim.x+edge_puzzle_gap, edge_puzzle_dim.y+edge_puzzle_gap]);
            }
        }
    }
    //translate([-0.5,0]) square([1, 15]); // for visually checking alignment
}

/**
 * @Summary Draw the shape of a segment corner depending on connector configuration (2D)
 * @Details The corner is square if there is an adjacent connector, and rounded if there is not
 * @param posy The y corner position (north or south)
 * @param posx The x corner position (east or west)
 * @param connector The connector configuration
 * @param radius Function to compute the corner radius by side
 */
module segment_corner(posy=_NORTH, posx=_WEST, connector=[false, false, false, false], radius) {
    assert(posy == _NORTH || posy == _SOUTH);
    assert(posx == _EAST || posx == _WEST);
    radii = [radius(posx), radius(posy)];
    if (connector[posx] || connector[posy]) {
        square(size = radii * 2, center=true);
    } else {
        // ellipse
        scale(radii) circle(r = 1);
    }
}

/**
 * @Summary Draw the 2D shape of a segment, including rounded corners
 * @param size The size of the segment
 * @param connector The connector configuration
 * @param include_wall If false, the plate_wall_thickness is not included in the rectangle
 */
module segment_rectangle(size, connector=[false, false, false, false], include_wall=false) {
    // wall thickness to cut off, by side
    wall_t = function (side) include_wall || connector[side] ? 0 : plate_wall_thickness[side];
    // corner radius by side
    compute_radius = function (side) max(0.01, plate_corner_radius - wall_t(side));
    bounds_offset = function (side) compute_radius(side) + wall_t(side);
    bounds_min = [
        -size.x/2 + bounds_offset(_WEST),
        -size.y/2 + bounds_offset(_SOUTH)
    ];
    bounds_max = [
        size.x/2 - bounds_offset(_EAST),
        size.y/2 - bounds_offset(_NORTH)
    ];
    hull() {
        translate([bounds_min.x, bounds_min.y]) segment_corner(_SOUTH, _WEST, connector, compute_radius);
        translate([bounds_max.x, bounds_min.y]) segment_corner(_SOUTH, _EAST, connector, compute_radius);
        translate([bounds_max.x, bounds_max.y]) segment_corner(_NORTH, _EAST, connector, compute_radius);
        translate([bounds_min.x, bounds_max.y]) segment_corner(_NORTH, _WEST, connector, compute_radius);
    };
}

module chamfer_triangle() {
    extend = 20;
    // extend far out into -x and -y to make sure we cut everything
    polygon([[-extend, -extend], [1 + extend, -extend], [-extend, 1 + extend]]);
}

/**
 * @Summary Model a segment, which is piece of the plate without breaks
 * @param count The number of cells in this segment, on each axis
 * @param padding The padding, for each side
 * @param connector Whether to add a connector, for each side
 * @param global_segment_index If applicable, the global index of this segment. This is used to emboss numbering
 */
module segment(count=[1, 1], padding=[0, 0, 0, 0], connector=[false, false, false, false], global_segment_index=undef) {
    size = [
        BASEPLATE_DIMENSIONS.x * count.x + padding[_EAST] + padding[_WEST],
        BASEPLATE_DIMENSIONS.y * count.y + padding[_NORTH] + padding[_SOUTH],
    ];
    _edge_puzzle_height_male = edge_puzzle_height_female - edge_puzzle_height_male_delta;
    // whether to cut the male edge puzzle connector to make room for the bin in the next cell. For really short connectors this is not necessary, but there's also no good reason to turn this off, so it's not user configurable at the moment
    _edge_puzzle_overlap = true;
    last = last_cell(count);
    difference() {
        union() {
            intersection() {
                translate([0, 0, -_extra_height]) linear_extrude(height = _total_height) difference() {
                    // basic plate with rounded corners
                    segment_rectangle(size, connector, include_wall=false);
                    if (connector_intersection_puzzle) {
                        segment_intersection_connectors(false, count, size, padding, connector);
                    }
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
                    for (ix = [0:1:last.x]) for (iy = [0:1:last.y]) navigate_cell(size, count, padding, [ix, iy]) {
                        cell([ix == count.x - 0.5, iy == count.y - 0.5], [
                            connector[_NORTH] && iy == last.y,
                            connector[_EAST] && ix == last.x,
                            connector[_SOUTH] && iy == 0,
                            connector[_WEST] && ix == 0
                        ]);
                    };
                };
            };

            if (plate_wall_thickness != [0,0,0,0]) translate([0, 0, -_extra_height-plate_wall_height[1]]) linear_extrude(_total_height + plate_wall_height[0] + plate_wall_height[1]) difference() {
                segment_rectangle(size, connector, include_wall=true);
                segment_rectangle(size, connector, include_wall=false);
            }
            
            if (connector_intersection_puzzle) translate([0, 0, -_extra_height]) linear_extrude(height = _total_height) segment_intersection_connectors(true, count, size, padding, connector);
            if (connector_edge_puzzle) {
                intersection() {
                    translate([0, 0, -_extra_height]) linear_extrude(height = _extra_height+_edge_puzzle_height_male) segment_edge_connectors(true, count, size, padding, connector);
                    if (_edge_puzzle_overlap) union() {
                        for (ix = [0:1:last.x]) {
                            if (connector[_SOUTH]) navigate_cell(size, count, padding, [ix, -1]) cell([ix == count.x - 0.5, false], positive=false);
                            if (connector[_NORTH]) navigate_cell(size, count, padding, [ix, last.y+1]) cell([ix == count.x - 0.5, false], positive=false);
                        }
                        for (iy = [0:1:last.y]) {
                            if (connector[_WEST]) navigate_cell(size, count, padding, [-1, iy]) cell([false, iy == count.y - 0.5], positive=false);
                            if (connector[_EAST]) navigate_cell(size, count, padding, [last.x+1, iy]) cell([false, iy == count.y - 0.5], positive=false);
                        }
                    }
                }
            }
        }
        if (connector_edge_puzzle) {
            translate([0, 0, -_extra_height]) linear_extrude(height = _extra_height+edge_puzzle_height_female) segment_edge_connectors(false, count, size, padding, connector);
        }
        if (numbering && global_segment_index != undef) {
            squeeze = count.x <= 1;
            navigate_cell(size, count, padding, [0, 0]) translate([BASEPLATE_DIMENSIONS.x/(count.x == 0.5 ? 4 : 2)-(squeeze?2.95/2:0), -BASEPLATE_DIMENSIONS.y/2+4, -_extra_height]) linear_extrude(number_depth) mirror([0, 1]) rotate([0, 0, 90]) text(str(global_segment_index + 1), size = squeeze ? number_squeeze_size : number_size, halign="right", valign = "center", font = number_font);
        }
        // extend a bit beyond the segment edges to make sure we cut any overhang
        extend = 10;
        if (bottom_chamfer[_SOUTH] > 0 && !connector[_SOUTH]) translate([-size.x/2 - extend, -size.y/2, -_extra_height]) rotate([0, 90, 0]) rotate([0, 0, 90]) linear_extrude(size.x + extend * 2) scale(bottom_chamfer[_SOUTH]) chamfer_triangle();
        if (bottom_chamfer[_WEST] > 0 && !connector[_WEST]) translate([-size.x/2, -size.y/2 - extend, -_extra_height]) rotate([-90, 0, 0]) rotate([0, 0, -90]) linear_extrude(size.y + extend * 2) scale(bottom_chamfer[_WEST]) chamfer_triangle();
        if (bottom_chamfer[_NORTH] > 0 && !connector[_NORTH]) translate([size.x/2 + extend, size.y/2, -_extra_height]) rotate([0, -90, 0]) rotate([0, 0, -90]) linear_extrude(size.x + extend * 2) scale(bottom_chamfer[_NORTH]) chamfer_triangle();
        if (bottom_chamfer[_EAST] > 0 && !connector[_EAST]) translate([size.x/2, size.y/2 + extend, -_extra_height]) rotate([90, 0, 0]) rotate([0, 0, 90]) linear_extrude(size.y + extend * 2) scale(bottom_chamfer[_EAST]) chamfer_triangle(); 
    }
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
 * @return A vector in the format: [start, mid, end], where the start is the size of the first segment, end the size of the last segment, and mid the size of all other segments
 */
function plan_axis_incremental_vars(axis_norm, bed_norm, start_padding_norm, end_padding_norm, force_first=undef) = 
    assert(axis_norm > 0)
    assert(bed_norm > 1)
    assert(start_padding_norm != undef)
    assert(end_padding_norm != undef)
    axis_norm + start_padding_norm + end_padding_norm <= bed_norm ? [axis_norm, -1, -1] :
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
    ) [first, mid, end];

/**
 * @Summary Transform a short plan from plan_axis_incremental_vars into a full plan as returned by plan_axis_ideal
 * @return A vector containing the number of cells in each planned segment
 */
function vars_to_incremental(axis_norm, vars) = let(
        first = vars[0],
        mid = vars[1],
        end = vars[2]
    ) mid == -1 ? [first] : [for(i = 0, pos = 0; pos < axis_norm; i = i + 1, pos = first + mid * (i - 1)) 
        i == 0 ? first : pos + mid >= axis_norm ? end : mid];

/**
 * @Summary Calculate two axis plans that are staggered so that segment corners don't intersect
 * @Details An incremental axis plan uses the maximum number of cells for each segment, and then sizes the final segment to contain the remaining cells.
 * @param axis_norm The number of cells in this axis, may have 0.5 added to indicate a half cell
 * @param bed_norm The bed size, normalized by cell size
 * @param start_padding_norm The extra padding at the start of the axis, normalized by cell size
 * @param start_padding_norm The extra padding at the end of the axis, normalized by cell size
 * @param force_first If set, forcibly change the size of the first segment
 * @return A vector of exactly two axis plans, each a vector containing the number of cells in each planned segment
 */
function plan_axis_staggered(axis_norm, bed_norm, start_padding_norm=0, end_padding_norm=0) =
    assert(axis_norm > 0)
    assert(bed_norm > 1)
    assert(start_padding_norm != undef)
    assert(end_padding_norm != undef)
    let (
        // lambda: call plan_axis_incremental_vars with a specific shift
        plan_vars = function(force_first) plan_axis_incremental_vars(axis_norm, bed_norm, start_padding_norm, end_padding_norm, force_first),
        // lambda: calculate the number of segments for a given set of plan_axis_incremental_vars
        plan_size = function(vars) vars[1] == -1 ? 1 : (axis_norm - vars[0] - vars[2]) / vars[1] + 2,
        // make a simple plan for the first column
        plan_a1 = plan_vars(y_row_count_first[0] <= 0 ? undef : y_row_count_first[0]),
        // if the last segment in the column is small, give that segment one more cell
        plan_a2 = plan_a1[1] == -1 || plan_a1[2] >= 2 || plan_a1[0] <= 2 ? plan_a1 : plan_vars(plan_a1[0] - 1)
    )
    // manual override
    y_row_count_first[1] > 0 ? [vars_to_incremental(axis_norm, plan_a1), vars_to_incremental(axis_norm, plan_vars(y_row_count_first[1]))] :
    // shortcut: if we don't need to split at all, we don't need to worry about staggering
    plan_a1[1] == -1 ? [vars_to_incremental(axis_norm, plan_a1), vars_to_incremental(axis_norm, plan_a1)] : 
    let(
        // now, we determine the optimal shift of the second column.
        // first, plan with a minimum shift as a baseline.
        plan_b_shift1 = plan_vars(plan_a2[0] - 1),
        // then, iterate all possible shifts, until we hit one that requires an additional segment compared to plan_b_shift1
        plan_b_shift = [for (shift = 1, plan = plan_b_shift1, best_size = plan_size(plan); shift < plan_a2[0] && plan_size(plan) <= best_size; shift = shift + 1, plan = plan_vars(plan_a2[0] - shift)) 0],
        max_unsplit_shift = len(plan_b_shift),
        // separately, calculate an "optimum shift", where the 3-way intersections are as far apart as possible
        optimum_shift = plan_a2[0] <= 3 ? 1 : floor(plan_a2[0] / 2),
        // our final shift is the minimum of the two.
        shift = min(optimum_shift, max_unsplit_shift)
    ) [vars_to_incremental(axis_norm, plan_a2), vars_to_incremental(axis_norm, plan_vars(plan_a2[0] - shift))];

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
    plate_padding = [
        plate_padding_sum.y / 2, // NORTH
        plate_padding_sum.x / 2, // EAST
        plate_padding_sum.y / 2, // SOUTH
        plate_padding_sum.x / 2, // WEST
    ] + edge_adjust + plate_wall_thickness;
    // keep some margin on the edge of the bed clear for the connectors
    connector_margin = max(connector_intersection_puzzle ? 3.5 : 0, connector_edge_puzzle ? edge_puzzle_dim_c.y + edge_puzzle_dim.y : 0);
    // for the x axis, we only need a single plan, so we can use the ideal algorithm.
    plan_x = plan_axis_ideal(axis_norm=plate_count.x, bed_norm=(bed_size.x - connector_margin)/BASEPLATE_DIMENSIONS.x, start_padding_norm=plate_padding[_WEST]/BASEPLATE_DIMENSIONS.x, end_padding_norm=plate_padding[_EAST]/BASEPLATE_DIMENSIONS.x);
    // for the y axis, we need to avoid 4-way gap intersections, so we need two plans.
    plans_y = plan_axis_staggered(axis_norm=plate_count.y, bed_norm=(bed_size.y - connector_margin)/BASEPLATE_DIMENSIONS.y, start_padding_norm=plate_padding[_SOUTH]/BASEPLATE_DIMENSIONS.y, end_padding_norm=plate_padding[_NORTH]/BASEPLATE_DIMENSIONS.y);
    for (segix = [0:len(plan_x) - 1]) {
        plan_y = plans_y[segix % 2];
        for (segiy = [0:len(plan_y) - 1]) {
            global_segment_index = segiy + ceil(segix / 2) * len(plans_y[0]) + floor(segix / 2) * len(plans_y[1]);
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
            ], global_segment_index=global_segment_index);
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

module test_pattern_numbering() {
    translate([0, 30]) segment(count = [2, 1], connector = [true, true, true, true], global_segment_index = 11);
    translate([30, -30]) segment(count = [0.5, 1], connector = [true, true, true, true], global_segment_index = 12);
    translate([-30, -30]) segment(count = [1, 1], connector = [true, true, true, true], global_segment_index = 12);
}

module test_pattern_wall() {
    segment(count = [2, 2], connector=[false, false, false, false], padding=[5, 5, 5, 5]);
}

if (test_pattern == 0) {
    main();
} else if (test_pattern == 1) {
    test_pattern_half();
} else if (test_pattern == 2) {
    test_pattern_padding();
} else if (test_pattern == 3) {
    test_pattern_numbering();
} else if (test_pattern == 4) {
    test_pattern_wall();
}
