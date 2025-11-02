#!/bin/bash
#SBATCH --job-name=catalog_add
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64GB
#SBATCH --gres=gpu:1
#SBATCH --time=00:30:00
#SBATCH --output=logs/catalog_add_%j.out
#SBATCH --error=logs/catalog_add_%j.err

# Capoom Catalog Addition Job
# Usage: sbatch slurm_jobs/catalog_add_job.slurm <target_scene> <catalog_object> <x,y,z> [rx,ry,rz] [scale]
# Example: sbatch slurm_jobs/catalog_add_job.slurm output/bear bear_catalog 5.0,0.0,1.5 0,45,0 1.2

TARGET_SCENE=$1
CATALOG_OBJ=$2
POSITION=$3
ROTATION=${4:-"0,0,0"}
SCALE=${5:-1.0}

if [ -z "$TARGET_SCENE" ] || [ -z "$CATALOG_OBJ" ] || [ -z "$POSITION" ]; then
    echo "Usage: sbatch catalog_add_job.slurm <target_scene> <catalog_object> <x,y,z> [rx,ry,rz] [scale]"
    echo "Example: sbatch catalog_add_job.slurm output/bear bear 5.0,0.0,1.5 0,45,0 1.2"
    exit 1
fi

echo "=================================================="
echo "Capoom Catalog Addition Job"
echo "=================================================="
echo "Target Scene: $TARGET_SCENE"
echo "Catalog Object: $CATALOG_OBJ"
echo "Position: $POSITION"
echo "Rotation: $ROTATION"
echo "Scale: $SCALE"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "Start time: $(date)"
echo "=================================================="

# Activate environment
source activate_env.sh

# Create logs directory
mkdir -p logs

# Check if catalog object exists
if [ ! -d "catalog/$CATALOG_OBJ" ]; then
    echo "ERROR: Catalog object 'catalog/$CATALOG_OBJ' not found!"
    echo "Available catalog objects:"
    ls -1 catalog/
    exit 1
fi

echo ""
echo "Catalog object found: catalog/$CATALOG_OBJ"
echo "Metadata:"
cat "catalog/$CATALOG_OBJ/metadata.json"

# Add object to scene
echo ""
echo "Adding object to scene..."
echo "Running: python capoom_street_furniture.py --scene $TARGET_SCENE --mode add --objects $CATALOG_OBJ --position $POSITION --rotation $ROTATION --scale $SCALE"
python capoom_street_furniture.py \
    --scene "$TARGET_SCENE" \
    --mode add \
    --objects "$CATALOG_OBJ" \
    --position "$POSITION" \
    --rotation "$ROTATION" \
    --scale "$SCALE"

if [ $? -ne 0 ]; then
    echo "ERROR: Addition failed!"
    exit 1
fi

echo "✓ Object added successfully"

# Render modified scene
echo ""
echo "Rendering modified scene..."
python render.py \
    -m "$TARGET_SCENE" \
    --iteration 30000_modified \
    --skip_test \
    --quiet

if [ $? -eq 0 ]; then
    echo "✓ Rendering complete"
    echo "Output: $TARGET_SCENE/train/ours_30000_modified/renders/"
else
    echo "⚠ Rendering failed (scene modified but not rendered)"
fi

echo ""
echo "=================================================="
echo "Job Complete!"
echo "Modified scene saved to:"
echo "  $TARGET_SCENE/point_cloud/iteration_30000_modified/"
echo "End time: $(date)"
echo "=================================================="
