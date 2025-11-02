#!/bin/bash
#SBATCH --job-name=sibr_viewer
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --gres=gpu:1
#SBATCH --mem=32GB
#SBATCH --time=04:00:00
#SBATCH --output=logs/viewer_%j.log
#SBATCH --error=logs/viewer_%j.err
#SBATCH --x11

echo "=========================================="
echo "Building SIBR and Starting Viewer"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $HOSTNAME"
echo "Start time: $(date)"
echo "X11 DISPLAY: $DISPLAY"
echo "=========================================="

# Load modules
module load cuda/12.8.1

# Activate conda environment
conda activate gaussian_grouping

# Build SIBR if not already built
SIBR_VIEWER="/home/chabeck/gaussian-splatting/SIBR_viewers/install/bin/SIBR_remoteGaussian_app"

if [ ! -f "$SIBR_VIEWER" ]; then
    echo ""
    echo "Building SIBR viewers..."
    cd /home/chabeck/gaussian-splatting/SIBR_viewers
    
    # Clean previous build
    rm -rf build
    
    # Configure with CMake
    cmake -Bbuild . \
        -DCMAKE_BUILD_TYPE=Release \
        -DGLEW_INCLUDE_DIR=$CONDA_PREFIX/include \
        -DGLEW_LIBRARY=$CONDA_PREFIX/lib/libGLEW.so \
        -DGLFW_INCLUDE_DIR=$CONDA_PREFIX/include \
        -DGLFW_LIBRARY=$CONDA_PREFIX/lib/libglfw.so \
        -DASSIMP_INCLUDE_DIR=$CONDA_PREFIX/include \
        -DASSIMP_LIBRARIES=$CONDA_PREFIX/lib/libassimp.so
    
    # Build (will take 10-15 minutes)
    cmake --build build -j8 --target install
    
    echo "✅ SIBR build complete!"
else
    echo "✅ SIBR already built, skipping build step"
fi

echo ""
echo "=========================================="
echo "Starting Gaussian Grouping Viewer"
echo "=========================================="

cd /home/chabeck/gaussian-grouping

# Start training with viewer
python train.py \
    -s data/bear \
    -m output/bear \
    --port 6009 \
    --ip 0.0.0.0 \
    --iterations 30000 \
    --test_iterations -1 \
    --save_iterations -1 \
    --checkpoint_iterations -1 \
    --config_file config/gaussian_dataset/train.json

echo ""
echo "=========================================="
echo "Viewer session ended"
echo "End time: $(date)"
echo "=========================================="
