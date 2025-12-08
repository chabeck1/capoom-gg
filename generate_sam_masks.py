
import os
import torch
import numpy as np
from PIL import Image
from tqdm import tqdm
import argparse
from ext.grounded_sam import load_model_hf, grouned_sam_output
from segment_anything import sam_model_registry, SamPredictor, SamAutomaticMaskGenerator

"""
Script to generate instance masks using Segment Anything Model (SAM).
Supports both text-prompted generation (Grounded-SAM) and automatic generation (Segment Everything).

Usage:
    python generate_sam_masks.py --image_dir <path> --output_dir <path> --automatic
"""

def generate_automatic_masks(image_dir, output_dir, split_idx=0, num_splits=1):
    print(f"Generating AUTOMATIC masks (Segment Everything) for images in {image_dir}")
    print(f"Output directory: {output_dir}")
    
    os.makedirs(output_dir, exist_ok=True)

    # Load SAM
    print("Loading SAM...")
    sam_checkpoint = 'Tracking-Anything-with-DEVA/saves/sam_vit_h_4b8939.pth'
    sam = sam_model_registry["vit_h"](checkpoint=sam_checkpoint)
    sam.to(device='cuda')
    
    # Initialize Automatic Mask Generator
    mask_generator = SamAutomaticMaskGenerator(sam)
    
    image_files = []
    for root, dirs, files in os.walk(image_dir):
        for file in files:
            if file.lower().endswith(('.png', '.jpg', '.jpeg')):
                rel_path = os.path.relpath(os.path.join(root, file), image_dir)
                image_files.append(rel_path)
    image_files.sort()
    
    total_images = len(image_files)
    print(f"Found {total_images} images total.")
    
    # Calculate split
    if num_splits > 1:
        chunk_size = int(np.ceil(total_images / num_splits))
        start_idx = split_idx * chunk_size
        end_idx = min((split_idx + 1) * chunk_size, total_images)
        image_files = image_files[start_idx:end_idx]
        print(f"Processing split {split_idx+1}/{num_splits}: images {start_idx} to {end_idx} ({len(image_files)} images)")
    
    for img_file in tqdm(image_files, desc=f"Processing split {split_idx}"):
        img_path = os.path.join(image_dir, img_file)
        
        # Create output subdirectory
        out_path = os.path.join(output_dir, img_file)
        os.makedirs(os.path.dirname(out_path), exist_ok=True)

        # Load image
        image_pil = Image.open(img_path).convert("RGB")
        image_np = np.array(image_pil)
        
        try:
            # Generate masks
            masks = mask_generator.generate(image_np)
            
            # Combine masks into a single ID map
            # Sort by area (largest first) so smaller masks overwrite larger ones
            masks = sorted(masks, key=(lambda x: x['area']), reverse=True)
            
            # Create an empty ID map
            # We use 16-bit integer to support > 255 objects
            H, W = masks[0]['segmentation'].shape
            id_map = np.zeros((H, W), dtype=np.uint16)
            
            for i, mask_data in enumerate(masks):
                # ID 0 is background, so start at 1
                obj_id = i + 1
                binary_mask = mask_data['segmentation']
                id_map[binary_mask] = obj_id
                
            # Save as 32-bit Integer PNG (to preserve IDs > 255 and match dataset format)
            result_img = Image.fromarray(id_map.astype(np.int32))
            # Ensure extension is png
            base, _ = os.path.splitext(out_path)
            result_img.save(base + '.png')
            
            # Save visualization (colorized)
            viz_path = base + '_viz.png'
            # Create random colormap
            # We need max_id + 1 colors
            max_id = id_map.max()
            if max_id > 0:
                # Generate random colors for each ID
                # Seed for consistency? Maybe not needed for viz.
                colors = np.random.randint(0, 255, size=(max_id + 1, 3), dtype=np.uint8)
                colors[0] = [0, 0, 0] # Background black
                
                # Map IDs to colors
                viz_img = colors[id_map]
                Image.fromarray(viz_img).save(viz_path)
            
        except Exception as e:
            print(f"Error processing {img_file}: {e}")

