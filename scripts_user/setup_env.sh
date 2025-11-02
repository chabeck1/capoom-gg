#!/bin/bash

# Load required modules
module load python3.10-anaconda
module load cuda/11.3.0

# Activate the conda environment
source activate gaussian_grouping

# Install PyTorch and related packages
echo "Installing PyTorch..."
conda install pytorch==1.12.1 torchvision==0.13.1 torchaudio==0.12.1 cudatoolkit=11.3 -c pytorch -y

# Install other required packages
echo "Installing other dependencies..."
pip install plyfile==0.8.1
pip install tqdm scipy wandb opencv-python scikit-learn lpips

# Install custom CUDA extensions
echo "Installing diff-gaussian-rasterization..."
pip install submodules/diff-gaussian-rasterization

echo "Installing simple-knn..."
pip install submodules/simple-knn

echo "Setup complete!"
echo "To use the environment, run:"
echo "  module load python3.10-anaconda cuda/11.3.0"
echo "  conda activate gaussian_grouping"
