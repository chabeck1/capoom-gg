#!/bin/bash
#SBATCH --job-name=build_sibr
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --gpus-per-node=1
#SBATCH --mem=32GB
#SBATCH --time=02:00:00
#SBATCH --output=logs/build_sibr_%j.log
#SBATCH --error=logs/build_sibr_%j.err

echo "Building SIBR Viewers..."
echo "Started: $(date)"

# Load modules
module load cuda/11.3.0 gcc/10.3.0 cmake

# Activate conda environment
source ~/.bashrc
conda activate gaussian_grouping

# Install GLEW via conda
echo "Installing GLEW..."
conda install -c conda-forge glew -y

# Build SIBR
cd $HOME/gaussian-grouping/gaussian-splatting/SIBR_viewers
rm -rf build

echo "Running cmake..."
cmake -Bbuild . -DCMAKE_BUILD_TYPE=Release \
    -DGLEW_INCLUDE_DIR=$CONDA_PREFIX/include \
    -DGLEW_LIBRARY=$CONDA_PREFIX/lib/libGLEW.so \
    -DCMAKE_PREFIX_PATH=$CONDA_PREFIX

echo "Building (this may take 15-30 minutes)..."
cmake --build build -j24 --target install

echo "Build complete: $(date)"
echo "SIBR binaries installed to: $(pwd)/install/bin/"
ls -lh install/bin/ || echo "Build failed - check error log"
