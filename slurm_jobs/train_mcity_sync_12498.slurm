#!/bin/bash
#SBATCH --job-name=gg_12498
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --gpus-per-node=1
#SBATCH --mem=250GB
#SBATCH --time=08:00:00
#SBATCH --output=logs/train_mcity_sync_12498_%j.log
#SBATCH --error=logs/train_mcity_sync_12498_%j.err

echo "=========================================="
echo "Gaussian Grouping Training - mcity_sync_12498"
echo "=========================================="
echo "Job started at $(date)"
echo "Running on node: $(hostname)"
echo "Job ID: $SLURM_JOB_ID"
echo "Memory allocated: 250GB"
echo ""

# Load CUDA
module load cuda/11.3.0

# Activate environment
source ~/.bashrc
conda activate gaussian_grouping

# Navigate to project directory
cd /home/chabeck/gaussian-grouping

echo "Dataset: mcity_sync_12498 (12,498 images)"
echo "Output: output/mcity_sync_12498"
echo "Iterations: 30,000"
echo ""

# Train
python train.py \
    -s data/mcity_sync_12498 \
    -m output/mcity_sync_12498 \
    --config config/gaussian_dataset/train.json

echo ""
echo "Training completed at $(date)"
