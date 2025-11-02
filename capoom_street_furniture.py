#!/usr/bin/env python3
"""
Capoom Street Furniture Detection & Cataloging System

Purpose: Detect and extract street furniture for AV testing digital twins
         Build a reusable catalog of 3D assets (stop signs, traffic lights, etc.)

Usage:
    # Detect all street furniture in a scene
    python capoom_street_furniture.py --scene output/street_scene --mode detect
    
    # Extract specific objects to catalog
    python capoom_street_furniture.py --scene output/street_scene --mode extract \
        --objects "stop sign;traffic light;fire hydrant"
    
    # Add catalog object to new scene
    python capoom_street_furniture.py --target output/test_scene --mode add \
        --catalog catalog/stop_sign_001.ply --position "2.0,0.0,1.5"
"""

import torch
import json
import os
import sys
from pathlib import Path
from typing import List, Dict, Tuple
import numpy as np
from scene import Scene, GaussianModel
from gaussian_renderer import render
from argparse import ArgumentParser

# Street furniture categories for AV testing
STREET_FURNITURE_CATEGORIES = {
    'traffic_control': [
        'stop sign', 'yield sign', 'speed limit sign', 'traffic light',
        'pedestrian signal', 'railroad crossing', 'construction sign'
    ],
    'street_infrastructure': [
        'fire hydrant', 'street light', 'lamp post', 'utility pole',
        'traffic cone', 'barrier', 'bollard', 'parking meter'
    ],
    'pedestrian': [
        'bench', 'trash can', 'mailbox', 'bike rack', 'bus stop',
        'crosswalk', 'sidewalk', 'curb'
    ],
    'vehicles': [
        'car', 'truck', 'bus', 'motorcycle', 'bicycle', 'pedestrian'
    ]
}


class StreetFurnitureDetector:
    """
    Detects street furniture in Gaussian Grouping scenes using GroundingDINO
    """
    
    def __init__(self, scene_path: str):
        self.scene_path = scene_path
        self.detections = {}
        
    def detect_all_street_furniture(self) -> Dict:
        """
        Run detection on all street furniture categories
        Returns mapping of category -> object IDs
        """
        from render_lerf_mask import render_sets
        from arguments import ModelParams, PipelineParams
        
        all_queries = []
        for category, items in STREET_FURNITURE_CATEGORIES.items():
            all_queries.extend(items)
        
        # Create detection query string
        query_string = ";".join(all_queries)
        
        print(f"Detecting street furniture: {query_string}")
        
        # Run render_lerf_mask for each item
        detections = {}
        for item in all_queries:
            obj_ids_file = os.path.join(
                self.scene_path, 
                "train/ours_30000_text",
                f"object_ids---{item}.json"
            )
            
            # Check if already detected
            if os.path.exists(obj_ids_file):
                with open(obj_ids_file, 'r') as f:
                    data = json.load(f)
                    if data['object_ids']:
                        detections[item] = data['object_ids']
                        print(f"✓ Found {item}: {data['object_ids']}")
            else:
                print(f"⚠ Need to detect: {item}")
        
        self.detections = detections
        return detections
    
    def export_detection_report(self, output_path: str):
        """
        Export detection results for analysis
        """
        report = {
            'scene': self.scene_path,
            'total_objects': len(self.detections),
            'categories': {},
            'object_mapping': self.detections
        }
        
        # Categorize detections
        for category, items in STREET_FURNITURE_CATEGORIES.items():
            found = {item: self.detections.get(item, []) for item in items if item in self.detections}
            if found:
                report['categories'][category] = found
        
        with open(output_path, 'w') as f:
            json.dump(report, f, indent=2)
        
        print(f"Detection report saved: {output_path}")


