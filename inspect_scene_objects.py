#!/usr/bin/env python3
"""
Quick script to inspect what object IDs exist in a trained scene
Shows object ID, number of Gaussians, and percentage of scene
"""

import torch
import sys
from pathlib import Path
from scene import GaussianModel
from arguments import ModelParams
from argparse import ArgumentParser

def inspect_objects(scene_path, iteration=30000):
    """Load scene and show object distribution"""
    
    # Load Gaussians
    gaussians = GaussianModel(sh_degree=3)
    iteration_path = Path(scene_path) / "point_cloud" / f"iteration_{iteration}"
    
    ply_path = iteration_path / "point_cloud.ply"
    classifier_path = iteration_path / "classifier.pth"
    
    if not ply_path.exists():
        print(f"ERROR: {ply_path} not found")
        return
    
    if not classifier_path.exists():
        print(f"ERROR: {classifier_path} not found")
        return
    
    print(f"Loading scene from {scene_path}")
    gaussians.load_ply(str(ply_path))
    
    # Load classifier
    num_classes = 256
    classifier = torch.nn.Conv2d(gaussians.num_objects, num_classes, kernel_size=1).cuda()
    classifier.load_state_dict(torch.load(classifier_path))
    
    # Get object assignments
    with torch.no_grad():
        logits3d = classifier(gaussians._objects_dc.permute(2, 0, 1))
        prob_obj3d = torch.softmax(logits3d, dim=0)
        
        # Get most likely object ID for each Gaussian
        obj_ids = torch.argmax(prob_obj3d, dim=0).squeeze()
        
        # Get confidence (max probability) for each Gaussian
        confidences = torch.max(prob_obj3d, dim=0)[0].squeeze()
    
    total_gaussians = obj_ids.shape[0]
    
    # Count Gaussians per object
    unique_ids, counts = torch.unique(obj_ids, return_counts=True)
    
    print(f"\n{'='*70}")
    print(f"Total Gaussians: {total_gaussians:,}")
    print(f"Unique Objects: {len(unique_ids)}")
    print(f"{'='*70}")
    print(f"{'Object ID':<12} {'Count':<15} {'Percentage':<12} {'Avg Confidence':<15}")
    print(f"{'-'*70}")
    
    # Sort by count (descending)
    sorted_indices = torch.argsort(counts, descending=True)
    
    for idx in sorted_indices:
        obj_id = unique_ids[idx].item()
        count = counts[idx].item()
        percentage = (count / total_gaussians) * 100
        
        # Get average confidence for this object
        obj_mask = obj_ids == obj_id
        avg_conf = confidences[obj_mask].mean().item()
        
        print(f"{obj_id:<12} {count:<15,} {percentage:>6.2f}%      {avg_conf:>6.3f}")
    
    print(f"{'='*70}\n")
    
    # Show high-confidence objects (good candidates for extraction)
    print("High-confidence objects (>10,000 Gaussians, >70% avg confidence):")
    print(f"{'-'*70}")
    
    candidates = []
    for idx in sorted_indices:
        obj_id = unique_ids[idx].item()
        count = counts[idx].item()
        obj_mask = obj_ids == obj_id
        avg_conf = confidences[obj_mask].mean().item()
        
        if count > 10000 and avg_conf > 0.7:
            candidates.append((obj_id, count, avg_conf))
            print(f"  Object {obj_id}: {count:,} Gaussians ({avg_conf:.3f} avg confidence)")
    
    if not candidates:
        print("  No high-confidence objects found with >10k Gaussians")
    
    print(f"{'='*70}\n")
    
    return unique_ids, counts, confidences

if __name__ == "__main__":
    parser = ArgumentParser(description="Inspect objects in a trained scene")
    parser.add_argument("--scene", type=str, required=True, help="Path to scene (e.g., output/bear)")
    parser.add_argument("--iteration", type=int, default=30000, help="Iteration to inspect")
    args = parser.parse_args()
    
    inspect_objects(args.scene, args.iteration)
