#!/usr/bin/env python3
"""
Convert SAM masks from [0, 127, 255] to [0, 1, 2] object IDs.
Gaussian Grouping expects integer class labels, not normalized floats.
"""

import os
import numpy as np
from PIL import Image
from tqdm import tqdm
import argparse

def fix_mask_values(input_dir, output_dir=None, dry_run=False):
    """
    Convert mask values [0, 127, 255] to [0, 1, 2].
    
    Args:
        input_dir: Directory with masks (e.g., data/mcity/object_mask)
        output_dir: Output directory (default: overwrite input)
        dry_run: If True, just show what would be done
    """
    if output_dir is None:
        output_dir = input_dir
    
    # Find all PNG mask files
    mask_files = []
    for root, dirs, files in os.walk(input_dir):
        for file in files:
            if file.endswith('.png'):
                mask_files.append(os.path.join(root, file))
    
    print(f"Found {len(mask_files)} mask files")
    
    # Check first file
    if mask_files:
        test_img = np.array(Image.open(mask_files[0]))
        unique_vals = np.unique(test_img)
        print(f"Sample mask values: {unique_vals}")
        
        if set(unique_vals) == {0, 1, 2}:
            print("✓ Masks already have correct values [0, 1, 2]!")
            return
        elif set(unique_vals) == {0, 127, 255}:
            print("✗ Masks have wrong values [0, 127, 255], fixing...")
        else:
            print(f"⚠ Unexpected mask values: {unique_vals}")
    
    if dry_run:
        print("DRY RUN - no files will be modified")
        return
    
    # Convert all masks
    for mask_path in tqdm(mask_files, desc="Converting masks"):
        # Load mask
        img = Image.open(mask_path)
        arr = np.array(img)
        
        # Map 0→0, 127→1, 255→2
        arr_fixed = np.zeros_like(arr)
        arr_fixed[arr == 127] = 1
        arr_fixed[arr == 255] = 2
        
        # Save
        rel_path = os.path.relpath(mask_path, input_dir)
        out_path = os.path.join(output_dir, rel_path)
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        
        Image.fromarray(arr_fixed.astype(np.uint8)).save(out_path)
    
    print(f"✓ Converted {len(mask_files)} masks")
    print(f"  Mapping: 0→0, 127→1, 255→2")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Fix SAM mask values for Gaussian Grouping")
    parser.add_argument("--input", "-i", type=str, required=True,
                        help="Input mask directory (e.g., data/mcity/object_mask)")
    parser.add_argument("--output", "-o", type=str, default=None,
                        help="Output directory (default: overwrite input)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Check masks without modifying")
    
    args = parser.parse_args()
    fix_mask_values(args.input, args.output, args.dry_run)
