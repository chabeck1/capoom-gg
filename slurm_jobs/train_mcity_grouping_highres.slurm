#!/bin/bash
#SBATCH --job-name=mcity_grouping_highres
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=100G
#SBATCH --gpus-per-node=1
#SBATCH --time=04:00:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=logs/train_mcity_grouping_highres_%j.out
#SBATCH --error=logs/train_mcity_grouping_highres_%j.err

# Environment setup
cd $HOME/gaussian-grouping
source activate_env.sh

echo "========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Start time: $(date)"
echo "========================================="

# Train Gaussian Grouping (Grouping Only) - High Res
# Freezing geometry and appearance, training only grouping attributes.
# Using 100GB RAM and full resolution (no --resolution 2)
python train.py \
    -s data/mcity \
    --model_path output/mcity_grouping_highres \
    --config_file config/gaussian_dataset/train.json \
    --start_ply output/capoom_ply/point_cloud/iteration_100/point_cloud_1.ply \
    --iterations 30000 \
    --densify_until_iter 0 \
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
