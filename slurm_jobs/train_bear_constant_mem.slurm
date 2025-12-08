#!/bin/bash
#SBATCH --job-name=gg_bear_test
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --gpus-per-node=1
#SBATCH --mem=32GB
#SBATCH --time=02:00:00
#SBATCH --output=logs/train_bear_constant_mem_%j.log
#SBATCH --error=logs/train_bear_constant_mem_%j.err

echo "=========================================="
echo "Bear Dataset - Constant Memory Test"
echo "=========================================="
echo "Job started at $(date)"
echo "Running on node: $(hostname)"
echo "Job ID: $SLURM_JOB_ID"
echo "Purpose: Verify constant memory mode doesn't affect quality"
echo ""

# Load CUDA
module load cuda/11.3.0

# Activate environment
source ~/.bashrc
conda activate gaussian_grouping

# Navigate to project directory
cd /home/chabeck/gaussian-grouping

echo "Dataset: bear (96 images)"
echo "Output: output/bear_constant_mem"
echo "Iterations: 30,000"
echo "Mode: Constant memory (lazy loading)"
echo ""

echo "Initial memory state:"
nvidia-smi --query-gpu=memory.used,memory.total --format=csv
echo ""

# Train with constant memory mode (automatic)
python train.py \
    -s data/bear \
    -m output/bear_constant_mem \
    --iterations 30000 \
    --config config/gaussian_dataset/train.json

echo ""
echo "Final memory state:"
nvidia-smi --query-gpu=memory.used,memory.total --format=csv
echo ""
echo "Training completed at $(date)"
