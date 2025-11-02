#!/bin/bash

# Convenient script to activate the Gaussian Grouping environment
source ~/.bashrc
module load python3.10-anaconda
module load cuda/11.3.0
conda activate gaussian_grouping

echo "Gaussian Grouping environment activated!"
echo "PyTorch version: $(python -c 'import torch; print(torch.__version__)')"
echo "CUDA available: $(python -c 'import torch; print(torch.cuda.is_available())')"
