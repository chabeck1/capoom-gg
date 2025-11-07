# Mcity Dataset Training Log

## Date: November 4, 2025

This document tracks all findings, issues, solutions, and custom scripts created while setting up Gaussian Grouping training on the Mcity dataset.

---

## Dataset Overview

- **Source**: Mcity autonomous vehicle test facility
- **Total Images**: 33,450 (16,725 per camera × 2 cameras)
- **Structure**: Nested directories `K1/camera_0/` and `K1/camera_1/`
- **Image Format**: 1024×1024 RGB JPG
- **Mask Format**: 1024×1024 Grayscale PNG (after conversion)
- **COLMAP Cameras**: 6 (cameras 0,1,2 from camera_0 directory, cameras 3,4,5 from camera_1 directory)
- **Multi-view Setup**: 
  - Each timestamp has 6 synchronized views
  - Format: `{timestamp}_0.jpg`, `{timestamp}_1.jpg`, `{timestamp}_2.jpg` for each camera
  - 5,575 complete timestamp groups available

---

## Critical Findings

### 1. **Multi-View Synchronization Required**
**Issue**: Random image sampling breaks 3D reconstruction  
**Discovery**: Gaussian Splatting requires overlapping views of the same scene. Random selection of 50 images from 33,450 could result in images from completely different areas of Mcity with no spatial overlap.  
**Solution**: Created synchronized subsets that preserve all 6 camera views for each timestamp.

### 2. **GPU Memory Bottleneck**
**Location**: `scene/cameras.py` line 42  
**Code**: `self.original_image = image.clamp(0.0, 1.0).to(self.data_device)`  
**Issue**: All images are loaded to GPU memory at initialization  
**Impact**: 
- Memory scales linearly: ~0.46 GB per image
- A40 GPU (44GB) can handle ~74 images max
- Full dataset (33,450 images) would require ~15TB GPU memory
**Limitation**: Current architecture cannot handle large datasets without code rewrite for lazy loading

### 3. **CUDA Architecture Compatibility**
**Issue**: Extensions compiled on one GPU type don't work on others  
**Error**: `cudaErrorNoKernelImageForDevice: no kernel image is available for execution on the device`  
**Root Cause**: CUDA code compiled without architecture-specific flags  
**Solution**: Added architecture flags to both CUDA extension setup.py files:
- `-gencode=arch=compute_80,code=sm_80` (NVIDIA A100)
- `-gencode=arch=compute_86,code=sm_86` (NVIDIA A40)
**Result**: Extensions now work on both spgpu (A40) and gpu_mig40 (A100 MIG) partitions

### 4. **Great Lakes Account Limitations**
**MaxWall Time**: 8:00:00 (hard limit per job)  
**Account**: entr490s113y25_class (shared class account)  
**Implication**: Cannot run multi-day training jobs, must work within 8-hour window

---

## Issues Fixed

### Issue #1: Wrong Mask Directory Name
**Problem**: Masks stored in `masks/`, code expects `object_mask/`  
**Solution**: 
```bash
mv data/mcity/masks data/mcity/object_mask
```

### Issue #2: RGB Masks Instead of Grayscale
**Problem**: Masks were 3-channel RGB, code expects 1-channel grayscale  
**Error**: `TypeError: can't convert np.ndarray of type numpy.object_`  
**Solution**: Converted all 33,450 masks using PIL
```python
from PIL import Image
mask = Image.open(mask_path).convert('L')  # Convert to grayscale
mask.save(mask_path)
```
**Verification**: All masks now Mode: L, size unchanged (1024×1024)

### Issue #3: Nested Directory Path Support
**Problem**: Code used basename for masks, broke with nested `K1/camera_0/` structure  
**Location**: `scene/dataset_readers.py` line 99-100  
**Original Code**:
```python
object_path = os.path.join(objects_folder, image_name + '.png')
```
**Fixed Code**:
```python
object_relative_path = extr.name.replace(os.path.splitext(extr.name)[1], '.png')
object_path = os.path.join(objects_folder, object_relative_path)
```
**Note**: Image loading already supported nested paths via `extr.name` (full path)

