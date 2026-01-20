
# extract paths from an svg and save them as openscad

import svgelements
import sys

in_name = sys.argv[1]
with open(sys.argv[1]) as f:
    svg = svgelements.SVG.parse(f)

scad = ""
for path in svg:
    if type(path) is not svgelements.Path:
        continue
    polygon = []
    for segment in path:
        if type(segment) is svgelements.CubicBezier:
            assert(segment.start == segment.control1)
            assert(segment.end == segment.control2)
            polygon.append(segment.end)
        elif type(segment) is svgelements.Move:
            polygon.append(segment.end)
        elif type(segment) is svgelements.Line:
            polygon.append(segment.end)
        elif type(segment) is svgelements.Close:
            pass
        else:
            print("Unknown path segment type " + str(type(segment)))
    path_id = path.values["attributes"]["id"]
    scad += "svg_path_" + in_name.replace(".", "_") + "_" + path_id + " = [" + ",".join(map(lambda p: f"[{p.x}, {p.y}]", polygon)) + "];\n";
    print(f"Extracted path '{path_id}' from {in_name}")

out_name = sys.argv[2]
with open(out_name, "w") as f:
    f.write(scad)