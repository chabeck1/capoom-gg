#!/bin/bash
#SBATCH --job-name=gg_full_lazy
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --gpus-per-node=1
#SBATCH --mem=300GB
#SBATCH --time=08:00:00
#SBATCH --output=logs/train_mcity_full_lazy_%j.log
#SBATCH --error=logs/train_mcity_full_lazy_%j.err

echo "=========================================="
echo "Gaussian Grouping Training - Full Dataset with Lazy Loading"
echo "=========================================="
echo "Job started at $(date)"
echo "Running on node: $(hostname)"
echo "Job ID: $SLURM_JOB_ID"
echo "Memory allocated: 300GB (for Gaussian densification)"
echo ""

# Load CUDA
module load cuda/11.3.0

# Activate environment
source ~/.bashrc
conda activate gaussian_grouping

# Navigate to project directory
cd $HOME/gaussian-grouping

echo "Dataset: mcity (33,450 images)"
echo "Output: output/mcity_full_lazy"
echo "Iterations: 30,000"
echo "Memory strategy: Lazy loading with 500-image LRU cache (~2.2GB cache)"
echo ""

# Train on full dataset with lazy loading, resuming from checkpoint if it exists
if [ -d "output/mcity_full_lazy/point_cloud/iteration_1000" ]; then
    echo "Resuming from iteration 1000 checkpoint"
    python train.py \
        -s data/mcity \
        -m output/mcity_full_lazy \
        --config config/gaussian_dataset/train.json \
        --start_checkpoint output/mcity_full_lazy/point_cloud/iteration_1000/point_cloud.ply
else
    echo "Starting fresh training"
    python train.py \
        -s data/mcity \
        -m output/mcity_full_lazy \
        --config config/gaussian_dataset/train.json
fi

echo ""
echo "Training completed at $(date)"
