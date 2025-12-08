#!/bin/bash
#SBATCH --job-name=render_custom
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --gpus-per-node=1
#SBATCH --time=00:30:00
#SBATCH --output=logs/render_custom_%j.out
#SBATCH --error=logs/render_custom_%j.err

cd $HOME/gaussian-grouping
source activate_env.sh

echo "========================================="
echo "Rendering Custom Colored Segmentation"
echo "========================================="

# Render High-Res Model
# Skip train views to save time, focus on test views (or vice versa if test set is empty)
# The user likely wants to see the training views since that's where the data is.
# Let's render a subset of training views if possible, but the script renders all.
# We'll render both but maybe the user only cares about one.
# Given the previous logs, "test" had 0 images in cache, suggesting maybe no test set?
# Let's check the logs again... 
# "[ITER 30000] Evaluating test: ... [ITER 30000] Evaluating train: ..."
# Both exist.

python render_custom_colors.py \
    --model_path output/mcity_grouping_highres \
    --iteration 30000 \
    --skip_test 

echo "Rendering complete."
