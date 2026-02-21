include <gridfinity-rebuilt-openscad/src/core/gridfinity-baseplate.scad>
use <gridfinity-rebuilt-openscad/src/helpers/list.scad>
include <paths/puzzle.scad>

// The size of the grid plate to generate
plate_size = [371, 254];
// The bed size of the printer, e.g. 250x220 for the Prusa Core One
bed_size = [250, 220];
// Thickness of the optional solid base
solid_base = 0;
// Chamfer at the bottom edge of the plate. Configurable for each edge individually (clockwise: north, east, south, west)
bottom_chamfer = [0, 0, 0, 0];
// Chamfer at the top edge of the plate. Configurable for each edge individually (clockwise: north, east, south, west)
top_chamfer = [0, 0, 0, 0];
// Padding alignment. The first value is the x direction (east/west), the second value the y direction (north/south). When padding is added to the build plate, this alignment is used to distribute it. A lower value will move the grid towards the west/south direction, adding more padding to the east/north
alignment = [0.5, 0.5]; // [0:0.1:1]

/* [Magnets] */

// Whether to enable friction-fit magnets for each grid cell
magnets = false;
// Magnet style
magnet_style = 1; // [0:Glue from top, 1:Press-Fit, 2:Glue from bottom]
// Style of the magnet level
magnet_frame_style = 1; // [0:Solid (incompatible with press-fit), 1:Round Corners]
// Diameter of the magnet slot
magnet_diameter = 5.9; // 0.01
// Height of the magnet slot
magnet_height = 2.25; // 0.25
// Wall above the magnet. Should be small for maximum magnet strength
magnet_top = 0.5; // 0.25
// Floor below the magnet. Not structurally important, should be small to minimize filament use
magnet_bottom = 0.75; // 0.25

/* [Click Latch (Experimental)] */

// Enable the click latch. WARNING: The plastic can deform over time, do not use PLA! PETG might be fine, but there are no long-term tests yet
click1 = false;
// Distance that the click latch extends into the bin area
click1_distance = 1; // .1
// Steepness of the click latch arc
click1_steepness = 1; // .1
// Length of the full click latch
click1_outer_length = 30;
// Length of the straight piece in the middle of the click latch. The arced pieces take up the remaining space
click1_inner_length = 0;
// Height of the click latch
click1_height = 3; // .1
// Thickness of the click latch. This is measured from the bottom of the baseplate profile
click1_strength = 1.6; // .1
// Thickness of the non-bending wall behind the click latch. This wall provides stability and prevents the click latch from bending too far
click1_wall_strength = 1; // .1

/* [Intersection Puzzle Connector] */

// Enable the intersection puzzle plate connector. This is similar to GridPlates/GRIPS. Small puzzle connectors are added cell intersections.
connector_intersection_puzzle = true;
// A value from 0 to 1 to modify the fit of the intersection puzzle connector. 0 is a loose fit, 1 is a tight fit.
intersection_puzzle_fit = 1; // [0:0.1:1]

/* [Edge Puzzle Connector] */

// Enable the edge puzzle plate connector. This connector is a bit cleaner, but is harder to print, especially when magnets are disabled (not enough vertical space). It's also more customizable, so you can tune the fit to your printer.
connector_edge_puzzle = false;

// Number of puzzle connectors per cell
edge_puzzle_count = 1;
// Dimensions of the male puzzle connector (main piece)
edge_puzzle_dim = [10, 2.5]; // 0.1
// Dimensions of the male puzzle connector (bridge to plate)
edge_puzzle_dim_c = [3, 1.2]; // 0.1
// Clearance of the puzzle connector. The female side is larger than the above dimensions by this amount
edge_puzzle_gap = 0.15; // 0.05
// If magnets are enabled, use the vertical space to add a border to the female puzzle socket, for added stability and better printability
edge_puzzle_magnet_border = true;
// Size of the added border
edge_puzzle_magnet_border_width = 2.5; // 0.1
// Height of the edge puzzle connector (female side, male is smaller by edge_puzzle_height_male_delta). You can set this to the full height, but make sure that no pieces of the segment remain unconnected!
edge_puzzle_height_female = 2.25; // 0.25
// Male side of the edge puzzle connector is smaller than the female side by this amount
edge_puzzle_height_male_delta = 0.25; // 0.25

/* [Filler] */

filler_x = 1; // [0:None, 1:Integer Fraction, 2:Dynamic]

filler_y = 1; // [0:None, 1:Integer Fraction, 2:Dynamic]

filler_fraction = [2, 2];

filler_minimum_size = [15, 15];

/* [Numbering] */

// Enable numbering of the segements, embossed in a corner
numbering = true;
// Depth of the embossing
number_depth = 0.5; // 0.25
// Font size of the numbers
number_size = 3; // 0.5
// Font
number_font = "sans-serif";
// When a segment is very narrow, use this reduced number size. Should rarely be relevant
number_squeeze_size = 2; // 0.5

/* [Plate wall] */

// Plate wall thickness. Can be specified for each direction individually (north, east, south, west). Note that this is *added* to the plate_size
plate_wall_thickness = [0, 0, 0, 0]; // 0.5
// Plate wall height. The first value is the height above the plate, the second value the height below the plate
plate_wall_height = [0, 0];

/* [Vertical Screws] */

// Radius of vertical screws
vertical_screw_diameter = 3.2; // 0.1
// Top countersink dimension. First value is the diameter of the screw head, second value the height
vertical_screw_countersink_top = [0, 0]; // 0.1
// Top counterbore dimension. First value is the diameter of the screw head, second value the height
vertical_screw_counterbore_top = [0, 0];

// Enable screws at *plate* corners
vertical_screw_plate_corners = false;
// Distance from the edge (in number of cells) for an intersection to qualify as a plate corner
vertical_screw_plate_corner_inset = [1, 1];
// Enable screws at *plate* edges
vertical_screw_plate_edges = false;
// Enable screws at *segment* corners that are not also plate corners
vertical_screw_segment_corners = false;
// Distance from the edge (in number of cells) for an intersection to qualify as a segment corner
vertical_screw_segment_corner_inset = [1, 1];
// Enable screws at *segment* edges (will interfere with intersection connectors!)
vertical_screw_segment_edges = false;
// Enable screws at all other intersections
vertical_screw_other = false;

/* [Thumb Screw] */

// Generate thumb screw cutouts compatible with 'Gridfinity Refined'. This requires solid_base or magnets with 
thumbscrews = false;
// Thumb screw cutout diameter
thumbscrew_diameter = 15.8; // 0.1

/* [Segmentation] */

// Select the algorithm for splitting the baseplate into segments along the x axis. The default ideal algorithm splits the plate into roughly equally-sized segments. The incremental algorithm produces as many maximum-size segments as possible, and one smaller segment for the remaining cells.
x_segment_algorithm = 0; // [0:Ideal, 1:Incremental]
// In the y direction, segment sizes are determined by a simple algorithm that only resizes the first and last segments. The number of rows for the first segment alternate to avoid 4-way intersections. You can override the number of rows in the start segment for the odd and even columns with this property 
y_row_count_first = [0, 0]; 
// If the 'incremental' x segment algorithm is chosen, this can be used to override the column count in the first segment.
x_column_count_first = 0;

/* [Advanced] */

