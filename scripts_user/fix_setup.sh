#!/bin/bash

# Source conda configuration
source ~/.bashrc

# Load required modules
module load python3.10-anaconda
module load cuda/11.3.0

# Activate the conda environment
conda activate gaussian_grouping

echo "Uninstalling incompatible PyTorch..."
pip uninstall -y torch torchvision torchaudio

echo "Installing PyTorch 1.12.1 with CUDA 11.3 support..."
pip install torch==1.12.1+cu113 torchvision==0.13.1+cu113 torchaudio==0.12.1 --extra-index-url https://download.pytorch.org/whl/cu113

# Verify PyTorch installation
python -c "import torch; print(f'PyTorch version: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}'); print(f'CUDA version: {torch.version.cuda}')"

echo ""
echo "Installing CUDA extensions..."
pip install submodules/diff-gaussian-rasterization
pip install submodules/simple-knn

echo ""
echo "============================================"
echo "Setup complete!"
echo "============================================"
echo ""
echo "To use the environment, run:"
echo "  source ~/.bashrc"
echo "  module load python3.10-anaconda cuda/11.3.0"
echo "  conda activate gaussian_grouping"
