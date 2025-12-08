#!/usr/bin/env python3
"""
Add obj_dc (identity encoding) properties to a vanilla Gaussian Splatting PLY.
This allows you to use a pre-trained GS model as initialization for Gaussian Grouping.
"""

import numpy as np
from plyfile import PlyData, PlyElement
import argparse
import os

def add_obj_dc_to_ply(input_path, output_path, num_objects=16):
    """
    Add obj_dc_0 through obj_dc_15 properties to a PLY file.
    
    Args:
        input_path: Path to input PLY (vanilla Gaussian Splatting)
        output_path: Path to output PLY (with obj_dc added)
        num_objects: Number of obj_dc dimensions (default 16)
    """
    print(f"Loading PLY from {input_path}")
    plydata = PlyData.read(input_path)
    
    # Get existing properties
    vertex_data = plydata.elements[0]
    num_vertices = vertex_data.count
    
    print(f"Found {num_vertices} Gaussians")
    print(f"Existing properties: {[p.name for p in vertex_data.properties]}")
    
    # Check if obj_dc already exists
    if any('obj_dc' in p.name for p in vertex_data.properties):
        print("Warning: obj_dc properties already exist! Skipping.")
        return
    
    # Extract all existing data
    dtype_full = [(p.name, p.val_dtype) for p in vertex_data.properties]
    
    # Add obj_dc properties
    for i in range(num_objects):
        dtype_full.append((f'obj_dc_{i}', 'f4'))
    
    print(f"Adding {num_objects} obj_dc properties (obj_dc_0 to obj_dc_{num_objects-1})")
    
    # Create new element array
    elements_new = np.empty(num_vertices, dtype=dtype_full)
    
    # Copy existing properties
    for prop in vertex_data.properties:
        elements_new[prop.name] = vertex_data[prop.name]
    
    # Initialize obj_dc to small random values (like GG does)
    # This gives each Gaussian a unique initial identity
    for i in range(num_objects):
        elements_new[f'obj_dc_{i}'] = np.random.randn(num_vertices).astype(np.float32) * 0.01
    
    # Create new PLY
    vertex_element = PlyElement.describe(elements_new, 'vertex')
    
    # Save
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    PlyData([vertex_element]).write(output_path)
    
    print(f"\nSuccessfully saved to {output_path}")
    print(f"New properties: {[p.name for p in vertex_element.properties]}")
    print(f"\nYou can now use this PLY to initialize Gaussian Grouping training:")
    print(f"  1. Copy to: data/mcity/sparse/0/points3D.ply")
    print(f"  2. Train: python train.py -s data/mcity --model_path output/mcity_gg")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Add obj_dc properties to vanilla Gaussian Splatting PLY")
    parser.add_argument("--input", "-i", type=str, required=True,
                        help="Input PLY file (vanilla Gaussian Splatting)")
    parser.add_argument("--output", "-o", type=str, required=True,
                        help="Output PLY file (with obj_dc added)")
    parser.add_argument("--num_objects", type=int, default=16,
                        help="Number of obj_dc dimensions (default: 16)")
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input):
        print(f"Error: Input file not found: {args.input}")
        exit(1)
    
    add_obj_dc_to_ply(args.input, args.output, args.num_objects)
