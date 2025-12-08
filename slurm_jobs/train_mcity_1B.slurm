#!/bin/bash
#SBATCH --job-name=mcity_1B
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=50G
#SBATCH --gpus-per-node=1
#SBATCH --time=08:00:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=/home/chabeck/gaussian-grouping/logs/train_mcity_1B_%j.out
#SBATCH --error=/home/chabeck/gaussian-grouping/logs/train_mcity_1B_%j.err

# Environment setup
cd /home/chabeck/gaussian-grouping
source activate_env.sh

echo "========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "Start time: $(date)"
echo "========================================="

# GPU info
nvidia-smi

echo ""
echo "Training Gaussian Grouping on MCity dataset..."
echo "Dataset: data/mcity (33,450 images)"
echo "Output: output/mcity_1B"
echo "Iterations: 1,000,000,000 (1 Billion)"
echo "Memory: 200GB"
echo ""

# Train Gaussian Grouping
# Note: 1B iterations is extremely large. Saving checkpoints every 100k to avoid disk fill.
# Using single line command to avoid line continuation issues
python train.py -s data/mcity --model_path output/mcity_1B --config_file config/gaussian_dataset/train.json --iterations 1000000000 --save_iterations 100000 500000 1000000 10000000 100000000 1000000000 --checkpoint_iterations 100000 500000 1000000 10000000 100000000 1000000000 --test_iterations 100000 1000000 --eval

echo ""
echo "========================================="
echo "Training completed (or timed out)!"
echo "End time: $(date)"
echo "========================================="
