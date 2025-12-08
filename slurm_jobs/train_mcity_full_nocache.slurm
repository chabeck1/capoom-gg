#!/bin/bash
#SBATCH --job-name=gg_full_nocache
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --gpus-per-node=1
#SBATCH --mem=200GB
#SBATCH --time=08:00:00
#SBATCH --output=logs/train_mcity_full_nocache_%j.log
#SBATCH --error=logs/train_mcity_full_nocache_%j.err

echo "=========================================="
echo "Gaussian Grouping Training - Full Dataset (No Image Caching)"
echo "=========================================="
echo "Job started at $(date)"
echo "Running on node: $(hostname)"
echo "Job ID: $SLURM_JOB_ID"
echo "Memory allocated: 200GB"
echo "Strategy: Reload images from disk on every access (slower but constant memory)"
echo ""

# Load CUDA
module load cuda/11.3.0

# Activate environment
source ~/.bashrc
conda activate gaussian_grouping

# Navigate to project directory
cd $HOME/gaussian-grouping

echo "Dataset: mcity (33,450 images)"
echo "Output: output/mcity_full_nocache"
echo "Iterations: 30,000"
echo ""

# Train on full dataset - images reload on every access
python train.py \
    -s data/mcity \
    -m output/mcity_full_nocache \
    --config config/gaussian_dataset/train.json

echo ""
echo "Training completed at $(date)"
