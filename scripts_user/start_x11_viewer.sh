#!/bin/bash
# Start Gaussian Grouping viewer with X11 forwarding
# Run this from an ssh -X session

echo "=========================================="
echo "Starting Gaussian Grouping X11 Viewer"
echo "=========================================="

# Check if X11 forwarding is working
if [ -z "$DISPLAY" ]; then
    echo "❌ ERROR: X11 forwarding not active!"
    echo "Please connect with: ssh -X chabeck@greatlakes.arc-ts.umich.edu"
    exit 1
fi

echo "✅ X11 DISPLAY: $DISPLAY"

# Load modules
echo "Loading CUDA module..."
module load cuda/12.8.1

# Activate conda environment
echo "Activating gaussian_grouping environment..."
conda activate gaussian_grouping

# Navigate to directory
cd /home/chabeck/gaussian-grouping

# Start training with viewer enabled
echo ""
echo "Starting viewer server..."
echo "This will open a viewer window on your Mac!"
echo ""

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
echo "Viewer session ended."
