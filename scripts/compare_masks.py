
import os
import numpy as np
from PIL import Image

def analyze_mask(path, name):
    print(f"--- Analyzing {name} Mask ---")
    if not os.path.exists(path):
        print(f"File not found: {path}")
        return

    try:
        img = Image.open(path)
        print(f"Format: {img.format}, Mode: {img.mode}, Size: {img.size}")
        
        arr = np.array(img)
        unique_vals = np.unique(arr)
        
        print(f"Number of unique values: {len(unique_vals)}")
        if len(unique_vals) < 20:
            print(f"Unique values: {unique_vals}")
        else:
            print(f"First 20 unique values: {unique_vals[:20]}...")
            
        if img.mode == 'RGB':
            # Check if it's actually grayscale (R=G=B)
            is_gray = np.all(arr[:,:,0] == arr[:,:,1]) and np.all(arr[:,:,1] == arr[:,:,2])
            print(f"Is effectively grayscale? {is_gray}")
            
    except Exception as e:
        print(f"Error: {e}")

# Find a sample file
def get_first_file(dir_path):
    if not os.path.exists(dir_path):
        return None
    for root, dirs, files in os.walk(dir_path):
        for file in files:
            if file.endswith('.png') or file.endswith('.jpg'):
                return os.path.join(root, file)
    return None

bear_mask_dir = "data/bear/object_mask"
mcity_mask_dir = "data/mcity/object_mask"

bear_sample = get_first_file(bear_mask_dir)
mcity_sample = get_first_file(mcity_mask_dir)

analyze_mask(bear_sample, "Bear")
print("\n")
analyze_mask(mcity_sample, "Mcity")
