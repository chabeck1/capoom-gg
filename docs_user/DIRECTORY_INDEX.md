# Gaussian Grouping - Directory Index

## 📁 Directory Structure

### `/slurm_jobs/`
SLURM batch job scripts for Great Lakes HPC.

**Training & Setup:**
- `train_example.slurm` - Train a scene
- `build_extensions.slurm` - Build CUDA extensions
- `build_grounding_dino.slurm` - Build GroundingDINO

**Editing:**
- `edit_by_text_job.slurm` - 🌟 Main text-based editing workflow
- `removal_job.slurm` - Remove objects by ID
- `inpaint_job.slurm` - Inpaint removed regions

**Visualization:**
- `lerf_mask_job.slurm` - Generate text-based masks
- `render_job.slurm` - Render scene views
- `viewer_job.slurm` - Launch 3D viewer

### `/docs_user/`
User-created documentation and guides.

- `TEXT_EDITING_SUCCESS.txt` - ✅ Success summary
- `EDIT_BY_TEXT.md` - Text editing guide
- `TEXT_QUERY_GUIDE.md` - Writing text queries
- `PROJECT_ROADMAP.md` - Goals and capabilities
- `QUICK_REFERENCE.txt` - Quick commands
- `QUICK_START.md` - Getting started
- `SETUP_README.md` - Setup notes

### `/scripts_user/`
Helper shell scripts.

- `install_grounding_dino.sh` - Install GroundingDINO
- `view_3d.sh` - Launch 3D viewer

### `/script/` (Original)
Original training and evaluation scripts from the paper.

### `/config/`
Configuration files for editing operations.

### `/output/`
Trained models and editing results.

### `/data/`
Training datasets (COLMAP format).

### `/logs/`
SLURM job output logs.

---

## 🎯 Quick Navigation

**Want to...?**
- Train a scene → `slurm_jobs/train_example.slurm`
- Remove objects by text → `slurm_jobs/edit_by_text_job.slurm`
- Read full guide → `USER_GUIDE.md`
- Understand the project → `docs_user/PROJECT_ROADMAP.md`
- See what works → `docs_user/TEXT_EDITING_SUCCESS.txt`

**Example Command:**
```bash
sbatch slurm_jobs/edit_by_text_job.slurm output/bear "bear"
```
