# Capoom AV Testing Digital Twin Workflow

**Goal**: Build digital twins of street scenes with ability to add/remove street furniture for autonomous vehicle testing scenarios.

---

## 🎯 Project Objectives

### 1. **Improve Street Furniture Detection Accuracy**
- Detect: stop signs, traffic lights, fire hydrants, benches, bollards, crosswalks, etc.
- Use text-based queries instead of manual ID selection
- Achieve >90% detection accuracy on common street furniture

### 2. **Scene Manipulation for AV Testing**
- **Remove objects**: Test "what if this wasn't here" scenarios
- **Add objects from catalog**: Insert stop signs, pedestrians at specific locations
- **Build asset library**: Reusable 3D models of street furniture

---

## 📋 Complete Workflow

### **Phase 1: Train Scene (One-time per location)**

```bash
# 1. Prepare street scene data (COLMAP format)
# You need: images/ + sparse/ (COLMAP reconstruction)

# 2. Train Gaussian Grouping
sbatch slurm_jobs/train_job.slurm \
  -s data/street_scenes/downtown_block_01 \
  -m output/downtown_block_01

# Training takes ~2 hours on A40
# Output: Trained 3D scene with object segmentation
```

### **Phase 2: Detect All Street Furniture**

```bash
# Detect all street furniture automatically
python render_lerf_mask.py \
  -m output/downtown_block_01 \
  --iteration 30000 \
  --skip_test \
  --text "stop sign;traffic light;fire hydrant;street light;bench;trash can;crosswalk;curb;parking meter;bollard"

# This creates for EACH object:
# - object_ids---stop_sign.json  (detected IDs)
# - grounded-sam---stop_sign.png (visualization)

# Generate detection report
python capoom_street_furniture.py \
  --scene output/downtown_block_01 \
  --mode detect \
  --output reports/downtown_block_01_furniture.json
```

**Output**: JSON report of all detected street furniture with object IDs

### **Phase 3: Build Catalog (Extract Assets)**

```bash
# Extract individual objects to reusable catalog
# Use SLURM for extraction (recommended):
sbatch slurm_jobs/catalog_extract_job.slurm \
  output/downtown_block_01 \
  "stop sign"

# This creates:
# catalog/
#   stop_sign/
#     gaussians.pt      ← 3D Gaussian parameters (all attributes)
#     metadata.json     ← Size, position, # of Gaussians
#
# Extraction uses 0.5 probability threshold (captures high-confidence Gaussians)

# To extract multiple objects, run detection first:
python render_lerf_mask.py -m output/downtown_block_01 \
  --text "stop sign;fire hydrant;traffic light"
# Then extract each individually with catalog_extract_job.slurm
```

**Catalog Metadata Example**:
```json
{
  "name": "bear",
  "object_ids": [34],
  "source_scene": "output/bear",
  "num_gaussians": 328583,
  "bbox_min": [-74.01, -33.65, -45.05],
  "bbox_max": [35.94, 32.73, 34.12],
  "centroid": [0.45, 0.88, 1.43],
  "size": [109.95, 66.38, 79.16]
}
```

**Key Parameters:**
- **Extraction Threshold**: 0.5 (50% probability) - captures high-confidence Gaussians
- **Scale Factor**: Use 1.0 to preserve density (values >1.0 spread Gaussians and cause transparency)
- **Position**: World coordinates in meters (x, y, z)
- **Rotation**: Euler angles in degrees (rx, ry, rz)

### **Phase 4: Scene Manipulation**

#### **4A. Remove Object from Scene**

```bash
# Remove stop sign from scene (testing: "what if no stop sign?")
sbatch slurm_jobs/removal_job.slurm \
  output/downtown_block_01 \
  "stop sign"

# Output: 
# output/downtown_block_01/train/ours_object_removal/iteration_30000/renders/
#   → 96 images with stop sign removed
```

#### **4B. Add Object to Scene**

```bash
# Add stop sign at new location (testing: "what if stop sign was here?")
# IMPORTANT: Use --scene (not --target) and scale 1.0 (scaling spreads Gaussians)
python capoom_street_furniture.py \
  --mode add \
  --scene output/downtown_block_01 \
  --objects "stop_sign" \
  --position "5.2,0.0,1.5" \
  --rotation "0,45,0" \
  --scale 1.0

# This modifies the scene by inserting catalog object
# Output: output/downtown_block_01/point_cloud/iteration_30000_modified/

# OR use SLURM for automated processing:
sbatch slurm_jobs/catalog_add_job.slurm \
  output/downtown_block_01 \
  stop_sign \
  5.2,0.0,1.5 \
  0,45,0 \
  1.0
```

