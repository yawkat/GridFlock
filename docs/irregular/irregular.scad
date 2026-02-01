gs = 42;
mode = 0;
plate_size_min = [gs, gs];
include <../../gridflock.scad>
bed_size = [1000, 1000];
plate_size = [gs * 5, gs * 7];
cell_override = mode == 3 ? "sssssscccsssccsssccsssccssscsssssss" : "";
test_pattern = -1; // prevent rendering outside intersection
magnets = false;

if (mode == 0) {
    main();
} else {
    intersection() {
        if (mode >= 2) main();
        linear_extrude(mode < 2 ? 1 : 100) scale(2) translate([-120, -170]) import("curve.svg");
    }
}
