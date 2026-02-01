gs = 42;
plate_size_min = [gs, gs];
plate_size_max = [gs * 3, gs * 3];
total_frames = 1000;
ex_t = abs($t*2 - 1);
ps = gs * 2.4 * ex_t + gs + 1;
include <../gridflock.scad>
bed_size = [1000, 1000];
plate_size = [ps, ps];
_segment_gap = 20;

echo("Plate Size: ", plate_size/gs);