def generate_masks(image_dir, output_dir, text_prompt=None, box_threshold=0.3, text_threshold=0.25, automatic=False, split_idx=0, num_splits=1):
    if automatic:
        generate_automatic_masks(image_dir, output_dir, split_idx, num_splits)
        return

    print(f"Generating masks for images in {image_dir}")
    print(f"Output directory: {output_dir}")
    print(f"Text prompt: '{text_prompt}'")
    
    os.makedirs(output_dir, exist_ok=True)
    
    # Load Grounding DINO
    print("Loading Grounding DINO...")
    ckpt_repo_id = "ShilongLiu/GroundingDINO"
    ckpt_filenmae = "groundingdino_swinb_cogcoor.pth"
    ckpt_config_filename = "GroundingDINO_SwinB.cfg.py"
    groundingdino_model = load_model_hf(ckpt_repo_id, ckpt_filenmae, ckpt_config_filename)
    groundingdino_model = groundingdino_model.to("cuda")

    # Load SAM
    print("Loading SAM...")
    sam_checkpoint = 'Tracking-Anything-with-DEVA/saves/sam_vit_h_4b8939.pth'
    if not os.path.exists(sam_checkpoint):
        # Try alternative path or download if needed
        print(f"Warning: SAM checkpoint not found at {sam_checkpoint}")
        # Assuming it might be in a different location or user needs to provide it
        # For now, let's assume it's there as per previous context
    
    sam = sam_model_registry["vit_h"](checkpoint=sam_checkpoint)
    sam.to(device='cuda')
    sam_predictor = SamPredictor(sam)
    
    image_files = sorted([f for f in os.listdir(image_dir) if f.endswith(('.png', '.jpg', '.jpeg'))])
    
    for img_file in tqdm(image_files, desc="Processing images"):
        img_path = os.path.join(image_dir, img_file)
        
        # Load image
        image_pil = Image.open(img_path).convert("RGB")
        image_np = np.array(image_pil)
        
        # Run Grounded-SAM
        # Returns: mask (H, W) bool tensor, annotated_frame (H, W, 3) numpy array
        try:
            mask, annotated_frame = grouned_sam_output(
                groundingdino_model, 
                sam_predictor, 
                text_prompt, 
                image_np, 
                BOX_TRESHOLD=box_threshold, 
                TEXT_TRESHOLD=text_threshold,
                device='cuda'
            )
            
            # Save mask
            mask_np = mask.cpu().numpy().astype(np.uint8) * 255
            mask_img = Image.fromarray(mask_np)
            mask_img.save(os.path.join(output_dir, img_file))
            
            # Optional: Save visualization
            # viz_dir = os.path.join(output_dir, "viz")
            # os.makedirs(viz_dir, exist_ok=True)
            # Image.fromarray(annotated_frame).save(os.path.join(viz_dir, img_file))
            
        except Exception as e:
            print(f"Error processing {img_file}: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--image_dir", type=str, required=True, help="Directory containing input images")
    parser.add_argument("--output_dir", type=str, required=True, help="Directory to save output masks")
    parser.add_argument("--text_prompt", type=str, default=None, help="Text prompt for Grounding DINO (e.g., 'car', 'road')")
    parser.add_argument("--box_threshold", type=float, default=0.3)
    parser.add_argument("--text_threshold", type=float, default=0.25)
    parser.add_argument("--automatic", action="store_true", help="Use SAM Automatic Mask Generator (Segment Everything)")
    parser.add_argument("--split_idx", type=int, default=0, help="Index of the split to process (0-based)")
    parser.add_argument("--num_splits", type=int, default=1, help="Total number of splits")
    
    args = parser.parse_args()
    
    generate_masks(args.image_dir, args.output_dir, args.text_prompt, args.box_threshold, args.text_threshold, args.automatic, args.split_idx, args.num_splits)
