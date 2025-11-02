#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🎮 Starting 3D Interactive Viewer"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Make sure you have port forwarding set up!"
echo "SSH command: ssh -L 6009:localhost:6009 chabeck@greatlakes.arc-ts.umich.edu"
echo ""
echo "Or in VSCode, add to SSH config:"
echo "  LocalForward 6009 localhost:6009"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Starting viewer..."
echo "Open your browser to: http://localhost:6009"
echo ""
echo "Controls:"
echo "  - Left mouse: Rotate"
echo "  - Right mouse: Pan"
echo "  - Scroll: Zoom"
echo "  - Press 'q' in terminal to quit"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""

# Activate conda environment
source ~/.bashrc
conda activate gaussian_grouping

# Launch the viewer
cd ~/gaussian-grouping

# View the trained model
python train.py -s data/bear -m output/bear \
    --start_checkpoint output/bear/point_cloud/iteration_30000/point_cloud.ply \
    --port 6009 \
    --test_iterations -1 \
    --save_iterations -1 \
    --config_file config/gaussian_dataset/train.json \
    --quiet
