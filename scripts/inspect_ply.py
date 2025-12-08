from plyfile import PlyData
import sys

def inspect_ply(path):
    plydata = PlyData.read(path)
    properties = [p.name for p in plydata.elements[0].properties]
    f_rest_props = [p for p in properties if p.startswith("f_rest_")]
    print(f"Total properties: {len(properties)}")
    print(f"f_rest properties: {len(f_rest_props)}")
    print(f"First few f_rest: {f_rest_props[:5]}")
    print(f"Last few f_rest: {f_rest_props[-5:]}")

if __name__ == "__main__":
    inspect_ply(sys.argv[1])
