#!/bin/bash
#SBATCH --job-name=mcity_gg
#SBATCH --account=navarch1
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --gres=gpu:1
#SBATCH --time=24:00:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=$HOME/gaussian-grouping/logs/train_mcity_grouping_%j.out
#SBATCH --error=$HOME/gaussian-grouping/logs/train_mcity_grouping_%j.err

# Environment setup
cd $HOME/gaussian-grouping
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
echo "Output: output/mcity_grouping"
echo "Iterations: 30,000 (each iteration = 1 random image)"
echo ""

# Train Gaussian Grouping from scratch
python train.py \
    -s data/mcity \
    --model_path output/mcity_grouping \
    --iterations 30000 \
    --save_iterations 5000 10000 15000 20000 25000 30000 \
    --checkpoint_iterations 5000 10000 15000 20000 25000 30000 \
    --test_iterations 5000 10000 15000 20000 25000 30000 \
    --eval

echo ""
echo "========================================="
echo "Training completed!"
echo "End time: $(date)"
echo "========================================="
echo ""
echo "Output saved to: output/mcity_grouping/"
echo "Final PLY with obj_dc: output/mcity_grouping/point_cloud/iteration_30000/point_cloud.ply"
echo ""
echo "To view segmentations:"
echo "  python render.py -m output/mcity_grouping"
echo "  python tools/segment_ply.py --input output/mcity_grouping/point_cloud/iteration_30000/point_cloud.ply --mode obj_dc"