class StreetFurnitureExtractor:
    """
    Extract individual street furniture objects into reusable catalog
    """
    
    def __init__(self, scene_path: str, catalog_dir: str = "catalog"):
        self.scene_path = scene_path
        self.catalog_dir = Path(catalog_dir)
        self.catalog_dir.mkdir(exist_ok=True)
        
    def extract_object_by_id(
        self, 
        object_ids: List[int], 
        object_name: str,
        extraction_thresh: float = 0.5
    ) -> Dict:
        """
        Extract Gaussians belonging to specific object IDs
        Saves to catalog with metadata
        """
        # Load scene
        print(f"Loading scene from {self.scene_path}")
        
        # Load gaussians directly from saved checkpoint
        gaussians = GaussianModel(sh_degree=3)
        
        # Load iteration files
        iteration_path = os.path.join(self.scene_path, "point_cloud/iteration_30000")
        if not os.path.exists(iteration_path):
            print(f"ERROR: Iteration path not found: {iteration_path}")
            sys.exit(1)
        
        # Load point cloud
        gaussians.load_ply(os.path.join(iteration_path, "point_cloud.ply"))
        print(f"Loaded {len(gaussians._xyz)} Gaussians")
        
        # Load classifier
        num_classes = 256
        classifier = torch.nn.Conv2d(gaussians.num_objects, num_classes, kernel_size=1).cuda()
        classifier_path = os.path.join(iteration_path, "classifier.pth")
        if not os.path.exists(classifier_path):
            print(f"ERROR: Classifier not found: {classifier_path}")
            sys.exit(1)
        classifier.load_state_dict(torch.load(classifier_path))
        
        # Get probability mask for object
        with torch.no_grad():
            logits3d = classifier(gaussians._objects_dc.permute(2, 0, 1))
            prob_obj3d = torch.softmax(logits3d, dim=0)
            
            # Mask for selected objects (KEEP these, not remove)
            mask3d = prob_obj3d[torch.tensor(object_ids).cuda(), :, :] > extraction_thresh
            mask3d = mask3d.any(dim=0).squeeze()
        
        print(f"Extracting {mask3d.sum().item()} Gaussians for '{object_name}'")
        
        # Extract Gaussian parameters
        extracted = {
            'xyz': gaussians._xyz[mask3d].cpu(),
            'features_dc': gaussians._features_dc[mask3d].cpu(),
            'features_rest': gaussians._features_rest[mask3d].cpu(),
            'scaling': gaussians._scaling[mask3d].cpu(),
            'rotation': gaussians._rotation[mask3d].cpu(),
            'opacity': gaussians._opacity[mask3d].cpu(),
            'objects_dc': gaussians._objects_dc[mask3d].cpu(),
        }
        
        # Calculate bounding box for metadata
        bbox_min = extracted['xyz'].min(dim=0)[0].detach().cpu().numpy()
        bbox_max = extracted['xyz'].max(dim=0)[0].detach().cpu().numpy()
        centroid = extracted['xyz'].mean(dim=0).detach().cpu().numpy()
        
        # Metadata
        metadata = {
            'name': object_name,
            'object_ids': object_ids,
            'source_scene': self.scene_path,
            'num_gaussians': mask3d.sum().item(),
            'bbox_min': bbox_min.tolist(),
            'bbox_max': bbox_max.tolist(),
            'centroid': centroid.tolist(),
            'size': (bbox_max - bbox_min).tolist()
        }
        
        # Save to catalog
        catalog_name = object_name.replace(' ', '_')
        catalog_path = self.catalog_dir / catalog_name
        catalog_path.mkdir(exist_ok=True)
        
        # Save Gaussians as .pt file
        torch.save(extracted, catalog_path / "gaussians.pt")
        
        # Save metadata
        with open(catalog_path / "metadata.json", 'w') as f:
            json.dump(metadata, f, indent=2)
        
        print(f"✓ Saved to catalog: {catalog_path}")
        return extracted, metadata


class SceneComposer:
    """
    Add/remove street furniture from scenes for AV testing
    """
    
    def __init__(self, scene_path: str, catalog_dir: str = "catalog"):
        self.scene_path = scene_path
        self.catalog_dir = Path(catalog_dir)
        
    def add_object_from_catalog(
        self,
        catalog_name: str,
        position: Tuple[float, float, float],
        rotation: Tuple[float, float, float] = (0, 0, 0),
        scale: float = 1.0
    ):
        """
        Add a catalog object to the scene at specified position
        
        Args:
            catalog_name: Name of catalog object (e.g., 'stop_sign')
            position: (x, y, z) world coordinates
            rotation: (rx, ry, rz) Euler angles in degrees
            scale: Uniform scale factor
        """
        catalog_path = self.catalog_dir / catalog_name
        
        # Load catalog object
        gaussians_data = torch.load(catalog_path / "gaussians.pt")
        with open(catalog_path / "metadata.json", 'r') as f:
            metadata = json.load(f)
        
        print(f"Loading '{metadata['name']}' from catalog...")
        print(f"  Gaussians: {metadata['num_gaussians']}")
        print(f"  Original centroid: {metadata['centroid']}")
        
        # Load target scene Gaussians directly
        print(f"Loading target scene from {self.scene_path}")
        target_gaussians = GaussianModel(sh_degree=3)
        
        # Load iteration files
        iteration_path = os.path.join(self.scene_path, "point_cloud/iteration_30000")
        if not os.path.exists(iteration_path):
            print(f"ERROR: Iteration path not found: {iteration_path}")
            sys.exit(1)
        
        # Load point cloud
        target_gaussians.load_ply(os.path.join(iteration_path, "point_cloud.ply"))
        print(f"Loaded {len(target_gaussians._xyz)} Gaussians from target scene")
        
        # Transform catalog object
        transformed = self._transform_gaussians(
            gaussians_data,
            position=position,
            rotation=rotation,
            scale=scale,
            original_centroid=np.array(metadata['centroid'])
        )
        
        # Merge with scene
        merged = self._merge_gaussians(target_gaussians, transformed)
        
        # Save modified scene
        output_path = os.path.join(self.scene_path, "point_cloud/iteration_30000_modified")
        os.makedirs(output_path, exist_ok=True)
        merged.save_ply(os.path.join(output_path, "point_cloud.ply"))
        
        print(f"✓ Scene modified: {output_path}")
        
    def _transform_gaussians(
        self, 
        gaussians_data: Dict,
        position: Tuple[float, float, float],
        rotation: Tuple[float, float, float],
        scale: float,
        original_centroid: np.ndarray
    ) -> Dict:
        """
        Apply 3D transformation to Gaussian parameters
        """
        import math
        
        # Center object at origin
        xyz = gaussians_data['xyz'].clone()
        xyz -= torch.from_numpy(original_centroid).float()
        
        # Apply scale
        xyz *= scale
        gaussians_data['scaling'] = gaussians_data['scaling'].clone() * scale
        
        # Apply rotation (Euler angles to rotation matrix)
        rx, ry, rz = [math.radians(r) for r in rotation]
        Rx = torch.tensor([
            [1, 0, 0],
            [0, math.cos(rx), -math.sin(rx)],
            [0, math.sin(rx), math.cos(rx)]
        ], dtype=torch.float32)
        
        Ry = torch.tensor([
            [math.cos(ry), 0, math.sin(ry)],
            [0, 1, 0],
            [-math.sin(ry), 0, math.cos(ry)]
        ], dtype=torch.float32)
        
        Rz = torch.tensor([
            [math.cos(rz), -math.sin(rz), 0],
            [math.sin(rz), math.cos(rz), 0],
            [0, 0, 1]
        ], dtype=torch.float32)
        
        R = Rz @ Ry @ Rx
        xyz = (R @ xyz.T).T
        
        # Apply translation
        xyz += torch.tensor(position, dtype=torch.float32)
        gaussians_data['xyz'] = xyz
        
        # TODO: Also transform rotation quaternions
        
        return gaussians_data
    
    def _merge_gaussians(self, target: GaussianModel, source_data: Dict) -> GaussianModel:
        """
        Merge source Gaussians into target scene
        """
        # Concatenate all parameters (ensure all on CUDA)
        target._xyz = torch.cat([
            target._xyz, 
            source_data['xyz'].cuda()
        ], dim=0)
        
        target._features_dc = torch.cat([
            target._features_dc,
            source_data['features_dc'].cuda()
        ], dim=0)
        
        target._features_rest = torch.cat([
            target._features_rest,
            source_data['features_rest'].cuda()
        ], dim=0)
        
        target._scaling = torch.cat([
            target._scaling,
            source_data['scaling'].cuda()
        ], dim=0)
        
        target._rotation = torch.cat([
            target._rotation,
            source_data['rotation'].cuda()
        ], dim=0)
        
        target._opacity = torch.cat([
            target._opacity,
            source_data['opacity'].cuda()
        ], dim=0)
        
        target._objects_dc = torch.cat([
            target._objects_dc,
            source_data['objects_dc'].cuda()
        ], dim=0)
        
        return target