// Corner radius of the generated plate. The default of 4mm matches the corner radius of the gridfinity cell
plate_corner_radius = 4;
// Edge adjustment values (clockwise: north, east, south, west). These values are *added* to the plate size as padding, i.e. the final plate will end up different than configured in plate_size. This allows you to customize the padding to be asymmetrical. You can also use negative values to "cut" the plate edges if you want to squeeze an extra square out of limited space.
edge_adjust = [0, 0, 0, 0];
// Override the content of individual cells. Each character in this string modifies one cell. The order goes from west to east, then south to north. A 'c' stands for a normal cell. An 's' stands for a solid plate without a cell cutout. An 'e' stands for an empty square
cell_override = "";
// Test patterns
test_pattern = 0; // [0:None, 1:Half, 2:Padding, 3:Numbering, 4:Wall, 5:Click]

/* [Hidden] */

// Resolution of the click latch.
click1_steps = 15;

_MAGNET_GLUE_TOP = 0;
_MAGNET_PRESS_FIT = 1;
_MAGNET_GLUE_BOTTOM = 2;

_MAGNET_SOLID = 0;
_MAGNET_ROUND_CORNERS = 1;

assert(!magnets || magnet_frame_style != _MAGNET_SOLID || magnet_style != _MAGNET_PRESS_FIT, "'Solid' magnet frame style is not compatible with press-fit magnets.");

assert(!thumbscrews || solid_base > 0 || (magnets && magnet_frame_style == _MAGNET_SOLID), "Thumbscrew holes require some sort of solid base, such as magnet_style solid, or an explicit solid_base.");

$fn=40;

// dimensions of the magnet extraction slot
_magnet_extraction_dim = [magnet_diameter/2, magnet_diameter/2+2];
// dimensions of the magnet extraction slot in negative mode. This is used to cut out slots out of the edge puzzle connector. This is a bit smaller to make the edge puzzle connector less frail
_magnet_extraction_dim_negative = [magnet_diameter/2, magnet_diameter/2];

// actual height of a gridfinity profile with no extra clearance.
// gridfinity rebuilt adds extra clearance at the bottom, we cut that out. This is the height for z>0
_profile_height = 4.65;
// height of the magnet level
_magnet_level_height = (magnet_style != _MAGNET_GLUE_TOP ? magnet_top : 0) + (magnet_style != _MAGNET_GLUE_BOTTOM ? magnet_bottom : 0) + magnet_height;
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

_CELL_STYLE_NORMAL = "c";
_CELL_STYLE_SOLID = "s";
_CELL_STYLE_EMPTY = "e";

_SEGMENT_ALGORITHM_IDEAL = 0;
_SEGMENT_ALGORITHM_INCREMENTAL = 1;

_FILLER_NONE = 0;
_FILLER_INTEGER = 1;
_FILLER_DYNAMIC = 2;

/**
 * @Summary Run some code in each corner, with proper rotation, to add magnets
 * @Details From the children's perspective, we are centered at the corner, and 
 *          the center of the cell is in the north-east (+x and +y)
 * @param unit_size Size of the cell, in grid units, in each direction
 */
module each_cell_corner(unit_size) {
    size = [BASEPLATE_DIMENSIONS.x*unit_size.x, BASEPLATE_DIMENSIONS.y*unit_size.y];
    if (unit_size.x < 1 && unit_size.y < 1) {
        translate([-size.x/2, size.y/2]) rotate([0, 0, 270]) children();
    } else if (unit_size.x < 1) {
        // these corners are chosen so that a half-size bin will fit both a vertical and a horizontal half-width slot
        translate([size.x/2, -size.y/2]) rotate([0, 0, 90]) children();
        translate([-size.x/2, size.y/2]) rotate([0, 0, 270]) children();
    } else if (unit_size.y < 1) {
        translate([-size.x/2, -size.y/2]) children();
        translate([size.x/2, size.y/2]) rotate([0, 0, 180]) children();
    } else {
        translate([-size.x/2, -size.y/2]) children();
        translate([size.x/2, -size.y/2]) rotate([0, 0, 90]) children();
        translate([-size.x/2, size.y/2]) rotate([0, 0, 270]) children();
        translate([size.x/2, size.y/2]) rotate([0, 0, 180]) children();
    }
}

/**
 * @Summary Draw a grid cell centered on 0,0
 * @param unit_size Size of the cell, in grid units, in each direction
 * @param positive This flag is false when this cell is used for cutting instead of additively. When cutting, we can simplify the geometry in ways that would waste filament for additive mode
 */
