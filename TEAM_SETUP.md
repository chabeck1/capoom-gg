# CAPOOM-GG Team Setup Guide

This repository contains our CAPOOM project implementation of Gaussian Grouping for AV testing digital twin creation.

## 🎯 Project Overview

**Goal**: Build digital twins of street scenes with ability to detect, extract, and manipulate street furniture (signs, lights, hydrants) for autonomous vehicle testing scenarios.

**Capabilities**:
- 3D scene reconstruction from images
- Automatic object segmentation (50+ objects per scene)
- Text-based object detection ("stop sign", "fire hydrant")
- Catalog system for reusable 3D assets
- Object removal, addition, and inpainting

## 📋 Prerequisites

Access to **ARC @ Great Lakes HPC** with:
- Account: `entr490s113y25_class`
- Partition: `spgpu` (GPU nodes)
- Storage: At least 50GB free space

## 🚀 Quick Start

### 1. Clone Repository

```bash
ssh YOUR_USERNAME@greatlakes.arc-ts.umich.edu
cd ~
git clone git@github.com:chabeck1/capoom-gg.git
cd capoom-gg
```

### 2. Install Dependencies

```bash
# Load required modules
module load python3.10-anaconda cuda/11.3.0

# Create conda environment
conda create -n gaussian_grouping python=3.8 -y
conda activate gaussian_grouping

# Install PyTorch with CUDA 11.3
pip install torch==1.12.1+cu113 torchvision==0.13.1+cu113 --extra-index-url https://download.pytorch.org/whl/cu113

# Install other dependencies
pip install tqdm plyfile submodules/diff-gaussian-rasterization submodules/simple-knn
pip install pillow lpips opencv-python torchmetrics
```

### 3. Build CUDA Extensions

This is **required** and must be done on a GPU node:

```bash
# Submit build job
sbatch slurm_jobs/build_extensions.slurm

# Monitor build
squeue -u $USER
tail -f logs/build_*.log

# Should complete in ~10 minutes
```

### 4. Install GroundingDINO (for text-based detection)

```bash
# Run the installation script
bash scripts_user/install_grounding_dino.sh

# This installs:
# - GroundedSAM
# - Segment Anything Model (SAM)
# - GroundingDINO
# - Required CUDA kernels
```

### 5. Verify Installation

```bash
# Activate environment
conda activate gaussian_grouping

# Test imports
python -c "import torch; print(f'PyTorch: {torch.__version__}, CUDA: {torch.cuda.is_available()}')"
python -c "import diff_gaussian_rasterization; print('CUDA extensions OK')"

# All should succeed without errors
```

## 📂 Repository Structure

```
capoom-gg/
├── README.md                    # Original Gaussian Grouping README
├── TEAM_SETUP.md               # This file
├── docs_user/                  # Our team documentation
│   ├── CAPOOM_WORKFLOW.md      # Main workflow guide (START HERE)
│   ├── QUICK_START.md          # Quick reference
│   └── USER_GUIDE.md           # Comprehensive guide
├── slurm_jobs/                 # SLURM job scripts
│   ├── train_example.slurm     # Train a scene
│   ├── catalog_extract_job.slurm
│   ├── catalog_add_job.slurm
│   └── edit_by_text_job.slurm
├── scripts_user/               # Helper scripts
│   ├── setup_env.sh            # Activate environment
│   ├── check_status.sh         # Check job status
│   └── validate_catalog.sh     # Validate catalog
├── data/                       # Training data (not in repo)
├── output/                     # Model outputs (not in repo)
└── catalog/                    # 3D object catalog (not in repo)
```

## 📖 Next Steps

After setup, read these in order:

1. **CAPOOM_WORKFLOW.md** - Understanding our complete workflow
2. **QUICK_START.md** - Your first training and editing session
3. **USER_GUIDE.md** - Detailed documentation for all features

## 🎓 Training Your First Scene

```bash
# 1. Prepare data in COLMAP format
mkdir -p data/my_scene/images
# Copy your images to data/my_scene/images/
# Copy COLMAP sparse/ folder to data/my_scene/sparse/

# 2. Submit training job
sbatch slurm_jobs/train_example.slurm

# 3. Monitor progress
squeue -u $USER
tail -f logs/train_*.log

# Training takes ~2-3 hours on A40 GPU
```

## 🔍 Common Commands

```bash
# Activate environment (run this in every new terminal)
source ~/capoom-gg/scripts_user/setup_env.sh

# Check job status
bash scripts_user/check_status.sh

# Monitor specific job
tail -f logs/JOBNAME_JOBID.log

# Cancel a job
scancel JOBID
```

## 🛠️ Troubleshooting

### CUDA Extensions Build Failed
```bash
# Check you're on a GPU node
nvidia-smi

# If not, request one:
salloc --account=entr490s113y25_class --partition=spgpu --gres=gpu:1 --time=01:00:00

# Then rebuild
cd ~/capoom-gg
bash scripts_user/build_cuda_extensions.sh
```

### Import Errors
```bash
# Verify conda environment
conda activate gaussian_grouping
which python  # Should show path in .conda/envs/gaussian_grouping

# Reinstall dependencies
pip install --upgrade torch torchvision
```

### Out of Memory
- Reduce `--batch_size` in training script
- Request more memory: `#SBATCH --mem=64G`
- Use smaller resolution images

## 📊 Resource Requirements

| Task | GPU | Memory | Time |
|------|-----|--------|------|
| Training | 1x A40 | 32GB | 2-3 hrs |
| Detection | 1x A40 | 16GB | 10 min |
| Extraction | 1x A40 | 16GB | 5 min |
| Rendering | 1x A40 | 16GB | 15 min |
| Inpainting | 1x A40 | 32GB | 1 hour |

## 🤝 Team Collaboration

### Branch Strategy
- `main` - Stable, tested code
- Create feature branches for experiments: `git checkout -b feature/your-feature`

### Sharing Results
- Output files go in `output/YOUR_SCENE/`
- Catalog objects in `catalog/OBJECT_NAME/`
- **Do not commit large files** (data, outputs, models)

### Getting Help
1. Check `docs_user/` documentation
2. Ask in team chat with:
   - Job ID if applicable
   - Error message
   - What you tried
3. Share log files: `logs/JOBNAME_JOBID.log`

## 🔗 Useful Links

- **Original Paper**: https://arxiv.org/abs/2312.00732
- **Project Page**: https://ymq2017.github.io/gaussian-grouping
- **Great Lakes Docs**: https://arc.umich.edu/greatlakes/
- **SLURM Guide**: https://arc.umich.edu/greatlakes/slurm-user-guide/

## 📞 Support

- **Repository**: https://github.com/chabeck1/capoom-gg
- **ARC Support**: hpc-support@umich.edu

---

**Ready?** Start with `docs_user/CAPOOM_WORKFLOW.md` to understand our complete workflow!
