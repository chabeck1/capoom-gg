# Gaussian Grouping - User Guide

This guide covers the enhanced text-based 3D editing features added to Gaussian Grouping.

## 📁 Project Organization

```
gaussian-grouping/
├── slurm_jobs/              # All SLURM job submission scripts
├── docs_user/               # User documentation and guides
├── scripts_user/            # Helper shell scripts
├── script/                  # Original training scripts
├── config/                  # Configuration files
│   ├── object_removal/      # Removal configs
│   └── object_inpaint/      # Inpainting configs
├── output/                  # Trained models and results
├── data/                    # Training datasets
└── logs/                    # Job output logs
```

## 🚀 Quick Start

### 1. Setup (One Time)

```bash
# Activate environment
source activate_env.sh

# Build CUDA extensions (if not done)
sbatch slurm_jobs/build_extensions.slurm

# Install GroundingDINO for text detection
sbatch slurm_jobs/build_grounding_dino.slurm
```

### 2. Train a Scene

```bash
# Download a dataset (e.g., bear)
wget https://huggingface.co/datasets/dylanebert/gaussian-grouping/resolve/main/bear.zip
unzip bear.zip -d data/

# Train
sbatch slurm_jobs/train_example.slurm
```

### 3. Text-Based Editing

```bash
# Remove objects by text description
sbatch slurm_jobs/edit_by_text_job.slurm output/bear "bear"

# Remove multiple objects
sbatch slurm_jobs/edit_by_text_job.slurm output/bear "bear;rocks;grass"

# Remove and inpaint
sbatch slurm_jobs/edit_by_text_job.slurm output/bear "bear" --inpaint
```

## 📋 SLURM Jobs Reference

### Training & Setup
- **train_example.slurm** - Train Gaussian Grouping on a scene
- **build_extensions.slurm** - Compile CUDA extensions (diff_gaussian_rasterization, simple-knn)
- **build_grounding_dino.slurm** - Compile GroundingDINO CUDA ops

### Editing
- **edit_by_text_job.slurm** - Remove objects by text description (main workflow)
- **removal_job.slurm** - Remove objects by ID (manual)
- **inpaint_job.slurm** - Inpaint after removal (manual)

### Visualization
- **lerf_mask_job.slurm** - Generate text-based object masks
- **render_job.slurm** - Render trained scene
- **viewer_job.slurm** - Launch 3D viewer (requires port forwarding)

## 📚 Documentation

See `docs_user/` for detailed guides:

- **TEXT_EDITING_SUCCESS.txt** - Complete success summary
- **EDIT_BY_TEXT.md** - Detailed text editing guide
- **TEXT_QUERY_GUIDE.md** - How to write effective text queries
- **PROJECT_ROADMAP.md** - Project goals and capabilities
- **QUICK_START.md** - Quick reference
- **SETUP_README.md** - Environment setup notes

## 🛠️ Helper Scripts

In `scripts_user/`:

- **install_grounding_dino.sh** - Install GroundingDINO dependencies
- **view_3d.sh** - Launch interactive 3D viewer

## 💻 Main Commands

### Check Job Status
```bash
squeue -u $USER                    # See running jobs
tail -f logs/<jobname>_*.log       # Watch job output
```

### Download Results
Use VSCode's file explorer to download:
- Renders: `output/<scene>/train/ours_object_removal/iteration_30000/renders/`
- 3D Model: `output/<scene>/point_cloud/iteration_30000/point_cloud.ply`
- Visualizations: `output/<scene>/train/ours_30000_text/`

