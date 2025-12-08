#!/bin/bash
#SBATCH --job-name=mcity_grouping
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --gpus-per-node=1
#SBATCH --time=04:00:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=logs/train_mcity_grouping_%j.out
#SBATCH --error=logs/train_mcity_grouping_%j.err

# Environment setup
cd /home/chabeck/gaussian-grouping
source activate_env.sh

echo "========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Start time: $(date)"
echo "========================================="

# Train Gaussian Grouping (Grouping Only)
# Freezing geometry and appearance, training only grouping attributes.
python train.py \
    -s data/mcity \
    --model_path output/mcity_grouping_only \
    --config_file config/gaussian_dataset/train.json \
    --start_ply output/capoom_ply/point_cloud/iteration_100/point_cloud_1.ply \
    --iterations 30000 \
    --densify_until_iter 0 \
    --resolution 2 \
    --position_lr_init 0 \
    --position_lr_final 0 \
    --feature_lr 0 \
    --opacity_lr 0 \
    --scaling_lr 0 \
    --rotation_lr 0 \
    --grouping_lr 0.0025 \
    --save_iterations 7000 30000 \
    --test_iterations 7000 30000 \
    --eval

echo ""
echo "========================================="
echo "Training completed!"
echo "End time: $(date)"
echo "========================================="
