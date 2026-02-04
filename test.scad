use <gridflock.scad>

module assert_eq(expected, actual) {
    if (expected != actual) {
        echo(str("Expected: ", expected));
        echo(str("Actual: ", actual));
        assert(expected == actual);
    }
}

assert_eq([[1], [1]], plan_axis_staggered(1, 5));
assert_eq([[2], [2]], plan_axis_staggered(2, 5));
assert_eq([[3], [3]], plan_axis_staggered(3, 5));
assert_eq([[4], [4]], plan_axis_staggered(4, 5));
assert_eq([[5], [5]], plan_axis_staggered(5, 5));
assert_eq([[4, 2], [2, 4]], plan_axis_staggered(6, 5));
assert_eq([[5, 2], [2, 5]], plan_axis_staggered(7, 5));
assert_eq([[5, 3], [3, 5]], plan_axis_staggered(8, 5));
assert_eq([[5, 4], [4, 5]], plan_axis_staggered(9, 5));
assert_eq([[5, 5], [2, 5, 3]], plan_axis_staggered(10, 5));
assert_eq([[4, 5, 2], [2, 5, 4]], plan_axis_staggered(11, 5));
assert_eq([[5, 5], [2, 6, 2]], plan_axis_staggered(axis_norm=10, bed_norm=6.0119, start_padding_norm=0.357143, end_padding_norm=0.357143));
assert_eq([5, 6, 5], plan_axis_incremental_vars(axis_norm=10, bed_norm=6.1, start_padding_norm=0.2, end_padding_norm=0.2));
assert_eq([3, 6, 1], plan_axis_incremental_vars(axis_norm=10, bed_norm=6.1, start_padding_norm=0.2, end_padding_norm=0.2, force_first=4));
assert_eq([3, 6, 1], plan_axis_incremental_vars(axis_norm=10, bed_norm=6.1, start_padding_norm=0.2, end_padding_norm=0.2, force_first=3));
assert_eq([2, 6, 2], plan_axis_incremental_vars(axis_norm=10, bed_norm=6.1, start_padding_norm=0.2, end_padding_norm=0.2, force_first=2));
assert_eq([1, 6, 3], plan_axis_incremental_vars(axis_norm=10, bed_norm=6.1, start_padding_norm=0.2, end_padding_norm=0.2, force_first=1));

cube([1, 1, 1]);
