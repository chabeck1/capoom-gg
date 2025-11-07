#!/bin/bash
#SBATCH --job-name=eval_seg
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16GB
#SBATCH --gres=gpu:1
#SBATCH --time=00:10:00
#SBATCH --output=logs/eval_segmentation_%j.out

# Evaluate segmentation accuracy against ground truth
# Usage: sbatch slurm_jobs/eval_segmentation.slurm output/bear

SCENE=${1:-output/bear}

echo "=================================================="
echo "Segmentation Accuracy Evaluation"
echo "=================================================="
echo "Scene: $SCENE"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "Start time: $(date)"
echo "=================================================="

source activate_env.sh

python evaluate_segmentation.py --scene "$SCENE"

echo ""
echo "=================================================="
echo "Evaluation complete!"
echo "End time: $(date)"
echo "=================================================="
