#!/bin/bash
#SBATCH --job-name=mcity_1B_600000
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --gpus-per-node=1
#SBATCH --time=08:00:00
#SBATCH --mail-type=FAIL
#SBATCH --output=logs/mcity_1B_600000_%j.out
#SBATCH --error=logs/mcity_1B_600000_%j.err

# Environment setup
cd /home/chabeck/gaussian-grouping
source activate_env.sh

echo "========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Segment: 500000 -> 600000"
echo "Start time: $(date)"
echo "========================================="

# Train Gaussian Grouping
python train.py \
    -s data/mcity \
    --model_path output/mcity_1B \
    --config_file config/gaussian_dataset/train.json \
    --iterations 600000 \
    --start_checkpoint output/mcity_1B/chkpnt500000.pth \
    --save_iterations 600000 \
    --checkpoint_iterations 600000 \
    --test_iterations 600000 \
    --eval

echo ""
echo "========================================="
echo "Segment completed!"
echo "End time: $(date)"
echo "========================================="
