#!/usr/bin/env python3
"""
Create a subset of the Mcity dataset that preserves multi-view synchronization.
For 3D reconstruction, we need all 6 camera views (camera_0/_0,_1,_2 + camera_1/_0,_1,_2)
for each timestamp to maintain spatial coverage.
"""

import os
import sys
import shutil
from collections import defaultdict
from pathlib import Path

def extract_timestamp(filename):
    """Extract timestamp from filename like '1758662704.529435_0.jpg'"""
    basename = os.path.basename(filename)
    timestamp = basename.split('_')[0]  # Get part before _0, _1, or _2
    return timestamp

def group_by_timestamp(image_dir):
    """Group all images by timestamp, showing which camera views exist"""
    timestamp_groups = defaultdict(lambda: {'camera_0': [], 'camera_1': []})
    
    for subdir in ['K1/camera_0', 'K1/camera_1']:
        full_path = os.path.join(image_dir, subdir)
        if not os.path.exists(full_path):
            continue
            
        for img_file in os.listdir(full_path):
            if not img_file.endswith('.jpg'):
                continue
            timestamp = extract_timestamp(img_file)
            camera_key = 'camera_0' if 'camera_0' in subdir else 'camera_1'
            timestamp_groups[timestamp][camera_key].append(os.path.join(subdir, img_file))
    
    return timestamp_groups

def create_subset(source_dir, target_dir, num_timestamps=10):
    """
    Create a subset with N timestamps (each timestamp = 6 images total).
    
    Args:
        source_dir: Path to mcity dataset (contains images/, object_mask/, sparse/)
        target_dir: Path to new subset dataset
        num_timestamps: Number of timestamp groups to include
    """
    image_dir = os.path.join(source_dir, 'images')
    mask_dir = os.path.join(source_dir, 'object_mask')
    
    print(f"Analyzing {image_dir}...")
    timestamp_groups = group_by_timestamp(image_dir)
    
    # Filter to complete groups (have all 6 views)
    complete_groups = {}
    for timestamp, views in timestamp_groups.items():
        if len(views['camera_0']) == 3 and len(views['camera_1']) == 3:
            complete_groups[timestamp] = views
    
    print(f"Found {len(complete_groups)} complete timestamp groups (6 views each)")
    print(f"Total potential images: {len(complete_groups) * 6}")
    
    # Select subset
    selected_timestamps = sorted(complete_groups.keys())[:num_timestamps]
    print(f"\nCreating subset with {num_timestamps} timestamps = {num_timestamps * 6} images")
    
    # Create directory structure
    for subdir in ['images/K1/camera_0', 'images/K1/camera_1', 
                   'object_mask/K1/camera_0', 'object_mask/K1/camera_1',
                   'sparse/0']:
        os.makedirs(os.path.join(target_dir, subdir), exist_ok=True)
    
    # Copy files
    copied_images = 0
    copied_masks = 0
    
    for timestamp in selected_timestamps:
        views = complete_groups[timestamp]
        
        # Copy all 6 views for this timestamp
        for camera_key in ['camera_0', 'camera_1']:
            for img_path in views[camera_key]:
                # Copy image
                src_img = os.path.join(image_dir, img_path)
                dst_img = os.path.join(target_dir, 'images', img_path)
                shutil.copy2(src_img, dst_img)
                copied_images += 1
                
                # Copy corresponding mask (same filename but .png)
                mask_filename = os.path.splitext(os.path.basename(img_path))[0] + '.png'
                mask_subpath = os.path.join(os.path.dirname(img_path), mask_filename)
                src_mask = os.path.join(mask_dir, mask_subpath)
                dst_mask = os.path.join(target_dir, 'object_mask', mask_subpath)
                
                if os.path.exists(src_mask):
                    shutil.copy2(src_mask, dst_mask)
                    copied_masks += 1
                else:
                    print(f"Warning: Mask not found for {img_path}")
    
    # Copy COLMAP sparse reconstruction
    for colmap_file in ['cameras.bin', 'images.bin', 'points3D.bin']:
        src = os.path.join(source_dir, 'sparse/0', colmap_file)
        dst = os.path.join(target_dir, 'sparse/0', colmap_file)
        if os.path.exists(src):
            shutil.copy2(src, dst)
            print(f"Copied {colmap_file}")
    
    print(f"\n✅ Subset created successfully!")
    print(f"   Images: {copied_images}")
    print(f"   Masks: {copied_masks}")
    print(f"   Location: {target_dir}")
    print(f"\n   Each timestamp has 6 synchronized views for proper 3D reconstruction")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python create_synchronized_subset.py <num_timestamps>")
        print("Example: python create_synchronized_subset.py 10  # Creates 60-image subset")
        sys.exit(1)
    
    num_timestamps = int(sys.argv[1])
    num_images = num_timestamps * 6
    
    source_dir = "/home/chabeck/gaussian-grouping/data/mcity"
    target_dir = f"/home/chabeck/gaussian-grouping/data/mcity_sync_{num_images}"
    
    if os.path.exists(target_dir):
        response = input(f"{target_dir} exists. Overwrite? (y/n): ")
        if response.lower() != 'y':
            print("Aborted.")
            sys.exit(0)
        shutil.rmtree(target_dir)
    
    create_subset(source_dir, target_dir, num_timestamps)
