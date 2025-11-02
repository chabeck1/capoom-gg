#!/usr/bin/env python3
"""
Calculate segmentation accuracy by comparing model predictions to ground truth
Computes IoU (Intersection over Union) and pixel accuracy
"""

import torch
import numpy as np
from PIL import Image
from pathlib import Path
from tqdm import tqdm
from scene import GaussianModel
from gaussian_renderer import render
from scene import Scene
from arguments import ModelParams
from argparse import ArgumentParser
import sys

def compute_iou(pred, gt, num_classes):
    """Compute IoU for each class"""
    ious = []
    valid_classes = []
    
    for cls in range(num_classes):
        pred_mask = (pred == cls)
        gt_mask = (gt == cls)
        
        intersection = np.logical_and(pred_mask, gt_mask).sum()
        union = np.logical_or(pred_mask, gt_mask).sum()
        
        if union > 0:
            iou = intersection / union
            ious.append(iou)
            valid_classes.append(cls)
    
    return ious, valid_classes

def evaluate_segmentation(scene_path, iteration=30000):
    """Evaluate segmentation accuracy"""
    
    print(f"Loading scene from {scene_path}")
    
    # Load model
    gaussians = GaussianModel(sh_degree=3)
    iteration_path = Path(scene_path) / "point_cloud" / f"iteration_{iteration}"
    
    ply_path = iteration_path / "point_cloud.ply"
    classifier_path = iteration_path / "classifier.pth"
    
    gaussians.load_ply(str(ply_path))
    
    # Load classifier
    num_classes = 256
    classifier = torch.nn.Conv2d(gaussians.num_objects, num_classes, kernel_size=1).cuda()
    classifier.load_state_dict(torch.load(classifier_path))
    classifier.eval()
    
    # Load ground truth masks
    gt_mask_dir = Path("data/bear/object_mask")
    gt_masks = sorted(gt_mask_dir.glob("*.png"))
    
    # Load rendered predictions (if they exist)
    pred_dir = Path(scene_path) / "train" / f"ours_{iteration}" / "objects_pred"
    
    if not pred_dir.exists():
        print(f"ERROR: Predictions not found at {pred_dir}")
        print("Need to render the scene first with object predictions")
        return
    
    pred_files = sorted(pred_dir.glob("*.png"))
    
    print(f"Found {len(gt_masks)} ground truth masks")
    print(f"Found {len(pred_files)} prediction masks")
    
    if len(gt_masks) != len(pred_files):
        print("WARNING: Number of GT and prediction files don't match!")
    
    # Compute metrics
    total_correct = 0
    total_pixels = 0
    all_ious = []
    per_class_ious = {}
    
    print("\nEvaluating segmentation accuracy...")
    
    for gt_file, pred_file in tqdm(zip(gt_masks, pred_files), total=len(gt_masks)):
        # Load masks
        gt = np.array(Image.open(gt_file))
        pred_img = np.array(Image.open(pred_file))
        
        # If pred is RGB, take first channel (they should all be the same)
        if len(pred_img.shape) == 3:
            pred = pred_img[:, :, 0]
        else:
            pred = pred_img
        
        # Resize if needed
        if gt.shape != pred.shape:
            from PIL import Image as PILImage
            pred = np.array(PILImage.fromarray(pred).resize((gt.shape[1], gt.shape[0]), PILImage.NEAREST))
        
        # Pixel accuracy
        correct = np.sum(pred == gt)
        total_correct += correct
        total_pixels += gt.size
        
        # IoU per class
        ious, valid_classes = compute_iou(pred, gt, num_classes)
        all_ious.extend(ious)
        
        for cls, iou in zip(valid_classes, ious):
            if cls not in per_class_ious:
                per_class_ious[cls] = []
            per_class_ious[cls].append(iou)
    
    # Overall metrics
    pixel_accuracy = (total_correct / total_pixels) * 100
    mean_iou = np.mean(all_ious) * 100
    
    print("\n" + "="*70)
    print("SEGMENTATION ACCURACY RESULTS")
    print("="*70)
    print(f"Pixel Accuracy: {pixel_accuracy:.2f}%")
    print(f"Mean IoU: {mean_iou:.2f}%")
    print(f"Total pixels evaluated: {total_pixels:,}")
    print("="*70)
    
    # Per-class IoU for important objects
    print("\nPer-Class IoU (top objects):")
    print("-"*70)
    print(f"{'Class ID':<12} {'Mean IoU':<15} {'Frames':<10}")
    print("-"*70)
    
    # Sort by number of frames
    sorted_classes = sorted(per_class_ious.items(), key=lambda x: len(x[1]), reverse=True)
    
    for cls_id, ious in sorted_classes[:20]:  # Top 20
        mean_cls_iou = np.mean(ious) * 100
        num_frames = len(ious)
        
        note = ""
        if cls_id == 34:
            note = "  ← THE BEAR"
        elif cls_id == 33:
            note = "  ← pedestal"
        elif cls_id == 35:
            note = "  ← upper statue"
        
        print(f"{cls_id:<12} {mean_cls_iou:>6.2f}%         {num_frames:<10}{note}")
    
    print("="*70)
    
    return pixel_accuracy, mean_iou, per_class_ious

if __name__ == "__main__":
    parser = ArgumentParser(description="Evaluate segmentation accuracy")
    parser.add_argument("--scene", type=str, default="output/bear", help="Path to scene")
    parser.add_argument("--iteration", type=int, default=30000, help="Iteration to evaluate")
    args = parser.parse_args()
    
    evaluate_segmentation(args.scene, args.iteration)
