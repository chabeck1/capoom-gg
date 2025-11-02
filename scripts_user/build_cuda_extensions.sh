#!/bin/bash

# This script should be run on a GPU node
# Load required modules
module load python3.10-anaconda
module load cuda/11.3.0

# Activate the conda environment
source ~/.bashrc
conda activate gaussian_grouping

echo "Building CUDA extensions on GPU node..."
echo "Current node: $(hostname)"
echo "CUDA_HOME: $CUDA_HOME"

# Check if CUDA is available
python -c "import torch; print(f'PyTorch version: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}'); print(f'CUDA version: {torch.version.cuda}')"

# Set environment variable to specify CUDA architecture
# Common architectures: 7.0 (V100), 7.5 (T4), 8.0 (A100), 8.6 (A30/A40)
# Let PyTorch auto-detect if possible, or set manually
export TORCH_CUDA_ARCH_LIST="7.0 7.5 8.0"

# Install diff-gaussian-rasterization
echo ""
echo "Installing diff-gaussian-rasterization..."
cd ~/gaussian-grouping
pip install submodules/diff-gaussian-rasterization

# Install simple-knn
echo ""
echo "Installing simple-knn..."
pip install submodules/simple-knn

echo ""
echo "============================================"
echo "CUDA extensions build complete!"
echo "============================================"
