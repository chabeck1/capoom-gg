# Edit 3D Scenes by Text Description

## 🎯 Now you can say "remove trees" and they'll disappear!

### Quick Start

```bash
# Remove objects by text description
python edit_by_text.py --scene output/bear --remove "trees"

# Remove multiple objects
python edit_by_text.py --scene output/bear --remove "trees;rocks;grass"

# Remove and inpaint (fills the holes)
python edit_by_text.py --scene output/bear --remove "bear" --inpaint
```

### Using SLURM (Recommended)

```bash
# Just removal (fast, ~10 minutes)
sbatch edit_by_text_job.slurm output/bear "trees"

# With inpainting (slow, ~2 hours)
sbatch edit_by_text_job.slurm output/bear "trees" --inpaint
```

## How It Works

1. **Text Detection** → Finds which object IDs match your description
2. **Removal** → Removes those objects from the 3D scene
3. **Inpainting** (optional) → Fills the holes with plausible content

## Examples

### Remove the main subject
```bash
python edit_by_text.py --scene output/bear --remove "bear" --inpaint
```

### Remove background elements
```bash
python edit_by_text.py --scene output/garden --remove "fence;shed"
```

### Remove multiple similar objects
```bash
python edit_by_text.py --scene output/room --remove "chairs"
```

## Options

- `--scene, -s` - Path to trained scene (e.g., output/bear)
- `--remove` - Text description (use `;` for multiple: "tree;rock;grass")
- `--inpaint` - Fill holes after removal (adds 1-2 hours)
- `--removal_thresh` - Aggressiveness (0.0-1.0, default 0.3)
- `--dry-run` - Only detect objects, don't edit
- `--no-confirm` - Skip confirmation (for batch jobs)

## What You Get

### Without `--inpaint`:
- Object removed with black/empty holes
- Fast (~10 minutes)
- Location: `output/<scene>/train/ours_object_removal/`

### With `--inpaint`:
- Object removed AND holes filled naturally
- Slow (~1-2 hours)
- Location: `output/<scene>/train/ours_object_inpaint/`

## Tips

1. **Try variations** - "tree" vs "trees" vs "pine tree" may give different results
2. **Start with dry-run** - Use `--dry-run` to see what would be removed first
3. **Batch similar objects** - "chair;table;desk" removes all furniture at once
4. **Use inpainting for final results** - Removal alone leaves holes
5. **Check visualizations** - Results include side-by-side comparisons

## Example Workflow

```bash
# Step 1: See what gets detected
python edit_by_text.py --scene output/bear --remove "trees" --dry-run

# Output shows: "Detected object IDs: [12, 45, 78]"

# Step 2: If it looks good, proceed
python edit_by_text.py --scene output/bear --remove "trees"
# Type 'y' to confirm

# Step 3: View results
# Download output/bear/train/ours_object_removal/renders/

# Step 4: If you like it, add inpainting
python edit_by_text.py --scene output/bear --remove "trees" --inpaint
```

## Comparison to Manual Editing

### Before (Manual Way):
```bash
# 1. Find object IDs manually
python render_lerf_mask.py -s data/bear -m output/bear --text "trees"
# 2. Look at visualizations to find IDs
# 3. Edit config file
# 4. Run removal script
bash script/edit_object_removal.sh output/bear config/...
```

### Now (Automated):
```bash
python edit_by_text.py --scene output/bear --remove "trees"
# Done! ✨
```

## Troubleshooting

**"No objects detected"**
- Try different text: "tree" vs "trees" vs "evergreen tree"
- Check if GroundingDINO found anything: look in logs
- The object might not be clearly visible in the first frame

**"Wrong objects detected"**
- Be more specific: "wooden chair" instead of "chair"
- Use `--dry-run` first to preview
- Manually check the LERF mask visualizations

**"Removal incomplete"**
- Lower `--removal_thresh` to be more aggressive
- Some Gaussians might be shared between objects

**"Inpainting takes forever"**
- It's normal - 1-2 hours for full scenes
- Consider using only removal for quick previews
- Check SLURM logs to monitor progress

## Advanced Usage

### Fine-tune removal aggressiveness
```bash
# More aggressive (removes more)
python edit_by_text.py --scene output/bear --remove "trees" --removal_thresh 0.1

# Less aggressive (removes less)
python edit_by_text.py --scene output/bear --remove "trees" --removal_thresh 0.5
```

### Batch process multiple scenes
```bash
for scene in output/*; do
    python edit_by_text.py --scene "$scene" --remove "people" --no-confirm
done
```

### Create before/after comparisons
```bash
# Original renders
cp -r output/bear/train/ours_30000/renders renders_original

# Remove objects
python edit_by_text.py --scene output/bear --remove "bear"

# Compare
# renders_original/ vs output/bear/train/ours_object_removal/renders/
```

---

**You asked: "so now i can just say i want to remove trees and all will disappear?"**

**Answer: YES! 🎉**

```bash
python edit_by_text.py --scene output/bear --remove "trees"
```

That's literally all you need!