#### **4C. Render Modified Scene**

```bash
# Render the modified scene to verify
python render.py \
  -m output/downtown_block_01 \
  --iteration 30000_modified \
  --skip_test

# Output: Rendered images with added/removed objects
```

---

## 🔧 Practical Examples for AV Testing

### **Example 1: Test Stop Sign Detection**

```bash
# Scenario: Does AV detect stop sign at intersection?

# 1. Baseline: Render original scene
python render.py -m output/intersection_01

# 2. Remove stop sign
sbatch slurm_jobs/removal_job.slurm output/intersection_01 "stop sign"

# 3. Compare AV behavior:
#    - With stop sign: AV should stop
#    - Without stop sign: AV should proceed (but shouldn't!)
```

### **Example 2: Add Object to Scene**

```bash
# Scenario: Add parked truck that blocks stop sign view

# 1. Extract truck from catalog (detection must be done first)
sbatch slurm_jobs/catalog_extract_job.slurm \
  output/parking_lot \
  "truck"

# 2. Add truck blocking view (use scale 1.0 to maintain density!)
sbatch slurm_jobs/catalog_add_job.slurm \
  output/intersection_01 \
  truck \
  3.0,0.0,0.5 \
  0,90,0 \
  1.0

# 3. Test: Can AV still detect occluded stop sign?
```

### **Example 3: Pedestrian Crossing**

```bash
# Scenario: Add pedestrian at crosswalk

# 1. Extract pedestrian from catalog scene (run detection first!)
sbatch slurm_jobs/catalog_extract_job.slurm \
  output/street_with_people \
  "pedestrian"

# 2. Place at crosswalk
sbatch slurm_jobs/catalog_add_job.slurm \
  output/intersection_01 \
  pedestrian \
  2.5,0.0,0.0 \
  0,45,0 \
  1.0

# 3. Test: Does AV yield to pedestrian?
```

### **Example 4: Construction Zone**

```bash
# Scenario: Simulate construction with cones and barriers

# Extract from catalog (one at a time, run detection first)
sbatch slurm_jobs/catalog_extract_job.slurm \
  output/construction_site \
  "traffic cone"

sbatch slurm_jobs/catalog_extract_job.slurm \
  output/construction_site \
  "barrier"

# Add multiple cones in a line (scale 1.0 to maintain appearance)
sbatch slurm_jobs/catalog_add_job.slurm \
  output/street_scene traffic_cone 1.0,0.0,0.2 0,0,0 1.0

sbatch slurm_jobs/catalog_add_job.slurm \
  output/street_scene traffic_cone 2.0,0.0,0.2 0,0,0 1.0

sbatch slurm_jobs/catalog_add_job.slurm \
  output/street_scene traffic_cone 3.0,0.0,0.2 0,0,0 1.0
```

---

## 📊 Detection Accuracy Improvements

### **Street Furniture Categories**

| Category | Objects | Current Status |
|----------|---------|----------------|
| **Traffic Control** | stop sign, yield sign, traffic light | ✅ Working |
| **Infrastructure** | fire hydrant, street light, utility pole | ✅ Working |
| **Pedestrian** | bench, trash can, bike rack, crosswalk | 🟡 Needs testing |
| **Vehicles** | car, truck, bus, bicycle, pedestrian | 🟡 Needs testing |

### **Improving Accuracy**

```bash
# 1. Fine-tune GroundingDINO on street furniture
#    - Collect more training data
#    - Adjust detection thresholds

# 2. Test different text queries
python render_lerf_mask.py -m output/scene \
  --text "octagonal red stop sign"  # More specific
  
python render_lerf_mask.py -m output/scene \
  --text "stop sign.traffic sign"  # Alternatives

# 3. Adjust IoA threshold for better matching
# Edit render_lerf_mask.py line 50:
# selected_obj_ids = select_obj_ioa(pred_obj, text_mask, ioa_thresh=0.6)
# Lower threshold = more permissive matching
```

