gs = 42;
plate_size_min = [gs, gs];
plate_size_max = [gs * 6, gs * 6];
total_frames = 1000;
ex_t = ($t*total_frames)/(total_frames-1);
include <../gridflock.scad>
bed_size = [gs * 3 + 10, gs * 3 + 10];
plate_size = [
        ex_t < 0.5 ? (plate_size_max.x - plate_size_min.x) * ex_t * 2 + plate_size_min.x : plate_size_max.x,
        ex_t < 0.5 ? plate_size_min.y : (plate_size_max.y - plate_size_min.y) * (ex_t * 2 - 1) + plate_size_min.y
] + [1, 1];
_segment_gap = 20;

echo("Plate Size: ", plate_size/gs);