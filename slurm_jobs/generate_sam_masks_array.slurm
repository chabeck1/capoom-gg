#!/bin/bash
#SBATCH --job-name=gen_sam_masks_array
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --gpus-per-node=1
#SBATCH --time=03:00:00
#SBATCH --array=0-19
#SBATCH --output=logs/gen_sam_masks_array_%A_%a.out
#SBATCH --error=logs/gen_sam_masks_array_%A_%a.err

cd $HOME/gaussian-grouping
source activate_env.sh

echo "========================================="
echo "Generating SAM Masks (Array Job)"
echo "Task ID: $SLURM_ARRAY_TASK_ID"
echo "========================================="

# Define input and output directories
IMAGE_DIR="data/mcity/images"
OUTPUT_DIR="data/mcity/sam_masks_auto"
NUM_SPLITS=20

echo "Input: $IMAGE_DIR"
echo "Output: $OUTPUT_DIR"
echo "Mode: Automatic (Segment Everything)"
echo "Split: $SLURM_ARRAY_TASK_ID / $NUM_SPLITS"

python generate_sam_masks.py \
    --image_dir "$IMAGE_DIR" \
    --output_dir "$OUTPUT_DIR" \
    --automatic \
    --split_idx $SLURM_ARRAY_TASK_ID \
    --num_splits $NUM_SPLITS

echo "Task complete."