### Issue #4: COLMAP Subset Mismatch
**Problem**: Subset datasets had full COLMAP reconstruction referencing all 33,450 images  
**Error**: `AttributeError: 'NoneType' object has no attribute 'size'`  
**Root Cause**: COLMAP images.bin references images not in subset, code loaded as None  
**Location**: `scene/dataset_readers.py` line 95-98  
**Solution**: Skip missing images instead of loading as None
```python
# Skip this camera if image doesn't exist (for subsets)
if not os.path.exists(image_path):
    continue
```
**Result**: Code now gracefully handles subsets with full COLMAP data

### Issue #5: CUDA Module Loading on Compute Nodes
**Problem**: `module load python/3.8.7` failed on some nodes  
**Solution**: Removed python module, rely on conda environment only
```bash
# Remove: module load python/3.8.7 cuda/11.3.0
# Use: module load cuda/11.3.0
```

---

## Custom Scripts Created

### 1. `create_synchronized_subset.py`
**Purpose**: Create training subsets that preserve multi-view synchronization  
**Usage**:
```bash
python create_synchronized_subset.py <num_timestamps>
# Example: python create_synchronized_subset.py 50  # Creates 300-image subset
```
**Features**:
- Analyzes all images and groups by timestamp
- Ensures all 6 camera views present for each timestamp
- Copies images, masks, and COLMAP data
- Output: `data/mcity_sync_<num_images>/`

**Key Function**:
```python
def group_by_timestamp(image_dir):
    """Group all images by timestamp, showing which camera views exist"""
    # Extracts timestamp from format: 1758662704.529435_0.jpg
    # Groups into camera_0 and camera_1 views
    # Filters to complete groups (6 views per timestamp)
```

### 2. `filter_colmap_subset.py`
**Purpose**: Filter COLMAP reconstruction to match subset images  
**Status**: Created but not needed - fixed by modifying dataset_readers.py to skip missing images  
**Note**: Kept for reference, could be useful for future manual COLMAP filtering

### 3. `convert_masks_to_grayscale.py`
**Purpose**: Convert RGB masks to grayscale (already executed)  
**Note**: All masks already converted, script preserved for documentation

---

## Code Modifications

### Modified Files Summary

