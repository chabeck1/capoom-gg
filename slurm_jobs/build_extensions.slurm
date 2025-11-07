#!/bin/bash
#SBATCH --job-name=build_gaussian_grouping
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --gres=gpu:1
#SBATCH --time=01:00:00
#SBATCH --mem=16G
#SBATCH --output=build_extensions_%j.log

# Load required modules
module load python3.10-anaconda
module load cuda/11.3.0

# Activate conda environment
source ~/.bashrc
conda activate gaussian_grouping

echo "Job started on $(hostname) at $(date)"
echo "CUDA_HOME: $CUDA_HOME"
echo "GPU info:"
nvidia-smi

# Build CUDA extensions
cd ~/gaussian-grouping

echo ""
echo "Building diff-gaussian-rasterization..."
pip install submodules/diff-gaussian-rasterization

echo ""
echo "Building simple-knn..."
pip install submodules/simple-knn

echo ""
echo "Verifying installation..."
python -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}')"
python -c "import diff_gaussian_rasterization; print('diff_gaussian_rasterization imported successfully')"
python -c "import simple_knn; print('simple_knn imported successfully')"

echo ""
echo "Job completed at $(date)"
