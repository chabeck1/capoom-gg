#!/bin/bash
#SBATCH --job-name=gg_viewer
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --gpus-per-node=1
#SBATCH --mem=32GB
#SBATCH --time=02:00:00
#SBATCH --output=logs/viewer_%j.log
#SBATCH --error=logs/viewer_%j.err

# Gaussian Grouping Real-Time Viewer Server
# Allows real-time visualization and editing while training

echo "=========================================="
echo "Gaussian Grouping Viewer Server"
echo "=========================================="
echo "Job started at $(date)"
echo "Running on node: $(hostname)"
echo "Job ID: $SLURM_JOB_ID"
echo ""

# Get the full hostname for SSH tunnel
HOSTNAME=$(hostname -f)
echo "📡 To connect from your Mac, run this command:"
echo ""
echo "   ssh -L 6009:${HOSTNAME}:6009 chabeck@greatlakes.arc-ts.umich.edu"
echo ""
echo "Then keep that terminal open and connect with SIBR viewer:"
echo "   ./SIBR_remoteGaussian_app --port 6009"
echo ""
echo "=========================================="
echo ""

# Load CUDA
module load cuda/11.3.0

# Activate environment
source ~/.bashrc
conda activate gaussian_grouping

# Navigate to project directory
cd /home/chabeck/gaussian-grouping

# Default scene (can customize)
SCENE=${1:-"mcity_sync_1002"}
OUTPUT_DIR="output/${SCENE}_viewer"

echo "Starting viewer server..."
echo "Scene: $SCENE"
echo "Output: $OUTPUT_DIR"
echo "Port: 6009"
echo "IP: 0.0.0.0 (listening on all interfaces)"
echo ""
echo "Server will run for up to 2 hours or until you cancel the job."
echo "Connect with SIBR viewer to start real-time editing!"
echo ""

# Run viewer in continue training mode with a loop to keep it alive
# The server will wait for connections and stay alive
while true; do
    echo "[$(date)] Starting viewer server (waiting for connections)..."
    
    python train.py \
        -s data/${SCENE} \
        -m ${OUTPUT_DIR} \
        --port 6009 \
        --ip 0.0.0.0 \
        --config config/gaussian_dataset/train.json \
        --iterations 100000 \
        --test_iterations -1 \
        --save_iterations -1 \
        --checkpoint_iterations -1 &
    
    PID=$!
    echo "Viewer server running with PID $PID"
    
    # Wait for the process or until user cancels
    wait $PID
    EXIT_CODE=$?
    
    echo "[$(date)] Viewer process exited with code $EXIT_CODE"
    
    # If it was killed by signal (job cancelled), exit cleanly
    if [ $EXIT_CODE -gt 128 ]; then
        echo "Job cancelled by user"
        break
    fi
    
    # Otherwise restart after a short delay
    echo "Restarting in 5 seconds..."
    sleep 5
done

echo ""
echo "Viewer server stopped at $(date)"
