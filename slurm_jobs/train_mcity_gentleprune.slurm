#!/bin/bash
#SBATCH --job-name=gg_mcity_gentleprune
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --gpus-per-node=1
#SBATCH --mem=100GB
#SBATCH --time=08:00:00
#SBATCH --output=logs/train_mcity_gentleprune_%j.log
#SBATCH --error=logs/train_mcity_gentleprune_%j.err

echo "=========================================="
echo "Mcity Training - Gentle Pruning (Large Dataset Fix)"
echo "=========================================="
echo "Job started at $(date)"
echo "Running on node: $(hostname)"
echo "Job ID: $SLURM_JOB_ID"
echo ""

# Load CUDA
module load cuda/11.3.0

# Activate environment
source ~/.bashrc
conda activate gaussian_grouping

# Navigate to project directory
cd $HOME/gaussian-grouping

echo "Dataset: mcity (33,450 images)"
echo "Output: output/mcity_gentleprune"
echo "Iterations: 100,000"
echo ""
echo "IMPROVEMENTS:"
echo "  ✓ Opacity threshold: 0.0005 (10x more lenient)"
echo "  ✓ Densify until: 50,000 (was 15,000)"
echo "  ✓ Size pruning delayed until iter 40,000"
echo "  ✓ Constant memory mode"
echo ""

# Train with gentle pruning
python train.py \
    -s data/mcity \
    -m output/mcity_gentleprune \
    --iterations 100000 \
    --config config/gaussian_dataset/train.json

echo ""
echo "Training completed at $(date)"
