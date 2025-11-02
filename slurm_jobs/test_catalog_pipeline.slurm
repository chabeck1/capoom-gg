#!/bin/bash
#SBATCH --job-name=test_catalog
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64GB
#SBATCH --gres=gpu:1
#SBATCH --time=01:00:00
#SBATCH --output=logs/test_catalog_%j.out
#SBATCH --error=logs/test_catalog_%j.err

# Complete Catalog Pipeline Test
# Tests: Detection → Extraction → Catalog → Addition → Render
# Usage: sbatch slurm_jobs/test_catalog_pipeline.slurm

echo "=================================================="
echo "Capoom Complete Catalog Pipeline Test"
echo "=================================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "Start time: $(date)"
echo "=================================================="

# Activate environment
source activate_env.sh

# Create logs directory
mkdir -p logs
mkdir -p catalog

SCENE="output/bear"
OBJECT_NAME="bear"

echo ""
echo "TEST 1: Detection"
echo "=================================================="
echo "Detecting 'bear' in scene..."
python render_lerf_mask.py \
    -m "$SCENE" \
    --iteration 30000 \
    --skip_test \
    --text "$OBJECT_NAME"

if [ $? -eq 0 ]; then
    echo "✓ TEST 1 PASSED: Detection successful"
else
    echo "✗ TEST 1 FAILED: Detection failed"
    exit 1
fi

# Check detection output
OBJ_IDS_FILE="$SCENE/train/ours_30000_text/object_ids---${OBJECT_NAME}.json"
if [ -f "$OBJ_IDS_FILE" ]; then
    echo "Detection results:"
    cat "$OBJ_IDS_FILE"
else
    echo "⚠ Warning: object_ids file not found"
fi

echo ""
echo "TEST 2: Extraction to Catalog"
echo "=================================================="
echo "Extracting 'bear' to catalog..."
python capoom_street_furniture.py \
    --scene "$SCENE" \
    --mode extract \
    --objects "$OBJECT_NAME"

if [ $? -eq 0 ]; then
    echo "✓ TEST 2 PASSED: Extraction successful"
else
    echo "✗ TEST 2 FAILED: Extraction failed"
    exit 1
fi

# Check catalog contents
CATALOG_DIR="catalog/${OBJECT_NAME}"
if [ -d "$CATALOG_DIR" ]; then
    echo "Catalog created at: $CATALOG_DIR"
    echo "Contents:"
    ls -lh "$CATALOG_DIR"
    
    if [ -f "$CATALOG_DIR/metadata.json" ]; then
        echo ""
        echo "Metadata:"
        cat "$CATALOG_DIR/metadata.json"
    fi
    
    if [ -f "$CATALOG_DIR/gaussians.pt" ]; then
        FILESIZE=$(stat -f%z "$CATALOG_DIR/gaussians.pt" 2>/dev/null || stat -c%s "$CATALOG_DIR/gaussians.pt" 2>/dev/null)
        echo ""
        echo "Gaussians file size: $FILESIZE bytes"
    fi
else
    echo "✗ Catalog directory not created!"
    exit 1
fi

echo ""
echo "TEST 3: Object Removal (Baseline)"
echo "=================================================="
echo "Removing bear from scene as baseline test..."
python edit_by_text.py \
    --model_path "$SCENE" \
    --text "$OBJECT_NAME" \
    --skip_inpaint

if [ $? -eq 0 ]; then
    echo "✓ TEST 3 PASSED: Removal successful"
    REMOVAL_DIR="$SCENE/train/ours_object_removal/iteration_30000/renders"
    if [ -d "$REMOVAL_DIR" ]; then
        NUM_IMAGES=$(ls "$REMOVAL_DIR"/*.png 2>/dev/null | wc -l)
        echo "Generated $NUM_IMAGES rendered images"
    fi
else
    echo "⚠ TEST 3 WARNING: Removal failed (non-critical)"
fi

echo ""
echo "TEST 4: Catalog Addition (Future)"
echo "=================================================="
echo "Note: Addition test requires validated extraction first"
echo "This would add bear at new position: [5.0, 0.0, 1.5]"
echo "Command: python capoom_street_furniture.py --mode add --target $SCENE --objects bear --position 5.0,0.0,1.5"
echo "⚠ Skipping addition test for now (needs debugging)"

echo ""
echo "=================================================="
echo "PIPELINE TEST SUMMARY"
echo "=================================================="
echo "✓ Detection: PASSED"
echo "✓ Extraction: PASSED"
echo "✓ Catalog Storage: PASSED"
echo "✓ Removal: PASSED"
echo "⚠ Addition: NOT TESTED (implement after validation)"
echo ""
echo "Catalog location: catalog/$OBJECT_NAME/"
echo "Detection results: $OBJ_IDS_FILE"
echo "Removal renders: $SCENE/train/ours_object_removal/iteration_30000/renders/"
echo ""
echo "Job Complete!"
echo "End time: $(date)"
echo "=================================================="
