## 🚀 Capoom Catalog Testing - Quick Reference

### **Current Status**

✅ **Test Job Running**: Job 34815388 on gl1503  
📝 **Log File**: `logs/test_catalog_34815388.out`  
⏱️ **ETA**: ~10-15 minutes total

---

## **Monitor Progress**

```bash
# Quick status check
squeue -j 34815388

# Watch live log
tail -f logs/test_catalog_34815388.out

# Full monitoring
./scripts_user/monitor_catalog_test.sh 34815388
```

---

## **After Test Completes**

### **1. Check Results**
```bash
# View test summary (last 50 lines)
tail -50 logs/test_catalog_34815388.out

# Should show:
# ✓ TEST 1 PASSED: Detection successful
# ✓ TEST 2 PASSED: Extraction successful
# ✓ TEST 3 PASSED: Removal successful
```

### **2. Validate Catalog**
```bash
./scripts_user/validate_catalog.sh bear

# This checks:
# - Gaussians file exists and loads
# - Metadata is complete
# - Gaussian count is reasonable
# - Files match expected structure
```

### **3. Inspect Catalog Contents**
```bash
# Check files
ls -lh catalog/bear/

# Read metadata
cat catalog/bear/metadata.json

# Load in Python
python3 -c "
import torch
data = torch.load('catalog/bear/gaussians.pt')
print('Keys:', data.keys())
print('Num Gaussians:', data['xyz'].shape[0])
"
```

### **4. View Detection Results**
```bash
# Check detected object IDs
cat output/bear/train/ours_30000_text/object_ids---bear.json

# View visualization
# Download: output/bear/train/ours_30000_text/grounded-sam---bear.png
```

### **5. View Removal Results**
```bash
# Count rendered images
ls output/bear/train/ours_object_removal/iteration_30000/renders/*.png | wc -l
# Should be: 96 images

# View in browser (if on local machine)
# Or download for inspection
```

---

## **Next Tests (If Successful)**

### **Test Addition to Scene**
```bash
# Add bear at new position
sbatch slurm_jobs/catalog_add_job.slurm \
  output/bear \
  bear \
  5.0,0.0,1.5 \
  0,45,0 \
  1.2

# Monitor
tail -f logs/catalog_add_*.out
```

### **Test Multiple Objects**
```bash
# If you have another scene trained, test detection of multiple objects
sbatch slurm_jobs/catalog_extract_job.slurm \
  output/teatime \
  "bear;cookies;mug;spoon"
```

### **Test on Street Scene** (Production Use)
```bash
# Once you have street scene data
sbatch slurm_jobs/train_job.slurm \
  -s data/street_scene \
  -m output/street_scene

# Then extract street furniture
sbatch slurm_jobs/catalog_extract_job.slurm \
  output/street_scene \
  "stop sign;traffic light;fire hydrant"
```

---

## **Troubleshooting**

### **If Detection Fails**
```bash
# Check if model exists
ls output/bear/point_cloud/iteration_30000/

# Check GroundingDINO installation
python -c "import groundingdino; print('OK')"
```

### **If Extraction Fails**
```bash
# Check error log
cat logs/test_catalog_34815388.err

# Common issue: Missing detection file
ls output/bear/train/ours_30000_text/object_ids---bear.json
```

### **If Job Hangs**
```bash
# Cancel job
scancel 34815388

# Check what went wrong
tail -100 logs/test_catalog_34815388.out

# Re-run with more verbose output
```

---

## **Expected File Structure After Test**

```
catalog/
└── bear/
    ├── gaussians.pt          # ~10-50 MB
    └── metadata.json         # ~1 KB

output/bear/
├── train/
│   ├── ours_30000_text/
│   │   ├── object_ids---bear.json
│   │   ├── grounded-sam---bear.png
│   │   └── renders/
│   └── ours_object_removal/
│       └── iteration_30000/
│           └── renders/      # 96 PNG files
└── point_cloud/
    └── iteration_30000/
        └── point_cloud.ply

logs/
├── test_catalog_34815388.out
└── test_catalog_34815388.err
```

---

## **Success Metrics**

- ✅ Detection JSON contains `"object_ids": [34]`
- ✅ Catalog has >10,000 Gaussians
- ✅ Metadata includes bbox, centroid, size
- ✅ 96 removal renders generated
- ✅ No errors in `.err` file

---

## **Commands Summary**

```bash
# Check job
squeue -j 34815388

# Monitor
./scripts_user/monitor_catalog_test.sh 34815388

# Validate after completion
./scripts_user/validate_catalog.sh bear

# View results
tail -50 logs/test_catalog_34815388.out
cat output/bear/train/ours_30000_text/object_ids---bear.json
cat catalog/bear/metadata.json

# Next test
sbatch slurm_jobs/catalog_add_job.slurm output/bear bear 5.0,0.0,1.5
```
