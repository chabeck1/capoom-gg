#!/bin/bash
#SBATCH --job-name=render_regular
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --gpus-per-node=1
#SBATCH --time=00:30:00
#SBATCH --output=logs/render_regular_%j.out
#SBATCH --error=logs/render_regular_%j.err

cd $HOME/gaussian-grouping
source activate_env.sh

echo "========================================="
echo "Rendering Regular Visualization"
echo "========================================="

# Render High-Res Model with standard coloring (PCA of features)
python render.py \
    --model_path output/mcity_grouping_highres \
    --iteration 30000 \
    --skip_test

echo "Rendering complete."
