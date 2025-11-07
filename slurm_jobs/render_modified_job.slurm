#!/bin/bash
#SBATCH --job-name=render_modified
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32GB
#SBATCH --gres=gpu:1
#SBATCH --time=00:30:00
#SBATCH --output=logs/render_modified_%j.out
#SBATCH --error=logs/render_modified_%j.err

# Render Modified Scene
# Usage: sbatch slurm_jobs/render_modified_job.slurm <scene_path> <iteration>
# Example: sbatch slurm_jobs/render_modified_job.slurm output/bear 30000_modified

SCENE_PATH=${1:-"output/bear"}
ITERATION=${2:-"30000_modified"}

echo "=================================================="
echo "Rendering Modified Scene"
echo "=================================================="
echo "Scene: $SCENE_PATH"
echo "Iteration: $ITERATION"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "Start time: $(date)"
echo "=================================================="

# Activate environment
source activate_env.sh

# Create logs directory
mkdir -p logs

# Render the scene
echo ""
echo "Rendering scene with iteration $ITERATION..."
python render.py \
    -m "$SCENE_PATH" \
    --iteration "$ITERATION" \
    --skip_test

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Rendering complete!"
    echo "Output directory: $SCENE_PATH/train/ours_$ITERATION/renders/"
    
    # Count rendered images
    NUM_IMAGES=$(ls "$SCENE_PATH/train/ours_$ITERATION/renders/"*.png 2>/dev/null | wc -l)
    echo "Generated $NUM_IMAGES images"
else
    echo ""
    echo "✗ Rendering failed"
    exit 1
fi

echo ""
echo "=================================================="
echo "Job Complete!"
echo "End time: $(date)"
echo "=================================================="
