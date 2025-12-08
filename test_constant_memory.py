#!/usr/bin/env python3
"""
Test script to verify constant memory usage during training.
This simulates the training loop and monitors memory.
"""

import torch
import os
from scene.cameras import Camera
import numpy as np

def get_memory_mb():
    """Get current GPU memory allocated in MB."""
    if torch.cuda.is_available():
        return torch.cuda.memory_allocated() / (1024**2)
    return 0

def test_constant_memory():
    print("=" * 60)
    print("CONSTANT MEMORY TEST")
    print("=" * 60)
    
    # Create a mock CameraInfo class
    class MockCamInfo:
        def __init__(self, idx):
            self.uid = idx
            self.width = 1024
            self.height = 1024
            self.image_path = "/home/chabeck/gaussian-grouping/data/mcity/images/K1/camera_1/1758665020.298448_2.jpg"
            self.FovX = 1.0
            self.FovY = 1.0
            self.image_name = f"test_{idx}"
    
    print(f"\nInitial GPU memory: {get_memory_mb():.2f} MB")
    
    # Create 10 cameras with lazy loading
    cameras = []
    for i in range(10):
        cam = Camera(
            colmap_id=i,
            R=np.eye(3),
            T=np.zeros(3),
            FoVx=1.0,
            FoVy=1.0,
            image=None,
            gt_alpha_mask=None,
            image_name=f"test_{i}",
            uid=i,
            data_device="cuda",
            cam_info=MockCamInfo(i),
            resolution_args=(-1, 1.0)
        )
        cameras.append(cam)
    
    print(f"After creating 10 cameras: {get_memory_mb():.2f} MB")
    print("(Should be ~0 MB since no images loaded yet)")
    
    # Simulate training loop - access images sequentially
    print("\n" + "=" * 60)
    print("SIMULATING TRAINING ITERATIONS")
    print("=" * 60)
    
    memories = []
    for iteration in range(30):
        # Access a camera (this triggers image load from disk)
        cam_idx = iteration % len(cameras)
        img = cameras[cam_idx].original_image
        
        # Use the image (simulate training step)
        _ = img.mean()
        
        # Clear the temporary tensor
        del img
        torch.cuda.empty_cache()
        
        mem = get_memory_mb()
        memories.append(mem)
        
        if iteration % 5 == 0:
            print(f"Iteration {iteration:3d}: GPU memory = {mem:.2f} MB")
    
    print("\n" + "=" * 60)
    print("RESULTS")
    print("=" * 60)
    print(f"Min memory: {min(memories):.2f} MB")
    print(f"Max memory: {max(memories):.2f} MB")
    print(f"Average memory: {sum(memories)/len(memories):.2f} MB")
    
    mem_growth = max(memories) - min(memories)
    print(f"\nMemory growth: {mem_growth:.2f} MB")
    
    if mem_growth < 50:  # Less than 50 MB growth
        print("✓ SUCCESS: Memory stays constant!")
        print("✓ Images are loaded on-demand and released immediately")
        return True
    else:
        print("✗ FAILURE: Memory is growing!")
        print("✗ Images may be cached in GPU memory")
        return False

if __name__ == "__main__":
    if not torch.cuda.is_available():
        print("ERROR: CUDA not available. This test requires a GPU.")
        exit(1)
    
    success = test_constant_memory()
    exit(0 if success else 1)