---

## 🎯 Deliverables for Capoom

### **1. Detection System**
- ✅ Text-based detection working
- ✅ GroundingDINO + SAM + IoA matching
- 📝 TODO: Benchmark accuracy on street furniture
- 📝 TODO: Fine-tune detection thresholds

### **2. Scene Manipulation**
- ✅ Object removal working (text-based via GroundingDINO+SAM)
- ✅ Extraction to catalog fully implemented (threshold 0.5)
- ✅ Addition from catalog working (CRITICAL: use scale 1.0 to avoid transparency)
- 📝 TODO: Test on real street scenes
- 📝 TODO: Handle lighting/shadows

### **3. Asset Catalog**
- ✅ Infrastructure for catalog storage
- ✅ Metadata tracking (size, position, # Gaussians)
- 📝 TODO: Build library of common street furniture
- 📝 TODO: Standardize coordinate systems

### **4. AV Testing Integration**
- 📝 TODO: Export to simulator format (CARLA, SUMO?)
- 📝 TODO: Automated test scenario generation
- 📝 TODO: Batch processing for multiple scenes

---

## ⚠️ Current Limitations & Solutions

| Limitation | Impact | Solution |
|------------|--------|----------|
| **Scaling spreads Gaussians** | Added objects look transparent | **Always use scale=1.0** (scale>1.0 = 1.73× volume for 1.2×) |
| **Extraction threshold** | Too high = sparse, too low = noise | 0.5 works well (50% confidence) |
| **Lighting mismatch** | Added objects look different | Fine-tune after insertion |
| **Scale ambiguity** | Objects may be wrong size | Use COLMAP camera params for scale |
| **No shadows** | Added objects float | Post-processing or shadow synthesis |
| **Static scenes only** | Can't test dynamic scenarios | Future: 4D Gaussian Splatting |
| **Memory usage** | Large scenes OOM | Use 64GB RAM node for processing |
| **Rendering modified scenes** | render.py expects integer iteration | Modified scenes exist as .ply but can't render via standard pipeline |

---

## 🚀 Next Steps

### **Immediate (This Week)**
1. ✅ Test detection on bear scene (completed - 90% confidence)
2. ✅ Build initial catalog extraction system (completed - 328K Gaussians)
3. ✅ Validate removal + addition pipeline end-to-end (completed - scale 1.0 works)
4. Test on actual street scene data with real furniture

### **Short-term (2-4 Weeks)**
1. Improve detection accuracy (benchmark + tune)
2. Implement fine-tuning for added objects
3. Create batch processing scripts

### **Long-term (1-2 Months)**
1. Build comprehensive street furniture catalog (50+ objects)
2. Integration with AV simulator
3. Automated test scenario generation
4. Multi-scene composition

---

## 📞 Quick Reference Commands

```bash
# Train scene
sbatch slurm_jobs/train_job.slurm -s data/scene -m output/scene

# Detect furniture (run this before extraction!)
python render_lerf_mask.py -m output/scene --text "stop sign;traffic light"

# Remove object
sbatch slurm_jobs/removal_job.slurm output/scene "stop sign"

# Extract to catalog (creates catalog/<object_name>/)
sbatch slurm_jobs/catalog_extract_job.slurm output/scene "stop sign"

# Add from catalog (scale 1.0 is critical!)
sbatch slurm_jobs/catalog_add_job.slurm output/scene stop_sign 5,0,1.5 0,45,0 1.0

# View results in 3D viewer
# Download output/scene/point_cloud/iteration_30000_modified/point_cloud.ply
# Open in SuperSplat, CloudCompare, or other .ply viewer
```

---

## 📝 Notes

- All positions are in world coordinates (meters)
- Rotation in degrees (Euler angles: rx, ry, rz)
- **Scale MUST be 1.0** for proper appearance (values >1.0 cause transparency by spreading Gaussians)
  - Scale 1.2 = 1.73× volume (1.2³) = Gaussians spread too thin
- Catalog names use underscores (e.g., `stop_sign` not `stop sign`)
- Always run detection (`render_lerf_mask.py`) before extraction to get object IDs
- Extraction threshold 0.5 (50% confidence) balances completeness vs noise
- Modified scenes saved as `iteration_30000_modified` (can view .ply directly, rendering not yet supported)