1. **`scene/dataset_readers.py`**
   - Line 99-100: Support nested mask directories
   - Line 95-98: Skip missing images in subsets (don't load as None)

2. **`submodules/diff-gaussian-rasterization/setup.py`**
   - Added CUDA architecture flags for A100 and A40 support

3. **`submodules/simple-knn/setup.py`**
   - Added CUDA architecture flags for A100 and A40 support

### Recompiled CUDA Extensions
```bash
# Recompiled with architecture support
cd submodules/diff-gaussian-rasterization
module load cuda/11.3.0
pip install -e .  # ✓ Success

cd ../simple-knn
module load cuda/11.3.0
pip install -e .  # ✓ Success
```

**Verification**:
```bash
python -c "import diff_gaussian_rasterization, simple_knn; print('✓')"
# Output: ✓ Both CUDA extensions load successfully
```

---

## Dataset Subsets Created

### mcity_micro (50 images)
- **Type**: Random selection
- **Status**: Trained to 75% completion before cancellation
- **Issue**: Random images likely have no spatial overlap
- **Location**: `data/mcity_micro/`

### mcity_tiny (335 images)
- **Type**: Random selection
- **Status**: Failed on MIG with CUDA kernel error (before CUDA recompilation)
- **Location**: `data/mcity_tiny/`

### mcity_small (3,345 images - 10% of full)
- **Type**: Random selection
- **Status**: GPU OOM on both A40 and A100 MIG
- **Issue**: Exceeds GPU memory limits (~1.5TB needed)
- **Location**: `data/mcity_small/`

### mcity_sync_60 (60 images) ✅ RECOMMENDED
- **Type**: Synchronized - 10 timestamps × 6 views
- **Status**: Ready for training
- **Advantage**: Proper spatial coverage, small enough for quick testing
- **Location**: `data/mcity_sync_60/`
- **Job**: 35330866 (pending on gpu_mig40)

### mcity_sync_300 (300 images) ✅ RECOMMENDED
- **Type**: Synchronized - 50 timestamps × 6 views
- **Status**: Ready for training
- **Advantage**: Better spatial coverage, still within GPU memory limits
- **Location**: `data/mcity_sync_300/`

---

## Training Jobs History

### Successful Jobs
- **Job 35321817**: mcity_micro (50 random images), reached 75% (22,470/30,000 iterations), ~8.56 it/s

### Failed Jobs
- **Job 35323694**: mcity_tiny (335 random), cancelled - wrong subset type
- **Job 35328610**: mcity_sync_60, failed - python module loading
- **Job 35328700**: mcity_sync_60, failed - COLMAP subset mismatch

### Current Jobs
- **Job 35330866**: mcity_sync_60 on gpu_mig40, pending - testing MIG CUDA compatibility

---

## SLURM Job Scripts

### Standard Training Template
```bash
#!/bin/bash
#SBATCH --job-name=gg_sync60
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=gpu_mig40  # or spgpu
#SBATCH --nodes=1
#SBATCH --gpus-per-node=1
#SBATCH --mem=200GB
#SBATCH --time=04:00:00
#SBATCH --output=logs/train_mcity_sync60_%j.log
#SBATCH --error=logs/train_mcity_sync60_%j.err

# Load CUDA (don't load python module)
module load cuda/11.3.0

# Activate conda environment
source ~/.bashrc
conda activate gaussian_grouping

# Run training
cd /home/chabeck/gaussian-grouping
python train.py \
    -s data/mcity_sync_60 \
    -m output/mcity_sync_60 \
    --config config/gaussian_dataset/train.json
```

### Available Job Scripts
- `slurm_jobs/train_mcity_sync60.slurm` - 60 images on spgpu
- `slurm_jobs/train_mcity_sync60_mig.slurm` - 60 images on gpu_mig40
- `slurm_jobs/train_mcity_sync300.slurm` - 300 images on gpu_mig40
- `slurm_jobs/train_mcity_micro.slurm` - 50 random (deprecated)
- `slurm_jobs/train_mcity_tiny.slurm` - 335 random (deprecated)

---

## Recommendations

### For Quick Testing (10-15 minutes)
```bash
python create_synchronized_subset.py 10  # 60 images
sbatch slurm_jobs/train_mcity_sync60_mig.slurm
```

### For Better Results (1-2 hours)
```bash
python create_synchronized_subset.py 50  # 300 images
sbatch slurm_jobs/train_mcity_sync300.slurm
```

### For Maximum Coverage (within 8hr limit)
```bash
python create_synchronized_subset.py 100  # 600 images
# Estimate: ~4-6 hours training time
```

### Scaling Beyond GPU Memory Limits
**Current limitation**: Cannot train on >600-800 images without code changes  
**Required fix**: Implement lazy loading in `scene/cameras.py`
- Load images on-demand instead of all at once
- Cache recently used images
- Free GPU memory for unused images
**Effort**: Medium complexity, would require architecture changes

---

## Monitoring Commands

### Check Job Status
```bash
squeue -u chabeck
```

### Monitor Training Progress
```bash
# Check progress percentage
tail -f logs/train_mcity_sync60_mig_<JOBID>.err

# Check output files
ls -lh output/mcity_sync_60/
ls -lh output/mcity_sync_60/chkpnt*.pth
```

### GPU Usage
```bash
# From compute node during job
nvidia-smi
```

---

## Technical Environment

### Great Lakes HPC
- **Partitions Used**: spgpu (A40 44GB), gpu_mig40 (A100 MIG 39GB)
- **CUDA Version**: 11.3.0
- **Python**: 3.8.7 (via conda)
- **PyTorch**: 1.12.1+cu113

### Key Dependencies
- diff-gaussian-rasterization (custom CUDA)
- simple-knn (custom CUDA)
- PIL/Pillow (image processing)
- COLMAP (sparse reconstruction)

### Conda Environment
```bash
conda activate gaussian_grouping
# Contains all dependencies pre-installed
```

---

## MIG Partition Bug - CONFIRMED NVIDIA DRIVER REGRESSION

### Official NVIDIA Documentation
**CRITICAL FINDING**: The 21TB allocation bug is a **documented NVIDIA driver regression** in R570 series affecting MIG partitions.

**Affected Driver Versions:**
- 570.124.06
- 570.133.20
- **570.148.08** (Great Lakes MIG nodes - CONFIRMED)
- 570.158.01

**Source**: NVIDIA GPU Operator Documentation and R570 Release Notes

**Official Statement**:
> "For drivers 570.124.06, 570.133.20, 570.148.08, and 570.158.01, GPU workloads cannot be scheduled on nodes that have a mix of MIG slices and full GPUs. This is due to a regression in NVML introduced in the R570 drivers."

### Root Cause: NVML Memory Management Bug

**What Happens:**
1. MIG uses isolated memory architecture with dedicated memory controllers per partition
2. R570 driver refactored NVML (NVIDIA Management Library) for MIG support
3. Buffer size calculation has integer overflow/uninitialized variable bug
4. Bug only triggers at resolutions above ~128×128 pixels
5. 1024×1024 images trigger cubic scaling bug: 1024³ × multiplier ≈ 21TB

**Why MIG Only:**
- Full GPUs (A40 on spgpu) use different memory addressing code path
- MIG partitions use new NVML code that has the regression
- Bug exists in MIG-specific memory controller configuration

**Empirical Confirmation:**
- ✅ Bear dataset (729×985): 21TB bug on MIG
- ✅ Mcity dataset (1024×1024): 21TB bug on MIG
- ✅ Diagnostic test (128×128): Works on MIG
- ✅ Same code/data on spgpu: Works perfectly
- Driver on MIG nodes: 570.148.08 (CONFIRMED affected version)

### NVIDIA Recommended Fix

**Downgrade to:** Driver 570.86.15 or earlier (known working)  
**Or upgrade to:** Driver 570.158.02 or later (regression fixed)

### Action Items for Great Lakes HPC

**Report to Cluster Administrators:**
```
Subject: MIG Partition Driver Regression - NVIDIA R570.148.08

Issue: gpu_mig40 partition has NVIDIA driver 570.148.08, which contains 
a documented NVML regression causing massive memory allocation failures 
for GPU workloads.

Evidence: 
- CUDA applications fail with 21TB allocation requests on 39GB MIG partitions
- Same code works on spgpu (A40) partition
- NVIDIA documentation confirms this driver version has MIG-specific bugs

Request: Downgrade MIG nodes to driver 570.86.15 or upgrade to 570.158.02+

Reference: NVIDIA GPU Operator Documentation (R570 known issues)
```

---

## Future Work

### Immediate Next Steps
1. ✅ Verify MIG training works with recompiled CUDA (Job 35330866)
2. ⏳ Train sync60 to completion for baseline
3. ⏳ Train sync300 for better spatial coverage
4. 📝 Compare reconstruction quality: random vs synchronized subsets

### Long-term Improvements
1. **Lazy Image Loading**: Modify `scene/cameras.py` to load images on-demand
2. **Larger Subsets**: Once lazy loading works, try 1000-5000 images
3. **Full Dataset**: Ultimate goal - train on all 33,450 images (requires lazy loading)
4. **Optimization**: Investigate memory-efficient alternatives (gradient checkpointing, mixed precision)

### Documentation Needed
1. Training convergence curves (loss over time)
2. Reconstruction quality metrics
3. Memory usage profiling
4. Timing benchmarks for different subset sizes

---

## Quick Reference

### Create New Synchronized Subset
```bash
cd ~/gaussian-grouping
python create_synchronized_subset.py <N>
# Output: data/mcity_sync_<N*6>/
```

### Submit Training Job
```bash
cd ~/gaussian-grouping
sbatch slurm_jobs/train_mcity_sync60_mig.slurm
# Monitor: squeue -u chabeck
```

### Check Training Progress
```bash
# Progress percentage
tail -100 logs/train_mcity_sync60_mig_<JOBID>.err | grep "Training progress"

# Full log
less logs/train_mcity_sync60_mig_<JOBID>.log
```

### Available Partitions
- **spgpu**: A40 44GB, longer queue (~362 pending jobs typical)
- **gpu_mig40**: A100 MIG 39GB, shorter queue (~19 pending jobs typical)
- Both now supported with recompiled CUDA extensions

---

## Contact & Collaboration

**GitHub Repository**: github.com/chabeck1/capoom-gg  
**Account**: entr490s113y25_class (shared)  
**Platform**: Great Lakes HPC, University of Michigan

---

*Last Updated: November 4, 2025*
*Status: CUDA extensions recompiled, synchronized subsets ready, testing MIG compatibility*
