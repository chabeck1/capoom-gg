# Quick Start Guide - Next Steps

Your Gaussian Grouping model is trained! Here's how to use it:

## 📁 Your Files

All job files are ready to use:
- `removal_job.slurm` - Remove objects from the scene
- `inpaint_job.slurm` - Inpaint removed regions
- `render_job.slurm` - Render with text prompts
- `NEXT_STEPS_GUIDE.md` - Detailed documentation

## 🚀 Quick Commands

### 1. Object Removal (Remove object #34 from scene)
```bash
sbatch removal_job.slurm
```
Monitor: `tail -f logs/removal_*.log`

### 2. Object Inpainting (Fill in the removed region)
```bash
sbatch inpaint_job.slurm
```
Monitor: `tail -f logs/inpaint_*.log`

### 3. Text-based Segmentation Rendering
```bash
sbatch render_job.slurm
```
Monitor: `tail -f logs/render_*.log`

## 🎨 Changing Which Object to Remove

Edit the config file:
```bash
nano config/object_removal/bear.json
```

Change `"select_obj_id" : [34]` to different numbers to remove different objects!

## 📊 View Your Results

Results are saved as PNG images. To view them:

**Option 1:** Copy to your local machine
```bash
scp -r username@greatlakes.arc-ts.umich.edu:~/gaussian-grouping/output/bear/train/ .
```

**Option 2:** Use Great Lakes OnDemand web interface (if available)

## 📂 Output Locations

- Training renders: `output/bear/train/ours_30000/`
- Object removal: `output/bear/train/ours_object_removal/`
- Inpainting: `output/bear/train/ours_object_inpaint/`

## 💡 Tips

1. Check job status: `squeue -u $USER`
2. Cancel a job: `scancel JOB_ID`
3. View results: Images are in the `renders/` subdirectory of each output folder
4. Experiment: Try different object IDs in the config files!

## 📖 More Information

See `NEXT_STEPS_GUIDE.md` for detailed instructions and explanations.
