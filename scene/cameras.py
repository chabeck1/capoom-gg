#
# Copyright (C) 2023, Inria
# GRAPHDECO research group, https://team.inria.fr/graphdeco
# All rights reserved.
#
# This software is free for non-commercial, research and evaluation use 
# under the terms of the LICENSE.md file.
#
# For inquiries contact  george.drettakis@inria.fr
#

import torch
from torch import nn
import numpy as np
import os
from utils.graphics_utils import getWorld2View2, getProjectionMatrix
from scipy.spatial.transform import Rotation as R
from PIL import Image
from utils.general_utils import PILtoTorch, PILtoTorchMask

WARNED = False

class Camera(nn.Module):
    def __init__(self, colmap_id, R, T, FoVx, FoVy, image, gt_alpha_mask,
                 image_name, uid,
                 trans=np.array([0.0, 0.0, 0.0]), scale=1.0, data_device = "cuda", objects=None, style_transfer=False,
                 cam_info=None, resolution_args=None
                 ):
        super(Camera, self).__init__()

        self.uid = uid
        self.colmap_id = colmap_id
        self.R = R
        self.T = T
        self.FoVx = FoVx
        self.FoVy = FoVy
        self.image_name = image_name

        try:
            self.data_device = torch.device(data_device)
        except Exception as e:
            print(e)
            print(f"[Warning] Custom device {data_device} failed, fallback to default cuda device" )
            self.data_device = torch.device("cuda")

        # CONSTANT MEMORY MODE: Store paths instead of images
        # Images will be loaded from disk on every access
        if cam_info is not None and resolution_args is not None:
            self._cam_info = cam_info
            self._resolution_args = resolution_args
            self._cached_image = None  # No persistent cache
            self.image_width = cam_info.width
            self.image_height = cam_info.height
        else:
            # Legacy mode: store image in GPU memory (for backward compatibility)
            self.original_image = image.clamp(0.0, 1.0).to(self.data_device)
            self.image_width = self.original_image.shape[2]
            self.image_height = self.original_image.shape[1]

            if gt_alpha_mask is not None:
                self.original_image *= gt_alpha_mask.to(self.data_device)
            else:
                self.original_image *= torch.ones((1, self.image_height, self.image_width), device=self.data_device)
            
            self._cam_info = None

        self.zfar = 100.0
        self.znear = 0.01

        self.trans = trans
        self.scale = scale

        self.world_view_transform = torch.tensor(getWorld2View2(R, T, trans, scale)).transpose(0, 1).cuda()
        self.projection_matrix = getProjectionMatrix(znear=self.znear, zfar=self.zfar, fovX=self.FoVx, fovY=self.FoVy).transpose(0,1).cuda()
        self.full_proj_transform = (self.world_view_transform.unsqueeze(0).bmm(self.projection_matrix.unsqueeze(0))).squeeze(0)
        self.camera_center = self.world_view_transform.inverse()[3, :3]

        # Handle objects - in lazy mode, objects will be loaded on-demand
        if cam_info is not None and resolution_args is not None:
            # Lazy mode - objects loaded on demand via property
            self._cached_objects = None
        else:
            # Legacy mode - store objects directly
            if objects is not None:
                self.objects = objects.to(self.data_device)
            else:
                self.objects = None
        
        if style_transfer:
            self.transfer_image = self.original_image.clone()

    @property
    def original_image(self):
        """Load image on-demand from disk for constant memory usage."""
        if self._cam_info is None:
            # Legacy mode - image already stored
            return self._cached_image
        
        # CONSTANT MEMORY: Load from disk every time (no caching)
        resolution, resolution_scale = self._resolution_args
        
        # Load and process image
        image = Image.open(self._cam_info.image_path)
        
        # Resize if needed
        if resolution in [1, 2, 4, 8]:
            resized_image_rgb = PILtoTorch(image, (self.image_width, self.image_height))
        else:
            if resolution == -1:
                if self.image_width > 1600:
                    global WARNED
                    if not WARNED:
                        print("[ INFO ] Encountered quite large input images (>1.6K pixels width), rescaling to 1.6K.\n "
                            "If this is not desired, please explicitly specify '--resolution/-r' as 1")
                        WARNED = True
                    target_width = 1600
                    scale_factor = target_width / self.image_width
                    resized_width = int(self.image_width * scale_factor)
                    resized_height = int(self.image_height * scale_factor)
                    resized_image_rgb = PILtoTorch(image, (resized_width, resized_height))
                else:
                    resized_image_rgb = PILtoTorch(image, (self.image_width, self.image_height))
            else:
                target_width = resolution
                scale_factor = target_width / self.image_width
                resized_width = int(self.image_width * scale_factor)
                resized_height = int(self.image_height * scale_factor)
                resized_image_rgb = PILtoTorch(image, (resized_width, resized_height))
        
        # Apply resolution scale
        if resolution_scale != 1.0:
            scaled_width = int(resized_image_rgb.shape[2] / resolution_scale)
            scaled_height = int(resized_image_rgb.shape[1] / resolution_scale)
            resized_image_rgb = PILtoTorch(image, (scaled_width, scaled_height))
        
        # Move to device and clamp
        img_tensor = resized_image_rgb.clamp(0.0, 1.0).to(self.data_device)
        
        # Apply alpha mask if needed
        img_tensor *= torch.ones((1, img_tensor.shape[1], img_tensor.shape[2]), device=self.data_device)
        
        return img_tensor
    
    @original_image.setter
    def original_image(self, value):
        """Setter for legacy compatibility."""
        self._cached_image = value

    @property
    def objects(self):
        """Load object mask on-demand from disk for constant memory usage."""
        if self._cam_info is None:
            # Legacy mode - objects already stored
            return self._cached_objects
        
        # CONSTANT MEMORY: Load objects from disk every time (no caching)
        if hasattr(self._cam_info, 'object_path') and self._cam_info.object_path and os.path.exists(self._cam_info.object_path):
            objects_pil = Image.open(self._cam_info.object_path)
            
            # Resize to match image dimensions
            resolution, resolution_scale = self._resolution_args
            if resolution in [1, 2, 4, 8]:
                resized_objects = PILtoTorchMask(objects_pil, (self.image_width, self.image_height))
            else:
                # Match the same resizing logic as the image
                if resolution == -1:
                    if self.image_width > 1600:
                        target_width = 1600
                        scale_factor = target_width / self.image_width
                        resized_width = int(self.image_width * scale_factor)
                        resized_height = int(self.image_height * scale_factor)
                        resized_objects = PILtoTorchMask(objects_pil, (resized_width, resized_height))
                    else:
                        resized_objects = PILtoTorchMask(objects_pil, (self.image_width, self.image_height))
                else:
                    target_width = resolution
                    scale_factor = target_width / self.image_width
                    resized_width = int(self.image_width * scale_factor)
                    resized_height = int(self.image_height * scale_factor)
                    resized_objects = PILtoTorchMask(objects_pil, (resized_width, resized_height))
            
            # Apply resolution scale
            if resolution_scale != 1.0:
                scaled_width = int(resized_objects.shape[2] / resolution_scale)
                scaled_height = int(resized_objects.shape[1] / resolution_scale)
                resized_objects = PILtoTorchMask(objects_pil, (scaled_width, scaled_height))
            
            # Return as [1, H, W] to match expected format in train.py
            objects_tensor = resized_objects.to(self.data_device)
            return objects_tensor
        else:
            return None
    
    @objects.setter
    def objects(self, value):
        """Setter for legacy compatibility."""
        self._cached_objects = value


class MiniCam:
    def __init__(self, width, height, fovy, fovx, znear, zfar, world_view_transform, full_proj_transform):
        self.image_width = width
        self.image_height = height    
        self.FoVy = fovy
        self.FoVx = fovx
        self.znear = znear
        self.zfar = zfar
        self.world_view_transform = world_view_transform
        self.full_proj_transform = full_proj_transform
        view_inv = torch.inverse(self.world_view_transform)
        self.camera_center = view_inv[3][:3]

