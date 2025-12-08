#!/bin/bash
#SBATCH --job-name=gen_sam_masks
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --gpus-per-node=1
#SBATCH --time=00:30:00
#SBATCH --output=logs/gen_sam_masks_%j.out
#SBATCH --error=logs/gen_sam_masks_%j.err

cd /home/chabeck/gaussian-grouping
source activate_env.sh

echo "========================================="
echo "Generating SAM Masks"
echo "========================================="

# Define input and output directories
IMAGE_DIR="data/mcity/images"
OUTPUT_DIR="data/mcity/sam_masks_auto"

echo "Input: $IMAGE_DIR"
echo "Output: $OUTPUT_DIR"
echo "Mode: Automatic (Segment Everything)"

python generate_sam_masks.py \
    --image_dir "$IMAGE_DIR" \
    --output_dir "$OUTPUT_DIR" \
    --automatic

echo "Generation complete."