module cell(unit_size=[1, 1], connector=[false, false, false, false], positive=true) {
    size = [BASEPLATE_DIMENSIONS.x*unit_size.x, BASEPLATE_DIMENSIONS.y*unit_size.y];
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
                if (click1) translate([0, 0, _profile_height/2]) {
                    if (unit_size.x == 1) cube([click1_outer_length, size.y-click1_wall_strength*2, _profile_height], center=true);
                    if (unit_size.y == 1) cube([size.x-click1_wall_strength*2, click1_outer_length, _profile_height], center=true);
                }
            }
            if (click1) {
                if (unit_size.x == 1) {
                    translate([0, -size.y/2, 0]) rotate([90, 0, -90]) do_sweep(_click1_sweep, convexity=4);
                    translate([0, size.y/2, 0]) rotate([90, 0, 90]) do_sweep(_click1_sweep, convexity=4);
                }
                if (unit_size.y == 1) {
                    translate([-size.x/2, 0, 0]) rotate([90, 0, 180]) do_sweep(_click1_sweep, convexity=4);
                    translate([size.x/2, 0, 0]) rotate([90, 0, 0]) do_sweep(_click1_sweep, convexity=4);
                }
            }
            if (magnets) {
                translate([0, 0, -_magnet_level_height]) linear_extrude(height = _magnet_level_height) {
                    if (positive && magnet_frame_style != _MAGNET_SOLID) {
                        // round corners
                        if (magnet_frame_style == _MAGNET_ROUND_CORNERS) {
                            each_cell_corner(unit_size) {
                                total_bounds = _magnet_location + magnet_diameter/2 + _magnet_border;
                                square([_magnet_location, total_bounds]);
                                square([total_bounds, _magnet_location]);
                                translate([_magnet_location, _magnet_location]) circle(r=magnet_diameter/2+_magnet_border);
                            }
                        }
                        // if we have a female edge connector here, add a bar for stability (edge_puzzle_magnet_border)
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
                        // for negative mode, we don't care about extra geometry
                        // this also runs for _MAGNET_SOLID style
                        translate(-size/2) square(size);
                    }
                }
            }
        }
        if (magnets) {
            each_cell_corner(unit_size) {
                translate([_magnet_location, _magnet_location]) {
                    rot_slot = (unit_size == [1, 1] || (unit_size.x < 1 && unit_size.y < 1)) ? -45 : -90;
                    // magnet slot
                    if (magnet_style == _MAGNET_GLUE_BOTTOM) {
                        translate([0, 0, -_extra_height]) cylinder(d=magnet_diameter, h=_extra_height-magnet_top); 
                    } else {
                        translate([0, 0, -_magnet_level_height + magnet_bottom]) linear_extrude(magnet_height) {
                            circle(d=magnet_diameter);
                            if (magnet_style == _MAGNET_PRESS_FIT) rotate([0, 0, rot_slot]) translate([-magnet_diameter/2, 0]) square([magnet_diameter, magnet_diameter/2 + _magnet_border]);
                        }
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
        if (thumbscrews && unit_size == [1, 1]) rotate_extrude() {
            top = magnets && magnet_frame_style != _MAGNET_SOLID ? -_magnet_level_height : 0;
            height = 100;
            polygon([[0, top], [thumbscrew_diameter/2, top], [thumbscrew_diameter/2 + height, top-height], [0, top-height]]);
        }
    }
}

/**
 * Raw polygon for the male puzzle connector. (Note: Only one half)
 */
module puzzle_male_0() {
    scale(1/128*4) translate([-128, -128]) polygon(svg_path_puzzle_svg_male_tight * intersection_puzzle_fit + svg_path_puzzle_svg_male_loose * (1 - intersection_puzzle_fit));
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
    mirror([1, 0]) scale(1/128*4) translate([-128, -128]) polygon(svg_path_puzzle_svg_female_tight * intersection_puzzle_fit + svg_path_puzzle_svg_female_loose * (1 - intersection_puzzle_fit));
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
 * @Summary Prepare geometry for do_sweep, which sweeps a polygon along a path
 * @param polygon The polygon to sweep. Array of 2D points
 * @param path The path to sweep along. Array of 3D points
 * @return Geometry data to pass to do_sweep
 */
function prepare_sweep(polygon, path) = let(
    ring_faces = function (base_index) [
            for (i = [0:len(polygon)-1]) [
                base_index + (i + 1) % len(polygon), 
                base_index + len(polygon) + (i + 1) % len(polygon), 
                base_index + len(polygon) + i, 
                base_index + i
            ]
        ],
    points = [for (pt_path = path) each [for (pt_poly = polygon) pt_path + [pt_poly.x, pt_poly.y, 0]]],
    first_face = reverse([each [0:len(polygon)-1]]),
    last_face = [each [len(polygon)*(len(path)-1):len(polygon)*len(path)-1]],
    faces = [
        first_face,
        for (i = [0:len(path)-2]) each ring_faces(i * len(polygon)),
        last_face
    ]
) [points, faces];

/**
 * @Summary Display a sweep prepared by prepare_sweep
 * @param sweep The value returned by prepare_sweep
 */
module do_sweep(prep, convexity=2) {
    polyhedron(points = prep[0], faces = prep[1], convexity = convexity);
}

/**
 * @Summary Clip a polygon along an edge (one step of the Sutherland-Hodgman algorithm)
 * @param polygon The input polygon to clip
 * @param contains A lambda taking a single point that returns whether that point is clipped or not
 * @param find_intersection A lambda taking a point inside and outside the result area (in that order), that returns the point where the line between those points intersects the start of the clipping region
 * @return The clipped polygon, potentially with duplicate points
 */
function clip_polygon_edge(polygon, contains, find_intersection) = 
    [for (i = [0:len(polygon)-1]) let (
        here = polygon[i],
        prev = i == 0 ? polygon[len(polygon) - 1] : polygon[i - 1],
        here_inside = contains(here),
        prev_inside = contains(prev),
    ) each
        here_inside ?
            prev_inside ? [here] : [find_intersection(here, prev), here] :
            prev_inside ? [find_intersection(prev, here)] : []
    ];

/**
 * @Summary Clip a polygon using the Sutherland-Hodgman algorithm so that all resulting points satisfy `pt.x <= max.x && pt.y <= max.y`
 * @param polygon The polygon to clip
 * @param max The bounds to clip to
 * @return The clipped polygon, with no duplicate points
 */
function clip_polygon_max(polygon, max) = let(
    step = function(dimension, pg) clip_polygon_edge(pg, function (pt) pt[dimension] <= max[dimension], function (inside, outside) let (factor = (max[dimension] - inside[dimension]) / (outside[dimension] - inside[dimension])) inside + (outside - inside) * factor),
    clipped = step(0, step(1, polygon)),
    deduplicated = [for (i = 0, prev = clipped[len(clipped) - 1]; i < len(clipped); prev = clipped[i], i = i + 1) each clipped[i] == prev ? [] : [clipped[i]]]
) deduplicated;

// the maximum width of the baseplate profile (at the very bottom of the profile)
_baseplate_max_strength = _BASEPLATE_PROFILE[3].x;
// the full polygon of the baseplate profile
_baseplate_polygon = [
    [0, 0],
    for (pt = _BASEPLATE_PROFILE) pt + [-_baseplate_max_strength, 0]
];

_click1_polygon = let(shiftx = _baseplate_max_strength-click1_strength) [for (pt = clip_polygon_max([for (pt = _baseplate_polygon) [pt.x+shiftx, pt.y]], [0, click1_height])) [pt.x-shiftx, pt.y]];
/**
 * @Summary Logistic function used for the click1 arc
 * @param x coordinate
 */
function click1_path_base(x) = 1/(1+exp(-click1_steepness*x));
_click1_path = let (
    arc_length = (click1_outer_length - click1_inner_length) / 2,
    low = click1_path_base(-arc_length/2),
    high = click1_path_base(arc_length/2),
    scale = click1_distance / (high - low),
    arc = [for (x = [-arc_length/2:arc_length/click1_steps:arc_length/2]) [-(click1_path_base(x)-low)*scale, 0, x - (click1_outer_length-arc_length)/2]]
) [
    each arc,
    for (pt = reverse(arc)) [pt.x, pt.y, -pt.z]
];
_click1_sweep = prepare_sweep(_click1_polygon, _click1_path);

/**
 * @Summary Cumulate the entries of an array. e.g. [1, 1, 0.5] -> [0, 1, 2, 2.5]
 */
function cumulate(trace) =
    assert(is_list(trace))
    [for (i = 0, cumulated = 0; i <= len(trace); cumulated = cumulated + (i >= len(trace) ? 0 : assert(is_num(trace[i])) trace[i]), i = i + 1) cumulated];

/**
 * @Summary Get the position of a particular cell on one axis (1D)
 * @param dimension The cell dimension on this axis
 * @param size The segment size on this axis
 * @param trace The array of cell sizes on this axis
 * @param padding_start The start padding on this axis
 * @param index The index of this cell on this axis (may be < 0 or >= size also)
 */
function cell_axis_position(dimension, size, trace, padding_start, index) =
    let(
        cumulated = cumulate(trace),
        start_pos_norm = 
            index < 0 ? index : 
            index >= len(trace) ? cumulated[len(trace)] + (index - len(trace)) :
            cumulated[index],
        own_size_norm = index < 0 || index >= len(trace) ? 1 : trace[index],
        final = -size/2 + padding_start + (start_pos_norm + own_size_norm / 2) * dimension
    ) final;

/**
 * @Summary In the segment coordinate system, translate to the center of a particular cell
 * @param size The size of the segment
 * @param trace The cell sizes on each axis
 * @param padding The padding of the segment (for each edge)
 * @param index The index of the cell (can also be negative or >= count)
 */
module navigate_cell(size, trace, padding, index) {
    translate([
        cell_axis_position(BASEPLATE_DIMENSIONS.x, size.x, trace.x, padding[_WEST], index.x), 
        cell_axis_position(BASEPLATE_DIMENSIONS.y, size.y, trace.y, padding[_SOUTH], index.y)
    ]) children();
}

/**
 * @Summary In the segment coordinate system, translate to a corner of a particular cell
 * @param size The size of the segment
 * @param trace The cell sizes on each axis
 * @param padding The padding of the segment (for each edge)
 * @param index The index of the cell
 * @param diry The y direction of the corner (north or south)
 * @param dirx The x direction of the corner (east or west)
 */
module navigate_corner(size, trace, padding, index, diry, dirx) {
    assert(diry == _NORTH || diry == _SOUTH);
    assert(dirx == _EAST || dirx == _WEST);
    navigate_cell(size, trace, padding, index) translate([
        (dirx == _WEST ? -1 : 1) * BASEPLATE_DIMENSIONS.x * (index.x < 0 || index.x >= len(trace.x) ? 1 : trace.x[index.x]) / 2, 
        (diry == _SOUTH ? -1 : 1) * BASEPLATE_DIMENSIONS.y * (index.y < 0 || index.y >= len(trace.y) ? 1 : trace.y[index.y]) / 2
    ]) children();
}

/**
 * @Summary In the segment coordinate system, translate to an edge of a particular cell
 * @param size The size of the segment
 * @param trace The cell sizes on each axis
 * @param padding The padding of the segment (for each edge)
 * @param index The index of the cell
 * @param dir The edge to navigate to (N/E/S/W)
 */
module navigate_edge(size, trace, padding, index, dir) {
    navigate_cell(size, trace, padding, index) translate([
        (dir == _WEST ? -1 : dir == _EAST ? 1 : 0) * BASEPLATE_DIMENSIONS.x * (index.x < 0 || index.x >= len(trace.x) ? 1 : trace.x[index.x]) / 2,
        (dir == _SOUTH ? -1 : dir == _NORTH ? 1 : 0) * BASEPLATE_DIMENSIONS.y * (index.y < 0 || index.y >= len(trace.y) ? 1 : trace.y[index.y]) / 2
    ]) children();
}

/**
 * @Summary Draw the segment intersection connectors (2D)
 * @Details Draw all the segment connectors in 2D, once for the whole segment. 
 *          This is done in two passes (negative and positive): The negative
 *          pass cuts out room from the plate, and the positive pass adds the 
            tabs.
 * @param positive true if this is the positive pass
 * @param trace The cell sizes on each axis
 * @param size The size of the segment (incl. padding)
 * @param padding The padding of the segment (for each edge)
 * @param connector The connector configuration (for each edge)
 */
module segment_intersection_connectors(positive, trace, size, padding, connector) {
    last = [len(trace.x) - 1, len(trace.y) - 1];
    // for the normal case, we iterate over the cells at the edge of the segment, and add two half-connectors for each cell.
    for (ix = [0:1:last.x]) {
        // north and south connectors
        skip_first = ix == 0 && connector[_WEST];
        skip_last = ix == last.x && connector[_EAST];
        if (connector[_SOUTH]) {
            if (!skip_first) navigate_corner(size, trace, padding, [ix, 0], _SOUTH, _WEST) mirror([1, 0]) rotate([0, 0, -90]) puzzle_female(positive);
            if (!skip_last) navigate_corner(size, trace, padding, [ix, 0], _SOUTH, _EAST) rotate([0, 0, -90]) puzzle_female(positive);
        }
        if (connector[_NORTH]) {
            if (!skip_first) navigate_corner(size, trace, padding, [ix, last.y], _NORTH, _WEST) rotate([0, 0, 90]) puzzle_male(positive);
            if (!skip_last) navigate_corner(size, trace, padding, [ix, last.y], _NORTH, _EAST) mirror([1, 0]) rotate([0, 0, 90]) puzzle_male(positive);
        }
    }
    for (iy = [0:1:last.y]) {
        // east and west connectors
        if (connector[_WEST]) {
            navigate_corner(size, trace, padding, [0, iy], _SOUTH, _WEST) rotate([0, 0, 180]) puzzle_female(positive);
            navigate_corner(size, trace, padding, [0, iy], _NORTH, _WEST) mirror([0, 1]) rotate([0, 0, 180]) puzzle_female(positive);
        }
        if (connector[_EAST]) {
            navigate_corner(size, trace, padding, [last.x, iy], _SOUTH, _EAST) mirror([0, 1]) puzzle_male(positive);
            navigate_corner(size, trace, padding, [last.x, iy], _NORTH, _EAST) puzzle_male(positive);
        }
    }
    // At the corners of the segment, we now only have half-connectors. But if we have padding, there may be space for a full connector after all.
    // We add half-connectors at the corners and cut them to fit the plate.

    // Size includes plate wall. We don't want to interfere with that.
    calculate_plate_wall = function (side) connector[side] ? 0 : plate_wall_thickness[side];
    bounds_min = [
        -size.x/2 + calculate_plate_wall(_WEST),
        -size.y/2 + calculate_plate_wall(_SOUTH)
    ];
    bounds_max = [
        size.x/2 - calculate_plate_wall(_EAST),
        size.y/2 - calculate_plate_wall(_NORTH)
    ];
    intersection() {
        translate([bounds_min.x, -size.y/2 - 20]) square([bounds_max.x - bounds_min.x, size.y + 40]);
        union() {
            if (!connector[_WEST]) {
                if (connector[_SOUTH]) navigate_corner(size, trace, padding, [0, 0], _SOUTH, _WEST) rotate([0, 0, -90]) puzzle_female(positive);
                if (connector[_NORTH]) navigate_corner(size, trace, padding, [0, last.y], _NORTH, _WEST) mirror([1, 0]) rotate([0, 0, 90]) puzzle_male(positive);
            }
            if (!connector[_EAST]) {
                if (connector[_SOUTH]) navigate_corner(size, trace, padding, [last.x, 0], _SOUTH, _EAST) mirror([1, 0]) rotate([0, 0, -90]) puzzle_female(positive);
                if (connector[_NORTH]) navigate_corner(size, trace, padding, [last.x, last.y], _NORTH, _EAST) rotate([0, 0, 90]) puzzle_male(positive);
            }
        }
    }
    intersection() {
        translate([-size.x/2 - 20, bounds_min.y]) square([size.x + 40, bounds_max.y - bounds_min.y]);
        union() {
            if (!connector[_SOUTH]) {
                if (connector[_WEST]) navigate_corner(size, trace, padding, [0, 0], _SOUTH, _WEST) mirror([0, 1]) rotate([0, 0, 180]) puzzle_female(positive);
                if (connector[_EAST]) navigate_corner(size, trace, padding, [last.x, 0], _SOUTH, _EAST) puzzle_male(positive);
            }
            if (!connector[_NORTH]) {
                if (connector[_WEST]) navigate_corner(size, trace, padding, [0, last.y], _NORTH, _WEST) rotate([0, 0, 180]) puzzle_female(positive);
                if (connector[_EAST]) navigate_corner(size, trace, padding, [last.x, last.y], _NORTH, _EAST) mirror([0, 1]) puzzle_male(positive);
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
 * @param trace The cell sizes on each axis
 * @param size The size of the segment (incl. padding)
 * @param padding The padding of the segment (for each edge)
 * @param connector The connector configuration (for each edge)
 */
module segment_edge_connectors(positive, trace, size, padding, connector) {
    last = [len(trace.x) - 1, len(trace.y) - 1];
    for (ix = [0:1:last.x]) {
        if (connector[_SOUTH]) navigate_edge(size, trace, padding, [ix, 0], _SOUTH) edge_puzzle(positive, _edge_puzzle_direction_male[_SOUTH], trace.x[ix]);
        if (connector[_NORTH]) navigate_edge(size, trace, padding, [ix, last.y], _NORTH) mirror([0, 1]) edge_puzzle(positive, _edge_puzzle_direction_male[_NORTH], trace.x[ix]);
    }
    for (iy = [0:1:last.y]) {
        if (connector[_WEST]) navigate_edge(size, trace, padding, [0, iy], _WEST) mirror([1, 0]) rotate([0, 0, 90]) edge_puzzle(positive, _edge_puzzle_direction_male[_WEST], trace.y[iy]);
        if (connector[_EAST]) navigate_edge(size, trace, padding, [last.x, iy], _EAST) rotate([0, 0, 90]) edge_puzzle(positive, _edge_puzzle_direction_male[_EAST], trace.y[iy]);
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
 * @param size Size of this cell edge in grid units
 */
module edge_puzzle(positive, male, size) {
    count_here = size < 1 ? max(1, floor(edge_puzzle_count/2)) : edge_puzzle_count;
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
 * @Summary Draw a vertical screw at the current coordinate
 */
module vertical_screw() {
    // Additional space to clear above the screw. There shouldn't be anything here, but this guards against rounding errors
    clear_upwards = 0.01;
    rotate_extrude() {
        translate([0, -_extra_height]) square([vertical_screw_diameter/2, _total_height + clear_upwards]);
        translate([0, _profile_height - vertical_screw_counterbore_top.y]) {
            // counterbore
            square([vertical_screw_counterbore_top.x/2, vertical_screw_counterbore_top.y+clear_upwards]);
            // countersink
            polygon([
                [0, 0], 
                [0, clear_upwards], 
                [vertical_screw_countersink_top.x/2, clear_upwards], 
                [vertical_screw_countersink_top.x/2, 0], 
                [vertical_screw_diameter/2, -vertical_screw_countersink_top.y]
            ]);
        }
    }
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

function compute_segment_size(trace, padding) = [
    BASEPLATE_DIMENSIONS.x * cumulate(trace.x)[len(trace.x)] + padding[_EAST] + padding[_WEST],
    BASEPLATE_DIMENSIONS.y * cumulate(trace.y)[len(trace.y)] + padding[_NORTH] + padding[_SOUTH],
];

/**
 * @Summary Model a segment, which is piece of the plate without breaks
 * @param trace The cell sizes, in grid units, on each axis
 * @param padding The padding, for each side
 * @param connector Whether to add a connector, for each side
 * @param global_segment_index If applicable, the global index of this segment. This is used to emboss numbering
 * @param global_cell_index If applicable, the global cell index of this segment. This is used for vertical screws at plate corners
 * @param global_cell_count If applicable, the global cell count. This is used for vertical screws at plate corners
 */
module segment(trace=[[1], [1]], padding=[0, 0, 0, 0], connector=[false, false, false, false], global_segment_index=undef, global_cell_index=[0, 0], global_cell_count=[0, 0]) {
    size = compute_segment_size(trace, padding);
    _edge_puzzle_height_male = edge_puzzle_height_female - edge_puzzle_height_male_delta;
    // whether to cut the male edge puzzle connector to make room for the bin in the next cell. For really short connectors this is not necessary, but there's also no good reason to turn this off, so it's not user configurable at the moment
    _edge_puzzle_overlap = true;
    last = [len(trace.x)-1, len(trace.y)-1];
    difference() {
        union() {
            intersection() {
                translate([0, 0, -_extra_height]) linear_extrude(height = _total_height) difference() {
                    // basic plate with rounded corners
                    segment_rectangle(size, connector, include_wall=false);
                    if (connector_intersection_puzzle) {
                        segment_intersection_connectors(false, trace, size, padding, connector);
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
                    for (ix = [0:1:last.x]) for (iy = [0:1:last.y]) navigate_cell(size, trace, padding, [ix, iy]) {
                        cell_size = [trace.x[ix], trace.y[iy]];

                        seq_index = (iy + global_cell_index.y) * ceil(global_cell_count.x) + (ix + global_cell_index.x);
                        cell_style = len(cell_override) <= seq_index ? _CELL_STYLE_NORMAL : cell_override[seq_index];
                        if (cell_style == _CELL_STYLE_NORMAL) {
                            cell(cell_size, [
                                connector[_NORTH] && iy == last.y,
                                connector[_EAST] && ix == last.x,
                                connector[_SOUTH] && iy == 0,
                                connector[_WEST] && ix == 0
                            ]);
                        } else if (cell_style == _CELL_STYLE_EMPTY) {
                        } else if (cell_style == _CELL_STYLE_SOLID) {
                            dim = [BASEPLATE_DIMENSIONS.x * cell_size.x, BASEPLATE_DIMENSIONS.y * cell_size.y];
                            translate([-dim.x/2, -dim.y/2, -_extra_height]) cube([dim.x, dim.y, _total_height]);
                        } else {
                            assert(false, str("Unknown cell style: '", cell_style, "'"));
                        }
                    };
                };
            };

            if (plate_wall_thickness != [0,0,0,0]) translate([0, 0, -_extra_height-plate_wall_height[1]]) linear_extrude(_total_height + plate_wall_height[0] + plate_wall_height[1]) difference() {
                segment_rectangle(size, connector, include_wall=true);
                segment_rectangle(size, connector, include_wall=false);
            }
            
            if (connector_intersection_puzzle) translate([0, 0, -_extra_height]) linear_extrude(height = _total_height) segment_intersection_connectors(true, trace, size, padding, connector);
            if (connector_edge_puzzle) {
                intersection() {
                    translate([0, 0, -_extra_height]) linear_extrude(height = _extra_height+_edge_puzzle_height_male) segment_edge_connectors(true, trace, size, padding, connector);
                    if (_edge_puzzle_overlap) union() {
                        for (ix = [0:1:last.x]) {
                            if (connector[_SOUTH]) navigate_cell(size, trace, padding, [ix, -1]) cell([trace.x[ix], 1], positive=false);
                            if (connector[_NORTH]) navigate_cell(size, trace, padding, [ix, last.y+1]) cell([trace.x[ix], 1], positive=false);
                        }
                        for (iy = [0:1:last.y]) {
                            if (connector[_WEST]) navigate_cell(size, trace, padding, [-1, iy]) cell([1, trace.y[iy]], positive=false);
                            if (connector[_EAST]) navigate_cell(size, trace, padding, [last.x+1, iy]) cell([1, trace.y[iy]], positive=false);
                        }
                    }
                }
            }
        }
        if (connector_edge_puzzle) {
            translate([0, 0, -_extra_height]) linear_extrude(height = _extra_height+edge_puzzle_height_female) segment_edge_connectors(false, trace, size, padding, connector);
        }
        if (numbering && global_segment_index != undef) {
            squeeze = len(trace.x) <= 1;
            navigate_cell(size, trace, padding, [0, 0]) translate([BASEPLATE_DIMENSIONS.x*trace.x[0]/2-(squeeze?2.95/2:0), -BASEPLATE_DIMENSIONS.y/2+4, -_extra_height]) linear_extrude(number_depth) mirror([0, 1]) rotate([0, 0, 90]) text(str(global_segment_index + 1), size = squeeze ? number_squeeze_size : number_size, halign="right", valign = "center", font = number_font);
        }
        // extend a bit beyond the segment edges to make sure we cut any overhang
        extend = 10;
        if (bottom_chamfer[_SOUTH] > 0 && !connector[_SOUTH]) translate([-size.x/2 - extend, -size.y/2, -_extra_height]) rotate([0, 90, 0]) rotate([0, 0, 90]) linear_extrude(size.x + extend * 2) scale(bottom_chamfer[_SOUTH]) chamfer_triangle();
        if (bottom_chamfer[_WEST] > 0 && !connector[_WEST]) translate([-size.x/2, -size.y/2 - extend, -_extra_height]) rotate([-90, 0, 0]) rotate([0, 0, -90]) linear_extrude(size.y + extend * 2) scale(bottom_chamfer[_WEST]) chamfer_triangle();
        if (bottom_chamfer[_NORTH] > 0 && !connector[_NORTH]) translate([size.x/2 + extend, size.y/2, -_extra_height]) rotate([0, -90, 0]) rotate([0, 0, -90]) linear_extrude(size.x + extend * 2) scale(bottom_chamfer[_NORTH]) chamfer_triangle();
        if (bottom_chamfer[_EAST] > 0 && !connector[_EAST]) translate([size.x/2, size.y/2 + extend, -_extra_height]) rotate([90, 0, 0]) rotate([0, 0, 90]) linear_extrude(size.y + extend * 2) scale(bottom_chamfer[_EAST]) chamfer_triangle(); 
        if (top_chamfer[_SOUTH] > 0 && !connector[_SOUTH]) translate([-size.x/2 - extend, -size.y/2, _profile_height]) rotate([0, 90, 0]) linear_extrude(size.x + extend * 2) scale(top_chamfer[_SOUTH]) chamfer_triangle();
        if (top_chamfer[_WEST] > 0 && !connector[_WEST]) translate([-size.x/2, -size.y/2 - extend, _profile_height]) rotate([-90, 0, 0]) linear_extrude(size.y + extend * 2) scale(top_chamfer[_WEST]) chamfer_triangle();
        if (top_chamfer[_NORTH] > 0 && !connector[_NORTH]) translate([-size.x/2, size.y/2, _profile_height]) rotate([0, 90, 0]) rotate([0, 0, -90]) linear_extrude(size.x + extend * 2) scale(top_chamfer[_NORTH]) chamfer_triangle();
        if (top_chamfer[_EAST] > 0 && !connector[_EAST]) translate([size.x/2, size.y/2 + extend, _profile_height]) rotate([90, -90, 0]) rotate([0, 0, 90]) linear_extrude(size.y + extend * 2) scale(top_chamfer[_EAST]) chamfer_triangle(); 

        // vertical screw holes
        is_edge_axis = function (index, bounds, inset=0) (index == inset && index <= ceil(bounds - 0.25) - inset) || (index == ceil(bounds - 0.25) - inset && index >= inset);
        is_edge = function (index, bounds) is_edge_axis(index.x, bounds.x) || is_edge_axis(index.y, bounds.y);
        is_corner = function (index, bounds, inset) is_edge_axis(index.x, bounds.x, inset.x) && is_edge_axis(index.y, bounds.y, inset.y);
        for (ix = [0:1:last.x+1]) for (iy = [0:1:last.y+1]) navigate_corner(size, trace, padding, [ix, iy], _SOUTH, _WEST) {
            segment_index = [ix, iy];
            if (is_corner(segment_index + global_cell_index, global_cell_count, vertical_screw_plate_corner_inset)) {
                if (vertical_screw_plate_corners) vertical_screw();
            } else if (is_edge(segment_index + global_cell_index, global_cell_count)) {
                if (vertical_screw_plate_edges) vertical_screw();
            } else if (is_corner(segment_index, [len(trace.x), len(trace.y)], vertical_screw_segment_corner_inset)) {
                if (vertical_screw_segment_corners) vertical_screw();
            } else if (is_edge(segment_index, [len(trace.x), len(trace.y)])) {
                if (vertical_screw_segment_edges) vertical_screw();
            } else {
                if (vertical_screw_other) vertical_screw();
            }
        }
    }
}

/**
 * @Summary Calculate the minimum number of segments required to print this axis
 * @param trace The cell sizes on this axis
 * @param bed_norm The bed size, normalized by cell size
 * @param start_padding_norm The extra padding at the start of the axis, normalized by cell size
 * @param start_padding_norm The extra padding at the end of the axis, normalized by cell size
 */
function segments_per_axis(trace, bed_norm, start_padding_norm=0, end_padding_norm=0) = 
    let(
        index_assignments = [for (i = 0, segment_i = 0, segment_size = start_padding_norm; i < len(trace); begin_new = segment_size + trace[i] > bed_norm, segment_i = segment_i + (begin_new ? 1 : 0), segment_size = (begin_new ? 0 : segment_size) + trace[i], i = i + 1) [segment_i, segment_size]],
        last = index_assignments[len(trace) - 1],
        split_last = last[1] + trace[len(trace) - 1] + end_padding_norm > bed_norm
    ) last[0] + (split_last ? 2 : 1);

/**
 * @Summary Calculate an ideal axis plan.
 * @Details An ideal axis plan uses the fewest possible segments, and keeps segments roughly the same size.
 * @param trace The cell sizes on this axis
 * @param bed_norm The bed size, normalized by cell size
 * @param start_padding_norm The extra padding at the start of the axis, normalized by cell size
 * @param start_padding_norm The extra padding at the end of the axis, normalized by cell size
 * @return A vector containing the number of cells in each planned segment
 */
function plan_axis_ideal(trace, bed_norm, start_padding_norm=0, end_padding_norm=0) =
    let(
        cumulated = cumulate(trace),
        total_size = cumulated[len(trace)] + start_padding_norm + end_padding_norm,
        segment_count = segments_per_axis(trace, bed_norm, start_padding_norm, end_padding_norm),
        avg_segment_size = total_size / segment_count,
        // compute which segment each cell is assigned to
        assignments = [for (i = [0:len(trace) - 1]) let (
            center = cumulated[i] + trace[i] / 2 + start_padding_norm,
            norm_ix = center / avg_segment_size
        ) (norm_ix % 1) == 0 ? norm_ix - 1 : floor(norm_ix)]
    ) [for (i = [0:segment_count - 1]) len(search(i, assignments, num_returns_per_match=0))];

/**
 * @Summary Calculate an incremental axis plan.
 * @Details An incremental axis plan uses the maximum number of cells for each segment, and then sizes the final segment to contain the remaining cells.
 * @param trace The cell sizes on this axis
 * @param bed_norm The bed size, normalized by cell size
 * @param start_padding_norm The extra padding at the start of the axis, normalized by cell size
 * @param start_padding_norm The extra padding at the end of the axis, normalized by cell size
 * @param force_first If set, forcibly change the size of the first segment
 * @return A vector in the format: [start, mid, end], where the start is the number of cells in the first segment, end the number of cells in the last segment, and mid the number of cells in all other segments
 */
function plan_axis_incremental_vars(trace, bed_norm, start_padding_norm=0, end_padding_norm=0, force_first=undef) = 
    assert(bed_norm > 1)
    assert(start_padding_norm != undef)
    assert(end_padding_norm != undef)
    let (
        cumulated = cumulate(trace)
    )
    cumulated[len(trace)] + start_padding_norm + end_padding_norm <= bed_norm ? [len(trace), -1, -1] :
    let(
        // size of middle segments
        mid = floor(bed_norm),

        // for a given first segment size, compute the last segment size
        compute_end = function (first) let(e = (len(trace) - first) % mid) e == 0 ? mid : e,

        // make a preliminary first segement
        first_p = force_first == undef ? floor(bed_norm - start_padding_norm) : force_first,
        // make a preliminary end segment
        end_p = compute_end(first_p),
        // is the end segment too small, i.e. a single half-cell, or too big?
        shift = (end_p == 1 && trace[len(trace) - 1] < 1) || (cumulated[len(trace)] - cumulated[len(trace) - end_p] + end_padding_norm) > bed_norm,
        // if the end segment was too small, shrink the first segment a bit to give the end segment a better size
        first = shift ? first_p - 1 : first_p,
        // recalculate end segment size
        end = compute_end(first)
    ) [first, mid, end];

/**
 * @Summary Transform a short plan from plan_axis_incremental_vars into a full plan as returned by plan_axis_ideal
 * @return A vector containing the number of cells in each planned segment
 */
function vars_to_incremental(trace, vars) = let(
        axis_norm = len(trace),
        first = vars[0],
        mid = vars[1],
        end = vars[2]
    ) mid == -1 ? [first] : [for(i = 0, pos = 0; pos < axis_norm; i = i + 1, pos = first + mid * (i - 1)) 
        i == 0 ? first : pos + mid >= axis_norm ? end : mid];

/**
 * @Summary Score plan_b, assuming plan_a is fixed. Lower value is better
 */
function score_plan_b(plan_a, plan_b) =
    let(
        too_small_start = plan_b[0] == 1,
        too_small_end = plan_b[2] == 1,
        distance_start = abs(plan_a[0] - plan_b[0]),
        distance_end = abs(plan_a[2] - plan_b[2]),
        score = (too_small_start ? 20 : 0) + (too_small_end ? 20 : 0) - distance_start - distance_end
    ) score;

/**
 * @Summary Get the index of the lowest value in a vector
 */
function least_index(vec, start=0) =
    assert(len(vec) > start) len(vec) == start + 1 ? start : let(
        suggest = least_index(vec, start + 1)
    ) vec[suggest] > vec[start] ? start : suggest;

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
function plan_axis_staggered(trace, bed_norm, start_padding_norm=0, end_padding_norm=0) =
    assert(bed_norm > 1)
    assert(start_padding_norm != undef)
    assert(end_padding_norm != undef)
    let (
        // lambda: call plan_axis_incremental_vars with a specific shift
        plan_vars = function(force_first) plan_axis_incremental_vars(trace, bed_norm, start_padding_norm, end_padding_norm, force_first),
        // lambda: calculate the number of segments for a given set of plan_axis_incremental_vars
        plan_size = function(vars) vars[1] == -1 ? 1 : (len(trace) - vars[0] - vars[2]) / vars[1] + 2,
        // make a simple plan for the first column
        plan_a1 = plan_vars(y_row_count_first[0] <= 0 ? undef : y_row_count_first[0]),
        // if the last segment in the column is small, give that segment one more cell
        plan_a2 = plan_a1[1] == -1 || plan_a1[2] >= 2 || plan_a1[0] <= 2 ? plan_a1 : plan_vars(plan_a1[0] - 1)
    )
    // manual override
    y_row_count_first[1] > 0 ? [vars_to_incremental(trace, plan_a1), vars_to_incremental(trace, plan_vars(y_row_count_first[1]))] :
    // shortcut: if we don't need to split at all, or we can't change the split, we don't need to worry about staggering
    plan_a1[1] <= 1 ? [vars_to_incremental(trace, plan_a1), vars_to_incremental(trace, plan_a1)] : 
    let(
        // now, we determine the optimal shift of the second column.
        // first, plan with a minimum shift as a baseline.
        plan_b_shift1 = plan_vars(plan_a2[0] - 1),
        // then, iterate all possible shifts, until we hit one that requires an additional segment compared to plan_b_shift1
        // for each plan, compute the score using score_plan_b
        plan_b_shift = [for (
            // initialize with shift=1, and assign that to the best_size
            shift = 1, plan = plan_b_shift1, best_size = plan_size(plan); 
            // check that the current shift is still within best_size
            shift < plan_a2[0] && plan_size(plan) <= best_size; 
            // compute the next plan and shift
            shift = shift + 1, plan = plan_vars(plan_a2[0] - shift)
        ) score_plan_b(plan_a2, plan)],
        // pick the shift with the best score
        shift = least_index(plan_b_shift) + 1
    ) [vars_to_incremental(trace, plan_a2), vars_to_incremental(trace, plan_vars(plan_a2[0] - shift))];

/**
 * @Summary Calculate the sum of a vector's elements, up to the until index (exclusive)
 */
function sum_sub_vector(vector, until) = 
    [for (i = 0, sum = 0; i <= until; sum = (i == until ? undef : sum + vector[i]), i = i + 1) sum][until];

function slice(vector, start, length) = [for (i = [0:len(vector)]) each (i >= start && i < start + length) ? [vector[i]] : []];

function compute_global_trace_fraction(integer_fraction, length_norm) = let(
    scaled = floor(length_norm * integer_fraction),
    whole = floor(scaled / integer_fraction),
    part = scaled - whole * integer_fraction
) [for (i = [0:whole-1]) 1, for (i = [0:part-1]) 1/integer_fraction];

function compute_global_trace_dynamic(minimum_size_norm, length_norm) = let(
    dyn = length_norm % 1,
    expand_last = dyn < minimum_size_norm,
    total = floor(length_norm) + (expand_last ? 0 : 1)
) [for (i = [0:total-2]) 1, (length_norm % 1) + (expand_last ? 1 : 0)];

function compute_global_trace(algorithm, integer_fraction, minimum_size_norm, length_norm) = 
    algorithm == _FILLER_NONE ? [for (i = [0:floor(length_norm)-1]) 1] :
    algorithm == _FILLER_INTEGER ? compute_global_trace_fraction(integer_fraction, length_norm) :
    compute_global_trace_dynamic(minimum_size_norm, length_norm); 

module main() {
    global_trace = [
        compute_global_trace(filler_x, filler_fraction.x, filler_minimum_size.x/BASEPLATE_DIMENSIONS.x, plate_size.x/BASEPLATE_DIMENSIONS.x),
        compute_global_trace(filler_y, filler_fraction.y, filler_minimum_size.y/BASEPLATE_DIMENSIONS.y, plate_size.y/BASEPLATE_DIMENSIONS.y)
    ];
    global_trace_cumulated = [cumulate(global_trace.x), cumulate(global_trace.y)];
    plate_padding_sum = [
        plate_size.x - global_trace_cumulated.x[len(global_trace.x)] * BASEPLATE_DIMENSIONS.x,
        plate_size.y - global_trace_cumulated.y[len(global_trace.y)] * BASEPLATE_DIMENSIONS.y
    ];
    plate_padding = [
        plate_padding_sum.y * (1 - alignment.y), // NORTH
        plate_padding_sum.x * (1 - alignment.x), // EAST
        plate_padding_sum.y * alignment.y, // SOUTH
        plate_padding_sum.x * alignment.x, // WEST
    ] + edge_adjust + plate_wall_thickness;
    // keep some margin on the edge of the bed clear for the connectors
    connector_margin = max(connector_intersection_puzzle ? 3.5 : 0, connector_edge_puzzle ? edge_puzzle_dim_c.y + edge_puzzle_dim.y : 0);
    bed_norm = [
        (bed_size.x - connector_margin)/BASEPLATE_DIMENSIONS.x,
        (bed_size.y - connector_margin)/BASEPLATE_DIMENSIONS.y
    ];
    start_padding_norm = [
        plate_padding[_WEST]/BASEPLATE_DIMENSIONS.x,
        plate_padding[_SOUTH]/BASEPLATE_DIMENSIONS.y
    ];
    end_padding_norm = [
        plate_padding[_EAST]/BASEPLATE_DIMENSIONS.x,
        plate_padding[_NORTH]/BASEPLATE_DIMENSIONS.y
    ];
    // for the x axis, we only need a single plan, so we can use the ideal algorithm.
    plan_x = x_segment_algorithm == _SEGMENT_ALGORITHM_IDEAL ? 
        plan_axis_ideal(global_trace.x, bed_norm=bed_norm.x, start_padding_norm=start_padding_norm.x, end_padding_norm=end_padding_norm.x) :
        vars_to_incremental(global_trace.x, plan_axis_incremental_vars(global_trace.x, bed_norm=bed_norm.x, start_padding_norm=start_padding_norm.x, end_padding_norm=end_padding_norm.x, force_first=x_column_count_first == 0 ? undef : x_column_count_first));
    // for the y axis, we need to avoid 4-way gap intersections, so we need two plans.
    plans_y = plan_axis_staggered(global_trace.y, bed_norm=bed_norm.y, start_padding_norm=start_padding_norm.y, end_padding_norm=end_padding_norm.y);
    plan_x_cumulate = cumulate(plan_x);
    for (segix = [0:len(plan_x) - 1]) {
        plan_y = plans_y[segix % 2];
        plan_y_cumulate = cumulate(plan_y);
        // Compute size of full plate model including segment gaps. We need to do this inside the loop because it changes depending on plan_y
        all_size = [
            plate_padding[_WEST] + plate_padding[_EAST] + global_trace_cumulated.x[len(global_trace.x)] * BASEPLATE_DIMENSIONS.x + (len(plan_x) - 1) * _segment_gap,
            plate_padding[_SOUTH] + plate_padding[_NORTH] + global_trace_cumulated.y[len(global_trace.y)] * BASEPLATE_DIMENSIONS.y + (len(plan_y) - 1) * _segment_gap
        ];
        for (segiy = [0:len(plan_y) - 1]) {
            segment_padding = [
                segiy == len(plan_y) - 1 ? plate_padding[_NORTH] : 0,
                segix == len(plan_x) - 1 ? plate_padding[_EAST] : 0,
                segiy == 0 ? plate_padding[_SOUTH] : 0,
                segix == 0 ? plate_padding[_WEST] : 0,
            ];
            cells_cumulated_before = [
                global_trace_cumulated.x[plan_x_cumulate[segix]],
                global_trace_cumulated.y[plan_y_cumulate[segiy]]
            ];
            cells_cumulated_after = [
                global_trace_cumulated.x[plan_x_cumulate[segix+1]],
                global_trace_cumulated.y[plan_y_cumulate[segiy+1]]
            ];
            translate([
                -all_size.x/2 + (cells_cumulated_after.x+cells_cumulated_before.x)/2 * BASEPLATE_DIMENSIONS.x + (segix != 0 ? plate_padding[_WEST] : 0) + (segment_padding[_WEST] + segment_padding[_EAST]) / 2 + segix * _segment_gap,
                -all_size.y/2 + (cells_cumulated_after.y+cells_cumulated_before.y)/2 * BASEPLATE_DIMENSIONS.y + (segiy != 0 ? plate_padding[_SOUTH] : 0) + (segment_padding[_NORTH] + segment_padding[_SOUTH]) / 2 + segiy * _segment_gap
            ]) segment(trace=[
                slice(global_trace.x, plan_x_cumulate[segix], plan_x[segix]),
                slice(global_trace.y, plan_y_cumulate[segiy], plan_y[segiy])
            ], padding=segment_padding, connector=[
                segiy != len(plan_y) - 1,
                segix != len(plan_x) - 1,
                segiy != 0,
                segix != 0
            ], global_segment_index=segiy + ceil(segix / 2) * len(plans_y[0]) + floor(segix / 2) * len(plans_y[1]),
            global_cell_index=[sum_sub_vector(plan_x, segix), sum_sub_vector(plan_y, segiy)],
            global_cell_count=[len(global_trace.x), len(global_trace.y)]);
        }
    }
}

module test_pattern_padding() {
    translate([30, 30]) segment(trace = [[1], [1]], padding=[5, 0, 0, 0], connector = [false, true, false, true]);
    translate([-30, 30]) segment(trace = [[1], [1]], padding=[0, 5, 0, 0], connector = [true, false, true, false]);
    translate([30, -30]) segment(trace = [[1], [1]], padding=[0, 0, 5, 0], connector = [false, true, false, true]);
    translate([-30, -30]) segment(trace = [[1], [1]], padding=[0, 0, 0, 5], connector = [true, false, true, false]);
}

module test_pattern_half() {
    segment(trace = [[1, 0.5], [1, 0.5]], connector = [true, true, true, true]);
}

module test_pattern_numbering() {
    translate([0, 30]) segment(trace = [[1, 1], [1]], connector = [true, true, true, true], global_segment_index = 11);
    translate([30, -30]) segment(trace = [[0.5], [1]], connector = [true, true, true, true], global_segment_index = 12);
    translate([-30, -30]) segment(trace = [[1], [1]], connector = [true, true, true, true], global_segment_index = 12);
}

module test_pattern_wall() {
    segment(trace = [[1, 1], [1, 1]], connector=[false, false, false, false], padding=[5, 5, 5, 5]);
}

module test_pattern_click() {
    trace = [[1], [1, 1, 1]];
    // this should give similar wall strength as a neighbouring cell
    padding = [12, click1_wall_strength, click1_wall_strength, click1_wall_strength];
    segment(trace = trace, connector=[false, false, false, false], padding=padding);
    format_small = function (d) d < 1 ? str(".", d*10) : (d % 1) == 0 ? str(d) : str(d * 10);
    txt = click1 ? str(format_small(click1_distance), "|", format_small(click1_steepness), "|", format_small(click1_height), "|", format_small(click1_strength), "|", format_small(click1_wall_strength)) : "off";
    navigate_edge(size = compute_segment_size(trace, padding), trace = trace, padding = padding, index = [0, 2], dir = _NORTH) 
        translate([0, padding[_NORTH]/2, _profile_height]) 
        linear_extrude(0.5) 
        scale([0.7, 1]) text(txt, halign="center", valign="center", size=8);
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
} else if (test_pattern == 5) {
    test_pattern_click();
}
