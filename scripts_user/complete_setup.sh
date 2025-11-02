#!/bin/bash

# Source conda configuration
source ~/.bashrc

# Load required modules
module load python3.10-anaconda
module load cuda/11.3.0

# Activate the conda environment
conda activate gaussian_grouping

# Check if PyTorch is installed
python -c "import torch; print(f'PyTorch version: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}')" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "PyTorch not properly installed. Installing now..."
    pip install torch==2.4.1 torchvision torchaudio
fi

# Ensure all dependencies are installed
echo "Verifying dependencies..."
pip install plyfile==0.8.1 tqdm scipy wandb opencv-python scikit-learn lpips 2>/dev/null || true

# Install custom CUDA extensions
echo "Installing diff-gaussian-rasterization..."
cd ~/gaussian-grouping
pip install submodules/diff-gaussian-rasterization

echo "Installing simple-knn..."
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
