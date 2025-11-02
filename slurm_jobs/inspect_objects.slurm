#!/bin/bash
#SBATCH --job-name=inspect_obj
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16GB
#SBATCH --gres=gpu:1
#SBATCH --time=00:05:00
#SBATCH --output=logs/inspect_objects_%j.out

# Quick inspection of what objects exist in scene
# Usage: sbatch slurm_jobs/inspect_objects.slurm output/bear

SCENE=$1

if [ -z "$SCENE" ]; then
    echo "Usage: sbatch inspect_objects.slurm <scene_path>"
    echo "Example: sbatch inspect_objects.slurm output/bear"
    exit 1
fi

echo "=================================================="
echo "Scene Object Inspection"
echo "=================================================="
echo "Scene: $SCENE"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "Start time: $(date)"
echo "=================================================="

source activate_env.sh

python inspect_scene_objects.py --scene "$SCENE"

echo ""
echo "=================================================="
echo "Inspection complete!"
echo "End time: $(date)"
echo "=================================================="
