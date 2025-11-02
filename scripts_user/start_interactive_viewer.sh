#!/bin/bash
# Interactive X11 Viewer Setup
# Run this script after connecting with: ssh -X chabeck@greatlakes.arc-ts.umich.edu

echo "=========================================="
echo "Starting Interactive X11 Viewer Session"
echo "=========================================="

# Check X11
if [ -z "$DISPLAY" ]; then
    echo "❌ ERROR: No X11 forwarding detected!"
    echo "Please reconnect with: ssh -X chabeck@greatlakes.arc-ts.umich.edu"
    exit 1
fi

echo "✅ X11 DISPLAY: $DISPLAY"
echo ""
echo "Requesting interactive GPU node with X11..."
echo ""

# Request interactive session
srun --account=entr490s113y25_class \
     --partition=spgpu \
     --gres=gpu:1 \
     --cpus-per-task=8 \
     --mem=32GB \
     --time=04:00:00 \
     --x11 \
     --pty bash -c '
     
echo "=========================================="
echo "On compute node: $HOSTNAME"
echo "X11 DISPLAY: $DISPLAY"
echo "=========================================="

# Load modules
module load cuda/12.8.1

# Activate conda properly
source ~/miniconda3/etc/profile.d/conda.sh 2>/dev/null || source ~/.conda/etc/profile.d/conda.sh 2>/dev/null || eval "$(conda shell.bash hook)"
conda activate gaussian_grouping

# Build SIBR if needed
SIBR_VIEWER="/home/chabeck/gaussian-splatting/SIBR_viewers/install/bin/SIBR_remoteGaussian_app"

if [ ! -f "$SIBR_VIEWER" ]; then
    echo ""
    echo "Installing SIBR dependencies (first time only)..."
    
    # Install OpenCV via conda on the compute node
    conda install -c conda-forge libopencv py-opencv -y
    
    echo ""
    echo "Building SIBR viewers (10-15 min)..."
    cd /home/chabeck/gaussian-splatting/SIBR_viewers
    
    rm -rf build
    
    # Set library paths for CMake to find
    export CMAKE_PREFIX_PATH=$CONDA_PREFIX:$CMAKE_PREFIX_PATH
    export CMAKE_LIBRARY_PATH=$CONDA_PREFIX/lib:$CMAKE_LIBRARY_PATH
    export CMAKE_INCLUDE_PATH=$CONDA_PREFIX/include:$CMAKE_INCLUDE_PATH
    
    cmake -Bbuild . \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_PREFIX_PATH=$CONDA_PREFIX \
        -DGLEW_INCLUDE_DIR=$CONDA_PREFIX/include \
        -DGLEW_SHARED_LIBRARY_RELEASE=$CONDA_PREFIX/lib/libGLEW.so.2.1.0 \
        -DGLFW3_INCLUDE_DIR=$CONDA_PREFIX/include \
        -DASSIMP_INCLUDE_DIR=$CONDA_PREFIX/include \
        -DASSIMP_LIBRARY=$CONDA_PREFIX/lib/libassimp.so \
        -DOpenCV_DIR=$CONDA_PREFIX/lib/cmake/opencv4
    
    cmake --build build -j8 --target install
    
    echo "✅ SIBR build complete!"
else
    echo "✅ SIBR already built"
fi

echo ""
echo "=========================================="
echo "Starting Gaussian Grouping Viewer"
echo "=========================================="

cd /home/chabeck/gaussian-grouping

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
echo "Session ended"
'
