#!/usr/bin/env python3
"""
Edit 3D scenes using text descriptions instead of object IDs.

This script uses render_lerf_mask.py to detect objects by text,
then automatically removes them using the detected object IDs.

Usage:
    python edit_by_text.py --scene output/bear --remove "bear"
    python edit_by_text.py --scene output/bear --remove "bear" --inpaint
"""

import os
import sys
import json
import argparse
import subprocess
from pathlib import Path


def find_object_ids_from_text(scene_path, text_prompt, dataset_source_path):
    """
    Run render_lerf_mask.py to detect objects and get their IDs.
    Returns list of object IDs.
    """
    print(f"🔍 Detecting '{text_prompt}' in scene using GroundingDINO + SAM...")
    
    # Run render_lerf_mask.py with the text prompt
    cmd = [
        "python", "render_lerf_mask.py",
        "-s", dataset_source_path,
        "-m", scene_path,
        "--text", text_prompt,
        "--skip_test"  # Only process training views to save time
    ]
    
    print(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        print(f"❌ Error running text detection:")
        print(result.stderr)
        return []
    
    # Check stdout for the object IDs message
    if "Selected object IDs" in result.stdout:
        print(result.stdout.split("Selected object IDs")[-1].split('\n')[0])
    
    # Read the saved JSON file with object IDs
    obj_ids_file = os.path.join(scene_path, "train", "ours_30000_text", f"object_ids---{text_prompt}.json")
    
    if not os.path.exists(obj_ids_file):
        print(f"❌ Object IDs file not found: {obj_ids_file}")
        return []
    
    with open(obj_ids_file, 'r') as f:
        data = json.load(f)
    
    object_ids = data.get('object_ids', [])
    
    if object_ids:
        print(f"✅ Found {len(object_ids)} object(s) matching '{text_prompt}'")
        print(f"   Object IDs: {object_ids}")
    else:
        print(f"⚠️  No objects detected for '{text_prompt}'")
    
    return object_ids


def remove_objects(scene_path, object_ids, removal_thresh=0.3):
    """
    Remove objects by their IDs.
    """
    print(f"\n🗑️  Removing objects {object_ids}...")
    
    # Create config
    config_dir = "config/object_removal"
    os.makedirs(config_dir, exist_ok=True)
    
    scene_name = Path(scene_path).name
    config_path = os.path.join(config_dir, f"{scene_name}_text_removal.json")
    
    config = {
        "num_classes": 256,
        "removal_thresh": removal_thresh,
        "select_obj_id": object_ids
    }
    
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)
    
    print(f"Created config: {config_path}")
    
    # Run removal
    cmd = ["bash", "script/edit_object_removal.sh", scene_path, config_path]
    print(f"Running: {' '.join(cmd)}")
    
    result = subprocess.run(cmd)
    
    if result.returncode == 0:
        print("✅ Object removal complete!")
        print(f"Results in: {scene_path}/train/ours_object_removal/")
    else:
        print("❌ Object removal failed")
        return False
    
    return True


def inpaint_scene(scene_path):
    """
    Inpaint the scene after removal to fill holes.
    """
    print(f"\n🎨 Inpainting scene to fill removed regions...")
    
    # Create config
    config_dir = "config/object_inpaint"
    os.makedirs(config_dir, exist_ok=True)
    
    scene_name = Path(scene_path).name
    config_path = os.path.join(config_dir, f"{scene_name}_text_inpaint.json")
    
    config = {
        "num_classes": 256
    }
    
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)
    
    print(f"Created config: {config_path}")
    
    # Run inpainting
    cmd = ["bash", "script/edit_object_inpaint.sh", scene_path, config_path]
    print(f"Running: {' '.join(cmd)}")
    print("⚠️  This will take 1-2 hours...")
    
    result = subprocess.run(cmd)
    
    if result.returncode == 0:
        print("✅ Inpainting complete!")
        print(f"Results in: {scene_path}/train/ours_object_inpaint/")
    else:
        print("❌ Inpainting failed")
        return False
    
    return True


def main():
    parser = argparse.ArgumentParser(
        description="Edit 3D Gaussian Splatting scenes using text descriptions"
    )
    parser.add_argument("--scene", "-m", required=True, 
                       help="Path to trained scene (e.g., output/bear)")
    parser.add_argument("--source", "-s", 
                       help="Path to source data (e.g., data/bear). If not provided, inferred from scene path")
    parser.add_argument("--remove", type=str,
                       help="Text description of objects to remove")
    parser.add_argument("--inpaint", action="store_true",
                       help="Inpaint after removal to fill holes")
    parser.add_argument("--removal_thresh", type=float, default=0.3,
                       help="Threshold for removal (0.0-1.0, lower = more aggressive)")
    parser.add_argument("--dry-run", action="store_true",
                       help="Only detect objects, don't edit")
    parser.add_argument("--no-confirm", action="store_true",
                       help="Skip confirmation prompt (for batch jobs)")
    
    args = parser.parse_args()
    
    if not args.remove:
        print("❌ Please specify objects to remove with --remove")
        print("Example: python edit_by_text.py --scene output/bear --remove 'bear'")
        return 1
    
    # Infer source path if not provided
    if not args.source:
        scene_name = Path(args.scene).name
        args.source = f"data/{scene_name}"
        print(f"ℹ️  Inferred source path: {args.source}")
    
    # Step 1: Find object IDs from text
    object_ids = find_object_ids_from_text(args.scene, args.remove, args.source)
    
    if not object_ids:
        print(f"\n❌ Could not find any objects matching '{args.remove}'")
        print("\nTips:")
        print("  - Try different descriptions (e.g., 'tree' vs 'trees' vs 'pine tree')")
        print("  - Make sure your scene is trained")
        print("  - Check if GroundingDINO and SAM are installed")
        print("  - Look at the visualization: " + os.path.join(args.scene, "train", "ours_30000_text", f"grounded-sam---{args.remove}.png"))
        return 1
    
    print(f"\n📋 Summary:")
    print(f"  Scene: {args.scene}")
    print(f"  Text query: '{args.remove}'")
    print(f"  Detected object IDs: {object_ids}")
    print(f"  Inpaint after removal: {args.inpaint}")
    
    if args.dry_run:
        print("\n🔍 Dry run - stopping here")
        print(f"Check visualization: {args.scene}/train/ours_30000_text/grounded-sam---{args.remove}.png")
        return 0
    
    # Confirm
    if not args.no_confirm:
        response = input("\nProceed with removal? [y/N]: ")
        if response.lower() != 'y':
            print("Cancelled")
            return 0
    
    # Step 2: Remove objects
    success = remove_objects(args.scene, object_ids, args.removal_thresh)
    if not success:
        return 1
    
    # Step 3: Optional inpainting
    if args.inpaint:
        success = inpaint_scene(args.scene)
        if not success:
            return 1
    
    print("\n" + "="*60)
    print("✅ ALL DONE!")
    print("="*60)
    print(f"\nYour edited scene is ready:")
    if args.inpaint:
        print(f"  {args.scene}/train/ours_object_inpaint/renders/")
    else:
        print(f"  {args.scene}/train/ours_object_removal/renders/")
    print(f"\nVisualization of detection:")
    print(f"  {args.scene}/train/ours_30000_text/grounded-sam---{args.remove}.png")
    print("\nDownload the renders folder to see the results!")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
