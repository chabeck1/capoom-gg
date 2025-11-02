# Text-Based Object Detection Guide

## Quick Start

Now you can query objects in your 3D scene using natural language!

### Basic Usage

```bash
# Activate environment and run with custom text queries
source activate_env.sh
python render_lerf_mask.py -s data/bear -m output/bear --text "bear;rocks;ground"
```

### SLURM Job (Recommended for GPU)

```bash
# Edit lerf_mask_job.slurm to change the text queries
nano lerf_mask_job.slurm

# Submit job
sbatch lerf_mask_job.slurm
```

## How It Works

1. **GroundingDINO** detects objects matching your text prompts in the first frame
2. **SAM** creates precise segmentation masks for those detections
3. **Gaussian Grouping** matches those masks to the 3D object IDs (1-256)
4. **Output** shows which object ID corresponds to each text query

## Examples

### Explore What's in a Scene
```bash
# Try broad categories first
python render_lerf_mask.py -s data/bear -m output/bear --text "animals;plants;rocks;water;sky"

# Then get more specific
python render_lerf_mask.py -s data/bear -m output/bear --text "bear;tree trunk;moss;boulders;dirt path"
```

### For Indoor Scenes
```bash
python render_lerf_mask.py -s data/room -m output/room --text "chair;table;lamp;window;floor;wall;ceiling"
```

### For Outdoor Scenes
```bash
python render_lerf_mask.py -s data/garden -m output/garden --text "flowers;grass;fence;path;plants;shed"
```

## Tips

1. **Start broad, then narrow**: Try "furniture" before "wooden chair with armrests"
2. **Separate with semicolons**: Use `;` not commas
3. **Check outputs**: Results are in `output/<scene>/train/ours_30000_text/`
4. **Visualizations**: Look for `grounded-sam---<query>.png` files showing detections

## Output Structure

```
output/bear/train/ours_30000_text/
├── grounded-sam---bear.png          # Detection visualization for "bear"
├── grounded-sam---rocks.png         # Detection visualization for "rocks"
├── test_mask/                       # Segmentation masks for each query
│   ├── 00000.png
│   ├── 00001.png
│   └── ...
├── renders/                         # RGB renders
└── objects_feature16/               # Feature visualizations
```

## What This Unlocks

✅ **Know what objects exist** - "Are there any chairs in this scene?"
✅ **Find object IDs** - "Which ID is the bear?" → Check visualization
✅ **Semantic editing** - Combine with removal/inpainting scripts
✅ **Scene understanding** - Get inventory of all objects

## Next Steps

Once you know the object IDs, you can:

1. **Remove specific objects**: Edit `config/object_removal/bear.json` to use the detected ID
2. **Inpaint regions**: Fill holes where objects were removed
3. **Multi-object editing**: Select multiple IDs for batch operations
4. **Scene composition**: Extract objects to reuse in other scenes

## Troubleshooting

**"No detections found"**: Try different text descriptions
**"Low confidence"**: The object might be partially occluded or ambiguous
**"Multiple detections"**: Same object might get multiple IDs (this is expected)

## Example Workflow

```bash
# 1. Train a scene
sbatch train_example.slurm

# 2. Discover what objects exist
python render_lerf_mask.py -s data/bear -m output/bear \
    --text "bear;rocks;trees;ground;water;plants"

# 3. Check visualizations to find bear's object ID
# (Let's say it's ID 34)

# 4. Remove the bear
cat > config/object_removal/bear.json << 'EOF'
{
  "num_classes": 256,
  "removal_thresh": 0.3,
  "select_obj_id": [34]
}
EOF

bash script/edit_object_removal.sh output/bear config/object_removal/bear.json

# 5. Inpaint the hole
bash script/edit_object_inpaint.sh output/bear config/object_inpaint/bear.json
```

Now you can work with objects by name instead of mysterious IDs! 🎉
