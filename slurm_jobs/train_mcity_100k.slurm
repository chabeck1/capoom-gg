#!/bin/bash
#SBATCH --job-name=gg_100k
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --gpus-per-node=1
#SBATCH --mem=205GB
#SBATCH --time=08:00:00
#SBATCH --output=logs/train_mcity_100k_%j.log
#SBATCH --error=logs/train_mcity_100k_%j.err

echo "=========================================="
echo "Gaussian Grouping Training - 100k Iterations (Constant Memory)"
echo "=========================================="
echo "Job started at $(date)"
echo "Running on node: $(hostname)"
echo "Job ID: $SLURM_JOB_ID"
echo "Memory allocated: 205GB"
echo "Strategy: Constant memory mode (load images from disk on demand)"
echo ""

# Load CUDA
module load cuda/11.3.0

# Activate environment
source ~/.bashrc
conda activate gaussian_grouping

# Navigate to project directory
cd /home/chabeck/gaussian-grouping

echo "Dataset: mcity (33,450 images)"
echo "Output: output/mcity_100k"
echo "Iterations: 100,000"
echo "Expected coverage: 3× per image"
echo "Expected PSNR improvement: 16.1 → 18-19"
echo ""

# Monitor memory usage
echo "Initial memory state:"
nvidia-smi --query-gpu=memory.used,memory.total --format=csv
echo ""

# Train with constant memory mode (automatic)
python train.py \
    -s data/mcity \
    -m output/mcity_100k \
    --iterations 100000 \
    --config config/gaussian_dataset/train.json

echo ""
echo "Final memory state:"
nvidia-smi --query-gpu=memory.used,memory.total --format=csv
echo ""
echo "Training completed at $(date)"
