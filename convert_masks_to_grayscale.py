#!/usr/bin/env python3
"""Convert RGB masks to grayscale for Gaussian Grouping training."""

import os
from PIL import Image
import numpy as np
from tqdm import tqdm
from pathlib import Path

def convert_rgb_to_grayscale(mask_dir):
    """Convert all RGB PNG masks to grayscale in place."""
    mask_files = list(Path(mask_dir).rglob("*.png"))
    
    print(f"Found {len(mask_files)} mask files to convert")
    
    for mask_path in tqdm(mask_files, desc="Converting masks"):
        try:
            # Load image
            img = Image.open(mask_path)
            
            # Check if it's RGB
            if img.mode == 'RGB':
                # Convert to grayscale using the first channel
                # (assuming all channels have same mask data)
                arr = np.array(img)
                gray = arr[:, :, 0]  # Take first channel
                
                # Save as grayscale
                gray_img = Image.fromarray(gray, mode='L')
                gray_img.save(mask_path)
            elif img.mode != 'L':
                print(f"Warning: {mask_path} has mode {img.mode}, converting to L")
                img.convert('L').save(mask_path)
                
        except Exception as e:
            print(f"Error processing {mask_path}: {e}")
    
    print("✓ Conversion complete!")

if __name__ == "__main__":
    mask_dir = "data/mcity/object_mask"
    convert_rgb_to_grayscale(mask_dir)
