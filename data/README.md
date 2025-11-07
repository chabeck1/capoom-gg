# Data Directory

This directory contains training data for Gaussian Grouping scenes.

## 📋 Data Not Included in Git

Due to file size, **data files are NOT tracked in git**. Team members need to obtain datasets separately.

## 🗂️ Current Datasets

### Mcity Street Scene
- **Source**: CAPOOM project data (copyrighted)
- **Format**: COLMAP (images + sparse reconstruction)
- **Size**: ~1.1 GB
- **Location**: `data/mcity/`

**To get the data:**
1. Access google drive shared from Capoom
2. Upload to Great Lakes:
   ```bash
   scp perspective-20251102T190855Z-1-002.zip YOUR_USERNAME@greatlakes.arc-ts.umich.edu:~/capoom-gg/data/
   ```
3. Extract:
   ```bash
   cd ~/capoom-gg/data
   unzip perspective-20251102T190855Z-1-002.zip
   mv perspective-20251102T190855Z-1-002 mcity
   ```

### Bear Scene (Example)
- **Source**: Gaussian Grouping paper
- **Format**: COLMAP + ground truth masks
- **Size**: ~200 MB
- **Location**: `data/bear/`
- Available from: https://huggingface.co/datasets/dylanebert/gaussian-grouping

## 📁 Expected Data Structure

Each scene should follow this structure:

```
data/
├── mcity/
│   ├── images/              # RGB images
│   │   ├── 000001.jpg
│   │   ├── 000002.jpg
│   │   └── ...
│   └── sparse/
│       └── 0/               # COLMAP reconstruction
│           ├── cameras.bin
│           ├── images.bin
│           └── points3D.bin
│
└── bear/                    # (Optional example scene)
    ├── images/
    ├── sparse/
    └── object_mask/         # Ground truth (if available)
```

## ⚙️ Creating Your Own Data

If collecting new scenes:

1. **Capture images**: Take photos/video of the scene from multiple angles
2. **Run COLMAP**: Process images to get camera poses and sparse 3D points
   ```bash
   colmap automatic_reconstructor \
       --image_path data/my_scene/images \
       --workspace_path data/my_scene/sparse
   ```
3. **Verify output**: Check that `sparse/0/` contains the .bin files
4. **Train**: Use the scene with Gaussian Grouping

## 🔒 Data Privacy

**Important**: 
- Mcity data is copyrighted by CAPOOM/University of Michigan
- Do NOT share publicly or upload to GitHub
- Only use for this class project
- Delete after project completion

## 📊 Data Storage

Current usage:
```bash
# Check data directory size
du -sh ~/capoom-gg/data/*

# Great Lakes storage quota
quota -s
```

**Recommended**: Keep only active scenes to save space. Archive old data.
