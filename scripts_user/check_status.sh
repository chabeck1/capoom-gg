#!/bin/bash

echo "╔════════════════════════════════════════════╗"
echo "║  Gaussian Grouping Environment Status     ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Load modules
module load python3.10-anaconda cuda/11.3.0 2>/dev/null

# Check conda environment
if conda env list | grep -q "gaussian_grouping"; then
    echo "✓ Conda environment exists: gaussian_grouping"
else
    echo "✗ Conda environment not found!"
fi

# Activate and check packages
source ~/.bashrc 2>/dev/null
conda activate gaussian_grouping 2>/dev/null

echo ""
echo "Python packages:"
python -c "import torch; print(f'  ✓ PyTorch {torch.__version__}')" 2>/dev/null || echo "  ✗ PyTorch not found"
python -c "import numpy; print(f'  ✓ NumPy {numpy.__version__}')" 2>/dev/null || echo "  ✗ NumPy not found"
python -c "import cv2; print(f'  ✓ OpenCV {cv2.__version__}')" 2>/dev/null || echo "  ✗ OpenCV not found"
python -c "import wandb; print(f'  ✓ wandb installed')" 2>/dev/null || echo "  ✗ wandb not found"

echo ""
echo "CUDA extensions (need GPU node to build):"
python -c "import diff_gaussian_rasterization; print('  ✓ diff_gaussian_rasterization')" 2>/dev/null || echo "  ⚠  diff_gaussian_rasterization not built yet"
python -c "import simple_knn; print('  ✓ simple_knn')" 2>/dev/null || echo "  ⚠  simple_knn not built yet"

echo ""
echo "System:"
echo "  Node: $(hostname)"
echo "  CUDA_HOME: $CUDA_HOME"
if command -v nvidia-smi &> /dev/null; then
    echo "  GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)"
else
    echo "  GPU: Not available (login node)"
fi

echo ""
echo "═══════════════════════════════════════════"
if python -c "import diff_gaussian_rasterization" 2>/dev/null; then
    echo "Status: ✓ Ready to use!"
else
    echo "Status: ⚠  Build CUDA extensions on GPU node"
    echo "Run: sbatch build_extensions.slurm"
fi
echo "═══════════════════════════════════════════"
