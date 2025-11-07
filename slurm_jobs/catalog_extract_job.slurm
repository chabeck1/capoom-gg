#!/bin/bash
#SBATCH --job-name=catalog_extract
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64GB
#SBATCH --gres=gpu:1
#SBATCH --time=00:30:00
#SBATCH --output=logs/catalog_extract_%j.out
#SBATCH --error=logs/catalog_extract_%j.err

# Capoom Catalog Extraction Job
# Usage: sbatch slurm_jobs/catalog_extract_job.slurm <scene_path> "<object_names>"
# Example: sbatch slurm_jobs/catalog_extract_job.slurm output/bear "bear"

SCENE_PATH=$1
OBJECT_NAMES=$2

if [ -z "$SCENE_PATH" ] || [ -z "$OBJECT_NAMES" ]; then
    echo "Usage: sbatch catalog_extract_job.slurm <scene_path> \"<object_names>\""
    echo "Example: sbatch catalog_extract_job.slurm output/bear \"bear\""
    exit 1
fi

echo "=================================================="
echo "Capoom Catalog Extraction Job"
echo "=================================================="
echo "Scene: $SCENE_PATH"
echo "Objects: $OBJECT_NAMES"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "Start time: $(date)"
echo "=================================================="

# Activate environment
source activate_env.sh

# Create logs directory
mkdir -p logs

# Step 1: Detect objects if not already done
echo ""
echo "Step 1: Detecting objects..."
echo "Running: python render_lerf_mask.py -m $SCENE_PATH --iteration 30000 --skip_test --text \"$OBJECT_NAMES\""
python render_lerf_mask.py \
    -m "$SCENE_PATH" \
    --iteration 30000 \
    --skip_test \
    --text "$OBJECT_NAMES"

if [ $? -ne 0 ]; then
    echo "ERROR: Detection failed!"
    exit 1
fi

echo "✓ Detection complete"

# Step 2: Extract to catalog
echo ""
echo "Step 2: Extracting to catalog..."
echo "Running: python capoom_street_furniture.py --scene $SCENE_PATH --mode extract --objects \"$OBJECT_NAMES\""
python capoom_street_furniture.py \
    --scene "$SCENE_PATH" \
    --mode extract \
    --objects "$OBJECT_NAMES"

if [ $? -ne 0 ]; then
    echo "ERROR: Extraction failed!"
    exit 1
fi

echo "✓ Extraction complete"

# Step 3: List catalog contents
echo ""
echo "=================================================="
echo "Catalog Contents:"
echo "=================================================="
ls -lh catalog/

echo ""
echo "Extraction Details:"
for obj in $(echo "$OBJECT_NAMES" | tr ';' '\n'); do
    obj_name=$(echo "$obj" | tr ' ' '_')
    if [ -d "catalog/$obj_name" ]; then
        echo ""
        echo "Object: $obj"
        echo "  Location: catalog/$obj_name/"
        if [ -f "catalog/$obj_name/metadata.json" ]; then
            echo "  Metadata:"
            cat "catalog/$obj_name/metadata.json" | head -20
        fi
    fi
done

echo ""
echo "=================================================="
echo "Job Complete!"
echo "End time: $(date)"
echo "=================================================="
