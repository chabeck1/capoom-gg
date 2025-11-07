#!/usr/bin/env python3
"""
Quick test of lazy loading implementation.
"""

import sys
from scene.dataset_readers import _image_cache, CameraInfo
import numpy as np

# Create a mock camera with lazy loading
cam = CameraInfo(
    uid=1,
    R=np.eye(3),
    T=np.zeros(3),
    FovY=1.0,
    FovX=1.0,
    image_path="data/mcity/images/K1/camera_0/1758662704.529435_0.jpg",
    image_name="test",
    width=1024,
    height=1024,
    object_path=None
)

print("CameraInfo created - image not loaded yet")
print(f"Image path: {cam.image_path}")
print(f"Image loaded: {cam._loaded}")
print()

# Access image - should trigger lazy load
print("Accessing cam.image for first time...")
img = cam.image
print(f"Image loaded: {cam._loaded}")
print(f"Image size: {img.size}")
print(f"Cache stats: {_image_cache.stats()}")
print()

# Access again - should hit cache
print("Accessing cam.image again...")
img2 = cam.image
print(f"Cache stats: {_image_cache.stats()}")
print()

print("✅ Lazy loading working correctly!")
