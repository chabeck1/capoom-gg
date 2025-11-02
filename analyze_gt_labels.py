#!/usr/bin/env python3
"""
Analyze ground truth object labels from the bear dataset
Shows which object IDs appear in how many frames
"""

from PIL import Image
import numpy as np
from pathlib import Path
from collections import defaultdict

# Count object occurrences across all frames
object_counts = defaultdict(int)
object_pixel_counts = defaultdict(int)

mask_dir = Path("data/bear/object_mask")
mask_files = sorted(mask_dir.glob("*.png"))

print(f"Analyzing {len(mask_files)} ground truth mask files...\n")

for mask_file in mask_files:
    img = np.array(Image.open(mask_file))
    unique_vals, counts = np.unique(img, return_counts=True)
    
    for val, count in zip(unique_vals, counts):
        if val > 0:  # Skip background (0)
            object_counts[val] += 1
            object_pixel_counts[val] += count

print("="*70)
print(f"Ground Truth Object Labels (from {len(mask_files)} frames)")
print("="*70)
print(f"{'Object ID':<12} {'Frames':<10} {'% Frames':<12} {'Avg Pixels/Frame':<20}")
print("-"*70)

# Sort by number of frames (descending)
sorted_objects = sorted(object_counts.items(), key=lambda x: x[1], reverse=True)

for obj_id, frame_count in sorted_objects:
    pct_frames = (frame_count / len(mask_files)) * 100
    avg_pixels = object_pixel_counts[obj_id] / frame_count
    print(f"{obj_id:<12} {frame_count:<10} {pct_frames:>6.1f}%      {avg_pixels:>15,.0f}")

print("="*70)
print(f"\nTotal unique objects in ground truth: {len(object_counts)}")
print(f"Background ID: 0 (appears in all frames)")
print("\nNote: Object ID 34 is labeled as the bear in ground truth")
