#!/bin/bash
#SBATCH --job-name=edit_text
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --gres=gpu:1
#SBATCH --time=02:00:00
#SBATCH --output=logs/edit_text_%j.log

# Usage: sbatch edit_by_text_job.slurm <scene> <text> [--inpaint]
# Example: sbatch edit_by_text_job.slurm output/bear "trees;rocks" --inpaint

SCENE=${1:-"output/bear"}
TEXT=${2:-"bear"}
INPAINT_FLAG=${3:-""}

# Load conda
source activate_env.sh

echo "Text-Based 3D Scene Editing"
echo "============================"
echo "Scene: $SCENE"
echo "Remove: $TEXT"
echo "Inpaint: ${INPAINT_FLAG:-no}"
echo ""

# Run the text-based editing
python edit_by_text.py --scene "$SCENE" --remove "$TEXT" $INPAINT_FLAG --no-confirm

echo ""
echo "✅ Job complete!"
