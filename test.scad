use <gridflock.scad>

module assert_eq(expected, actual) {
    if (expected != actual) {
        echo(str("Expected: ", expected));
        echo(str("Actual: ", actual));
        assert(expected == actual);
    }
}

assert_eq([0, 1, 2], cumulate([1, 1]));
assert_eq([0, 0.5, 1.5], cumulate([0.5, 1]));

assert_eq(1, segments_per_axis([1], 3));
assert_eq(1, segments_per_axis([1, 1, 1], 3));
assert_eq(2, segments_per_axis([1, 1, 1, 1], 3));
assert_eq(2, segments_per_axis([1, 1, 1.2], 3));
assert_eq(2, segments_per_axis([1, 1, 1], 3, start_padding_norm=0.1));
assert_eq(2, segments_per_axis([1, 1, 1], 3, end_padding_norm=0.1));
assert_eq(3, segments_per_axis([1, 1, 1, 1, 1, 1, 1], 3));
assert_eq(3, segments_per_axis([1, 1, 1, 1, 1, 1.2], 3));
assert_eq(3, segments_per_axis([1, 1, 1, 1, 1, 1], 3, start_padding_norm=0.1));
assert_eq(3, segments_per_axis([1, 1, 1, 1, 1, 1], 3, end_padding_norm=0.1));

assert_eq([1], plan_axis_ideal([1], 3));
assert_eq([3], plan_axis_ideal([1, 1, 1], 3));
assert_eq([2, 2], plan_axis_ideal([1, 1, 1, 1], 3));
assert_eq([3, 2], plan_axis_ideal([1, 1, 1, 1, 1], 3));

function singles(n) = [for (i = [1:n]) 1];

assert_eq([[1], [1]], plan_axis_staggered(singles(1), 5));
assert_eq([[2], [2]], plan_axis_staggered(singles(2), 5));
assert_eq([[3], [3]], plan_axis_staggered(singles(3), 5));
assert_eq([[4], [4]], plan_axis_staggered(singles(4), 5));
assert_eq([[5], [5]], plan_axis_staggered(singles(5), 5));
assert_eq([[4, 2], [2, 4]], plan_axis_staggered(singles(6), 5));
assert_eq([[5, 2], [2, 5]], plan_axis_staggered(singles(7), 5));
assert_eq([[5, 3], [3, 5]], plan_axis_staggered(singles(8), 5));
assert_eq([[5, 4], [4, 5]], plan_axis_staggered(singles(9), 5));
assert_eq([[5, 5], [2, 5, 3]], plan_axis_staggered(singles(10), 5));
assert_eq([[4, 5, 2], [2, 5, 4]], plan_axis_staggered(singles(11), 5));
assert_eq([[5, 5], [2, 6, 2]], plan_axis_staggered(singles(10), bed_norm=6.0119, start_padding_norm=0.357143, end_padding_norm=0.357143));

assert_eq([5, 6, 5], plan_axis_incremental_vars(trace=singles(10), bed_norm=6.1, start_padding_norm=0.2, end_padding_norm=0.2));
assert_eq([3, 6, 1], plan_axis_incremental_vars(trace=singles(10), bed_norm=6.1, start_padding_norm=0.2, end_padding_norm=0.2, force_first=4));
assert_eq([3, 6, 1], plan_axis_incremental_vars(trace=singles(10), bed_norm=6.1, start_padding_norm=0.2, end_padding_norm=0.2, force_first=3));
assert_eq([2, 6, 2], plan_axis_incremental_vars(trace=singles(10), bed_norm=6.1, start_padding_norm=0.2, end_padding_norm=0.2, force_first=2));
assert_eq([1, 6, 3], plan_axis_incremental_vars(trace=singles(10), bed_norm=6.1, start_padding_norm=0.2, end_padding_norm=0.2, force_first=1));

assert_eq([2, -1, -1], plan_axis_incremental_vars(trace=[1, 0.5], bed_norm=2));
assert_eq([1, 2, 2], plan_axis_incremental_vars(trace=[1, 1, 0.5], bed_norm=2));

assert_eq([[0, 1], [0, 0], [1, 0], [1, 1]], clip_polygon_max([[0, 0], [2, 0], [0, 2]], [1, 1]));
assert_eq([[1, 1], [0, 1], [0, 0], [1, 0]], clip_polygon_max([[0, 2], [0, 0], [2, 0]], [1, 1]));
assert_eq([[1, 0], [1, 1], [0, 1], [0, 0]], clip_polygon_max([[2, 0], [0, 2], [0, 0]], [1, 1]));

// _FILLER_NONE
assert_eq([1], compute_global_trace(0, 2, 0.25, 1.5));

// _FILLER_INTEGER
assert_eq([1, 0.5], compute_global_trace(1, 2, 0.25, 1.5));
assert_eq([1, 0.5], compute_global_trace(1, 2, 0.25, 1.6));
assert_eq([1], compute_global_trace(1, 2, 0.25, 1.4));

// _FILLER_DYNAMIC
// values chosen carefully to avoid FP errors
assert_eq([1], compute_global_trace(2, 2, 0.25, 1));
assert_eq([1.125], compute_global_trace(2, 2, 0.25, 1.125));
assert_eq([1, 0.25], compute_global_trace(2, 2, 0.25, 1.25));
assert_eq([1, 0.5], compute_global_trace(2, 2, 0.25, 1.5));

cube([1, 1, 1]);