def main():
    parser = ArgumentParser(description="Capoom Street Furniture Tool")
    parser.add_argument("--scene", required=True, help="Path to scene")
    parser.add_argument("--mode", required=True, choices=['detect', 'extract', 'add', 'remove'])
    parser.add_argument("--objects", type=str, help="Semicolon-separated object names")
    parser.add_argument("--catalog", type=str, default="catalog", help="Catalog directory")
    parser.add_argument("--target", type=str, help="Target scene for 'add' mode")
    parser.add_argument("--position", type=str, help="x,y,z position for 'add' mode")
    parser.add_argument("--rotation", type=str, default="0,0,0", help="rx,ry,rz rotation")
    parser.add_argument("--scale", type=float, default=1.0, help="Scale factor")
    parser.add_argument("--output", type=str, help="Output path")
    
    args = parser.parse_args()
    
    if args.mode == 'detect':
        detector = StreetFurnitureDetector(args.scene)
        detections = detector.detect_all_street_furniture()
        report_path = args.output or os.path.join(args.scene, "street_furniture_report.json")
        detector.export_detection_report(report_path)
        
    elif args.mode == 'extract':
        if not args.objects:
            print("Error: --objects required for extract mode")
            return
        
        extractor = StreetFurnitureExtractor(args.scene, args.catalog)
        
        for obj_name in args.objects.split(';'):
            # First detect to get object IDs
            obj_ids_file = os.path.join(
                args.scene,
                "train/ours_30000_text",
                f"object_ids---{obj_name}.json"
            )
            
            if os.path.exists(obj_ids_file):
                with open(obj_ids_file, 'r') as f:
                    data = json.load(f)
                    object_ids = data['object_ids']
                    
                if object_ids:
                    extractor.extract_object_by_id(object_ids, obj_name)
                else:
                    print(f"⚠ No objects found for '{obj_name}'")
            else:
                print(f"⚠ Run detection first for '{obj_name}'")
    
    elif args.mode == 'add':
        if not args.objects or not args.position:
            print("Error: --objects and --position required for add mode")
            return
        
        target_scene = args.target or args.scene
        composer = SceneComposer(target_scene, args.catalog)
        
        position = tuple(map(float, args.position.split(',')))
        rotation = tuple(map(float, args.rotation.split(',')))
        
        catalog_name = args.objects.replace(' ', '_')
        composer.add_object_from_catalog(
            catalog_name=catalog_name,
            position=position,
            rotation=rotation,
            scale=args.scale
        )


if __name__ == "__main__":
    main()