### View Results
- **2D Renders**: Download PNGs and view locally
- **3D Model**: Upload PLY to [antimatter15.com/splat](https://antimatter15.com/splat)

## 🎯 Example Workflows

### Full Pipeline: Train → Detect → Remove → Inpaint

```bash
# 1. Train scene (~2 hours)
sbatch slurm_jobs/train_example.slurm

# 2. Wait for training to complete
squeue -u $USER

# 3. Remove object by text (~15 minutes)
sbatch slurm_jobs/edit_by_text_job.slurm output/bear "bear"

# 4. Check results
ls output/bear/train/ours_object_removal/iteration_30000/renders/

# 5. Optional: Add inpainting (~1-2 hours)
sbatch slurm_jobs/edit_by_text_job.slurm output/bear "bear" --inpaint
```

### Quick Test: Use Pre-trained Model

```bash
# Download pre-trained model
wget https://huggingface.co/mqye/Gaussian-Grouping/resolve/main/checkpoint/bear.zip

# Remove object
sbatch slurm_jobs/edit_by_text_job.slurm output/bear "bear"
```

### Explore Scene Objects

```bash
# Generate text-based masks for visualization
sbatch slurm_jobs/lerf_mask_job.slurm

# Check what was detected
ls output/bear/train/ours_30000_text/
cat output/bear/train/ours_30000_text/selected_obj_ids.json
```

## 🔧 Configuration Files

### Removal Config
`config/object_removal/<scene>.json`:
```json
{
  "num_classes": 256,
  "removal_thresh": 0.3,
  "select_obj_id": [34, 45, 67]
}
```

### Inpaint Config
`config/object_inpaint/<scene>.json`:
```json
{
  "num_classes": 256
}
```

## 📊 Understanding Object IDs

Each scene has up to 256 object IDs:
- **ID 0**: Background
- **ID 1-255**: Detected objects

View object masks:
```bash
# Color-coded object visualizations
ls output/bear/train/ours_30000/objects_pred/

# Text-detected objects
cat output/bear/train/ours_30000_text/selected_obj_ids.json
```

## ⚠️ Troubleshooting

### Job Fails Immediately
```bash
# Check error
cat logs/<jobname>_<jobid>.log

# Common issues:
# - Out of memory: Increase --mem in SLURM script
# - Time limit: Increase --time
# - CUDA not available: Job not on GPU node (check partition)
```

### Text Detection Finds Nothing
```bash
# Try different descriptions
"bear" vs "teddy bear" vs "statue"

# Check visualization
output/bear/train/ours_30000_text/grounded-sam---<text>.png

# Lower threshold in render_lerf_mask.py (line ~82)
BOX_TRESHOLD = 0.2  # Lower = more detections
```

### Removal Incomplete
```bash
# Lower removal threshold (more aggressive)
# Edit config file:
"removal_thresh": 0.1  # Default is 0.3

# Or specify in edit_by_text.py call:
--removal_thresh 0.1
```

## 📈 Performance Notes

### Timing (NVIDIA A40 GPU)
- Training (30k iterations): ~2 hours
- Object removal: ~10 minutes
- Object inpainting: ~1-2 hours
- Text detection: ~10-15 minutes

### Memory Requirements
- Training: 32GB RAM
- Removal: 32GB RAM
- Inpainting: 64GB RAM (increased for perceptual loss)

### Dataset Sizes
- bear: 407MB (96 images)
- garden: ~1GB (200+ images)
- Custom: Depends on image count

## 🎓 Academic Context

This implementation is based on:

**Gaussian Grouping: Segment and Edit Anything in 3D Scenes**
- Paper: https://arxiv.org/abs/2312.00732
- Project: https://ymq2017.github.io/gaussian-grouping
- ECCV 2024

Key technologies:
- **Gaussian Splatting**: Fast 3D reconstruction
- **SAM**: Segment Anything Model for 2D masks
- **GroundingDINO**: Text-to-image detection
- **IoA Matching**: 2D-to-3D correspondence

## 📞 Support

For issues:
1. Check logs: `logs/<jobname>_<jobid>.log`
2. Review documentation: `docs_user/`
3. See original docs: `docs/`
4. Check GitHub issues: https://github.com/lkeab/gaussian-grouping

## 🎉 What's New

Enhanced features added in this fork:
- ✅ Text-based object removal (`edit_by_text.py`)
- ✅ Automated SLURM job templates
- ✅ GroundingDINO integration
- ✅ Organized project structure
- ✅ Comprehensive documentation
- ✅ Fixed supervision library compatibility
- ✅ Improved error handling

Original capabilities:
- 3D scene reconstruction
- Open-world object segmentation
- Object removal and inpainting
- LERF-style text queries

---

**Quick Links:**
- Training: `sbatch slurm_jobs/train_example.slurm`
- Text Edit: `sbatch slurm_jobs/edit_by_text_job.slurm output/bear "bear"`
- Check Status: `squeue -u $USER`
- View Logs: `tail -f logs/*.log`
