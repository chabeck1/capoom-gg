# How to Use Your Trained Gaussian Grouping Model

Your model has been successfully trained on the bear dataset! Here's how to use it for different tasks.

## Current Status
- ✅ Trained model location: `output/bear/`
- ✅ Final iteration: 30,000
- ✅ Rendered outputs: `output/bear/train/ours_30000/`

## Available Tasks

### 1. View Novel Renderings (Already Done!)

Your training already generated novel view renderings:
```bash
# View rendered images
ls output/bear/train/ours_30000/renders/

# View segmented objects
ls output/bear/train/ours_30000/objects_pred/

# View ground truth comparisons
ls output/bear/train/ours_30000/gt/
```

### 2. 3D Object Removal

Remove specific objects from the 3D scene.

**Step 1:** Edit the config to choose which object(s) to remove.

```bash
# Edit this file to change which object ID to remove
nano config/object_removal/bear.json
```

The config looks like:
```json
{
    "num_classes": 256,
    "removal_thresh": 0.3,
    "select_obj_id" : [34]  // Change this number to remove different objects
}
```

**Step 2:** Run the removal script:
```bash
bash script/edit_object_removal.sh output/bear config/object_removal/bear.json
```

**Output:** Results will be in `output/bear/train/ours_object_removal/`

---

### 3. 3D Object Inpainting

Inpaint (fill in) the region where an object was removed.

**Note:** The bear dataset already has pre-computed inpainting masks!

```bash
# Run inpainting (uses pre-computed masks from the dataset)
bash script/edit_object_inpaint.sh output/bear config/object_inpaint/bear.json
```

**Output:** Results will be in `output/bear/train/ours_object_inpaint/`

---

### 4. Text-Prompt Based Segmentation

Render segmentation masks based on text prompts (like LERF).

```bash
# Render masks for specific text queries
python render_lerf_mask.py -m output/bear --skip_train
```

This will use Grounded-SAM to match your trained 3D segments to text descriptions.

---

### 5. Custom Novel View Rendering

Render new viewpoints of your scene.

```bash
# Render from trained model
python render.py -m output/bear --num_classes 256
```

---

## SLURM Job Examples

If you want to run these on the cluster with SLURM, here are job templates:

### Object Removal Job

Create `removal_job.slurm`:
```bash
#!/bin/bash
#SBATCH --job-name=gg_removal
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --nodes=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --output=logs/removal_%j.log

module load python3.10-anaconda cuda/11.3.0
source ~/.bashrc
conda activate gaussian_grouping

cd ~/gaussian-grouping
bash script/edit_object_removal.sh output/bear config/object_removal/bear.json
```

Submit with: `sbatch removal_job.slurm`

### Inpainting Job

Create `inpaint_job.slurm`:
```bash
#!/bin/bash
#SBATCH --job-name=gg_inpaint
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --nodes=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=03:00:00
#SBATCH --output=logs/inpaint_%j.log

module load python3.10-anaconda cuda/11.3.0
source ~/.bashrc
conda activate gaussian_grouping

cd ~/gaussian-grouping
bash script/edit_object_inpaint.sh output/bear config/object_inpaint/bear.json
```

Submit with: `sbatch inpaint_job.slurm`

---

## Quick Interactive Test (On Login Node - Small Test Only)

If you want to quickly test viewing results without a job:

```bash
# Activate environment
conda activate gaussian_grouping

# Check what objects were segmented
ls output/bear/train/ours_30000/objects_pred/

# View a specific rendered image (you'll need to copy to local machine to view)
# Or use a visualization tool on the cluster
```

---

## Tips

1. **Finding Object IDs:** Look at the segmented objects in `output/bear/train/ours_30000/objects_pred/` to see what was segmented. Each unique object has an ID.

2. **Visualization:** To view the PNG images, you'll need to either:
   - Copy them to your local machine: `scp username@greatlakes.arc-ts.umich.edu:~/gaussian-grouping/output/bear/train/ours_30000/renders/*.png .`
   - Use OnDemand web portal if available
   - Use X11 forwarding with an image viewer

3. **Experiment:** Try different `select_obj_id` values in the config files to remove/inpaint different objects!

---

## File Structure

```
output/bear/
├── cameras.json                    # Camera parameters
├── cfg_args                        # Training configuration
├── input.ply                       # Initial point cloud
├── point_cloud/                    # Saved checkpoints
│   ├── iteration_1000/
│   ├── iteration_7000/
│   └── iteration_30000/            # Final trained model
└── train/
    └── ours_30000/
        ├── renders/                # Novel view renderings
        ├── objects_pred/           # Segmented objects
        ├── gt/                     # Ground truth images
        └── concat/                 # Side-by-side comparisons
```
