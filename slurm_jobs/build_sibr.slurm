#!/bin/bash
#SBATCH --job-name=build_sibr
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32GB
#SBATCH --time=02:00:00
#SBATCH --output=logs/build_sibr_%j.log
#SBATCH --error=logs/build_sibr_%j.err

echo "=========================================="
echo "Building SIBR Viewers on Great Lakes"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $HOSTNAME"
echo "Start time: $(date)"
echo "=========================================="

# Load required modules
module load cuda/12.4.1
module load gcc/12.2.0
module load cmake/3.28.2

# Setup conda environment
source ~/miniconda3/etc/profile.d/conda.sh
conda activate gaussian_grouping

# Navigate to gaussian-splatting directory
cd /home/chabeck/gaussian-splatting

# Clone SIBR_viewers if not present
if [ ! -d "SIBR_viewers" ] || [ ! "$(ls -A SIBR_viewers)" ]; then
    echo "Cloning SIBR_viewers submodule..."
    git submodule update --init --recursive
fi

cd SIBR_viewers

# Create build directory
mkdir -p build
cd build

# Configure with CMake
echo "Configuring SIBR with CMake..."
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CUDA_COMPILER=/sw/pkgs/arc/cuda/12.4.1/bin/nvcc \
    -DCUDA_TOOLKIT_ROOT_DIR=/sw/pkgs/arc/cuda/12.4.1

# Build
echo "Building SIBR (this will take 10-20 minutes)..."
make -j8

# Install
echo "Installing SIBR..."
make install

echo "=========================================="
echo "Build complete!"
echo "End time: $(date)"
echo "=========================================="
echo ""
echo "SIBR viewers installed to:"
echo "/home/chabeck/gaussian-splatting/SIBR_viewers/install/bin/"
echo ""
echo "To use the remote viewer with X11 forwarding:"
echo "  ssh -X chabeck@greatlakes.arc-ts.umich.edu"
echo "  srun --account=entr490s113y25_class --partition=spgpu --gres=gpu:1 --pty bash"
echo "  cd /home/chabeck/gaussian-splatting/SIBR_viewers/install/bin"
echo "  ./SIBR_remoteGaussian_app --port 6009"
