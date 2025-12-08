
import torch
import os
import numpy as np
from plyfile import PlyData
import argparse
import json

def inspect_grouping(model_path, iteration=30000):
    print(f"Inspecting model at: {model_path}")
    
    # Paths
    ply_path = os.path.join(model_path, "point_cloud", f"iteration_{iteration}", "point_cloud.ply")
    classifier_path = os.path.join(model_path, "point_cloud", f"iteration_{iteration}", "classifier.pth")
    
    if not os.path.exists(ply_path):
        print(f"Error: PLY file not found at {ply_path}")
        return
    if not os.path.exists(classifier_path):
        print(f"Error: Classifier checkpoint not found at {classifier_path}")
        return

    # 1. Load PLY and extract obj_dc
    print("Loading PLY file...")
    plydata = PlyData.read(ply_path)
    
    # Find obj_dc attributes
    obj_dc_names = [p.name for p in plydata.elements[0].properties if p.name.startswith("obj_dc_")]
    obj_dc_names = sorted(obj_dc_names, key=lambda x: int(x.split('_')[-1]))
    
    num_objects_dim = len(obj_dc_names)
    print(f"Found {num_objects_dim} grouping dimensions in PLY.")
    
    num_points = plydata.elements[0].count
    print(f"Number of points: {num_points}")
    
    # Extract obj_dc data
    # Shape: (N, 16)
    obj_dc = np.zeros((num_points, num_objects_dim), dtype=np.float32)
    for idx, name in enumerate(obj_dc_names):
        obj_dc[:, idx] = np.asarray(plydata.elements[0][name])
    
    # Convert to tensor
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    obj_dc_tensor = torch.tensor(obj_dc).to(device) # (N, 16)
    
    # 2. Load Classifier
    print("Loading classifier...")
    classifier_state = torch.load(classifier_path, map_location=device)
    
    # Check shapes
    weight = classifier_state['weight'] # Expected: (NumClasses, 16, 1, 1)
    bias = classifier_state['bias']     # Expected: (NumClasses)
    
    num_classes = weight.shape[0]
    print(f"Classifier has {num_classes} output classes.")
    
    # Reshape weights for matrix multiplication
    # We want to do: obj_dc (N, 16) @ weight.T (16, C) + bias
    # weight is (C, 16, 1, 1) -> squeeze to (C, 16)
    W = weight.squeeze().to(device) # (C, 16)
    b = bias.to(device)             # (C)
    
    # 3. Inference
    print("Running inference to determine object classes...")
    
    batch_size = 100000
    num_batches = (num_points + batch_size - 1) // batch_size
    
    all_predictions = []
    
    for i in range(num_batches):
        start_idx = i * batch_size
        end_idx = min((i + 1) * batch_size, num_points)
        
        batch_obj_dc = obj_dc_tensor[start_idx:end_idx]
        
        # Logits: (B, C)
        batch_logits = torch.matmul(batch_obj_dc, W.t()) + b
        
        # Predictions: (B)
        batch_predictions = torch.argmax(batch_logits, dim=1)
        all_predictions.append(batch_predictions.cpu())
        
        if i % 10 == 0:
            print(f"Processed batch {i+1}/{num_batches}")

    predictions = torch.cat(all_predictions)
    
    # 4. Analysis
    unique_classes, counts = torch.unique(predictions, return_counts=True)
    num_unique = len(unique_classes)
    
    print(f"\nResults:")
    print(f"Total unique objects/groups found: {num_unique}")
    
    # Sort by count
    sorted_indices = torch.argsort(counts, descending=True)
    top_k = min(20, num_unique)
    
    print(f"\nTop {top_k} most frequent objects (by point count):")
    print(f"{'Class ID':<10} | {'Point Count':<15} | {'Percentage':<10}")
    print("-" * 45)
    
    for i in range(top_k):
        idx = sorted_indices[i]
        class_id = unique_classes[idx].item()
        count = counts[idx].item()
        percentage = (count / num_points) * 100
        print(f"{class_id:<10} | {count:<15} | {percentage:.2f}%")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--model_path", type=str, required=True)
    parser.add_argument("--iteration", type=int, default=30000)
    args = parser.parse_args()
    
    inspect_grouping(args.model_path, args.iteration)
