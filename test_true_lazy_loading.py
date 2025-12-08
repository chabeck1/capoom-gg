#!/usr/bin/env python3
"""
Test that Camera objects truly lazy-load images, not during Scene init
"""

import sys
import torch
from scene import Scene
from scene.gaussian_model import GaussianModel
from arguments import ModelParams

# Monkey-patch PIL Image.open to track calls
original_open = None
open_count = 0

def tracking_open(path):
    global open_count
    open_count += 1
    if open_count <= 5:  # Print first few
        print(f"  Image opened: {path}")
    return original_open(path)

# Patch PIL
from PIL import Image
original_open = Image.open
Image.open = tracking_open

print("Creating Scene with lazy loading...")
print("If truly lazy, we should only see dimension checks, not full image loads\n")

# Use a small dataset
import argparse
parser = argparse.ArgumentParser()
model_params = ModelParams(parser)
args = parser.parse_args([
    '-s', 'data/bear',
    '-m', 'output/test_lazy',
    '--data_device', 'cpu'
])

gaussians = GaussianModel(args.sh_degree)
scene = Scene(args, gaussians)

print(f"\n✓ Scene initialized")
print(f"  Total Image.open() calls during init: {open_count}")
print(f"  Training cameras: {len(scene.train_cameras[1.0])}")
print(f"  Test cameras: {len(scene.test_cameras[1.0])}")

# The image should only open for dimensions (once per camera), not load pixel data
# With lazy loading, we'd see 2x the camera count (train + test) open calls just for dimensions
expected_dimension_checks = len(scene.train_cameras[1.0]) + len(scene.test_cameras[1.0])

if open_count <= expected_dimension_checks + 5:  # Some slack for ply reading etc
    print(f"\n✅ PASS: Only {open_count} opens for {expected_dimension_checks} cameras (dimension checks only)")
else:
    print(f"\n❌ FAIL: {open_count} opens for {expected_dimension_checks} cameras (images were loaded!)")

# Now access first camera's image - this SHOULD load it
print("\n\nNow accessing first training camera's image...")
open_count_before = open_count
first_cam = scene.train_cameras[1.0][0]
img = first_cam.original_image
print(f"  Image shape: {img.shape}")
print(f"  New Image.open() calls: {open_count - open_count_before}")

if open_count > open_count_before:
    print("✅ PASS: Image was lazy-loaded on first access")
else:
    print("❌ FAIL: Image was not lazy-loaded (already in memory)")
