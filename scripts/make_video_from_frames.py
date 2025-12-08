import os
import cv2
import numpy as np
from PIL import Image
from tqdm import tqdm
import argparse

def make_video(model_path, iteration=30000, fps=30):
    base_path = os.path.join(model_path, "train", f"ours_{iteration}")
    
    render_path = os.path.join(base_path, "renders")
    gts_path = os.path.join(base_path, "gt")
    colormask_path = os.path.join(base_path, "objects_feature16")
    gt_colormask_path = os.path.join(base_path, "gt_objects_color")
    pred_obj_path = os.path.join(base_path, "objects_pred_custom")
    
    output_dir = os.path.join(base_path, "concat_custom_partial")
    os.makedirs(output_dir, exist_ok=True)
    output_video_path = os.path.join(output_dir, "result.mp4")
    
    print(f"Looking for frames in {pred_obj_path}...")
    
    # Get list of files that exist in pred_obj_path (since that's what we have 709 of)
    files = sorted([f for f in os.listdir(pred_obj_path) if f.endswith('.png')])
    
    if not files:
        print("No frames found!")
        return

    print(f"Found {len(files)} frames. Creating video...")
    
    # Read first frame to get size
    first_frame = np.array(Image.open(os.path.join(pred_obj_path, files[0])))
    h, w = first_frame.shape[:2]
    
    # We stack 5 images horizontally: GT, Render, GT_Seg, Pred_Seg, PCA_Seg
    # Note: GT_Seg might be all black if no GT masks provided
    video_w = w * 5
    video_h = h
    
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    writer = cv2.VideoWriter(output_video_path, fourcc, fps, (video_w, video_h))
    
    for filename in tqdm(files):
        try:
            # Load all components
            # Use .convert('RGB') to ensure 3 channels
            pred_obj = np.array(Image.open(os.path.join(pred_obj_path, filename)).convert('RGB'))
            
            # Check if other files exist, otherwise use black
            if os.path.exists(os.path.join(gts_path, filename)):
                gt = np.array(Image.open(os.path.join(gts_path, filename)).convert('RGB'))
            else:
                gt = np.zeros_like(pred_obj)

            if os.path.exists(os.path.join(render_path, filename)):
                rgb = np.array(Image.open(os.path.join(render_path, filename)).convert('RGB'))
            else:
                rgb = np.zeros_like(pred_obj)

            if os.path.exists(os.path.join(gt_colormask_path, filename)):
                gt_obj = np.array(Image.open(os.path.join(gt_colormask_path, filename)).convert('RGB'))
            else:
                gt_obj = np.zeros_like(pred_obj)

            if os.path.exists(os.path.join(colormask_path, filename)):
                render_obj = np.array(Image.open(os.path.join(colormask_path, filename)).convert('RGB'))
            else:
                render_obj = np.zeros_like(pred_obj)
            
            # Concatenate
            result = np.hstack([gt, rgb, gt_obj, pred_obj, render_obj])
            
            # Write to video (OpenCV uses BGR)
            writer.write(result[:, :, ::-1])
            
        except Exception as e:
            print(f"Error processing {filename}: {e}")
            continue
            
    writer.release()
    print(f"Video saved to {output_video_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--model_path", type=str, required=True)
    args = parser.parse_args()
    
    make_video(args.model_path)
