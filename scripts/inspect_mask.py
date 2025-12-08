import numpy as np
from PIL import Image
import sys

img_path = sys.argv[1]
print(f"Inspecting {img_path}")
try:
    img = Image.open(img_path)
    data = np.array(img)
    print(f"Shape: {data.shape}")
    print(f"Dtype: {data.dtype}")
    print(f"Min value: {data.min()}")
    print(f"Max value: {data.max()}")
    unique_vals = np.unique(data)
    print(f"Unique values count: {len(unique_vals)}")
    print(f"First 20 unique values: {unique_vals[:20]}")
except Exception as e:
    print(f"Error: {e}")
