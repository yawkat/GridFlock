gs = 42;
total_frames = 1000;
frame_index = round($t * total_frames);
include <../gridflock.scad>
bed_size = [gs * 3 + 10, gs * 3 + 10];
plate_size = [gs * 3, gs * 3];
magnets = frame_index != 2;
magnet_style = frame_index == 0 ? 0 : 1;