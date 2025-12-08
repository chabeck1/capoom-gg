#!/bin/bash
#SBATCH --job-name=test_const_mem
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --gpus-per-node=1
#SBATCH --mem=16GB
#SBATCH --time=00:10:00
#SBATCH --output=$HOME/gaussian-grouping/logs/test_constant_mem_%j.log
#SBATCH --error=$HOME/gaussian-grouping/logs/test_constant_mem_%j.err

# Load CUDA
module load cuda/11.3.0

# Activate environment
source ~/.bashrc
conda activate gaussian_grouping

# Run test
echo "=========================================="
echo "Testing Constant Memory Implementation"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "GPU: $CUDA_VISIBLE_DEVICES"
echo ""

cd $HOME/gaussian-grouping
python3 test_constant_memory.py

echo ""
echo "Test completed at $(date)"
