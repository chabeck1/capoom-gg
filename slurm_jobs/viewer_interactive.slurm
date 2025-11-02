#!/bin/bash
#SBATCH --job-name=gg_viewer
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --nodes=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --output=logs/viewer_%j.log
#SBATCH --error=logs/viewer_%j.err

# ════════════════════════════════════════════════════════════════════
# Real-Time Gaussian Grouping Viewer Job
# ════════════════════════════════════════════════════════════════════
# 
# This job starts an interactive 3D viewer for your trained scenes.
# You can view the scene in real-time while training or view a 
# completed checkpoint.
#
# USAGE:
#   sbatch slurm_jobs/viewer_interactive.slurm [SCENE_NAME] [ITERATION]
#
# EXAMPLES:
#   sbatch slurm_jobs/viewer_interactive.slurm bear 30000
#   sbatch slurm_jobs/viewer_interactive.slurm test_scene 15000
#
# If no arguments provided, defaults to bear scene at iteration 30000
# ════════════════════════════════════════════════════════════════════

# Parse arguments or use defaults
SCENE_NAME="${1:-bear}"
ITERATION="${2:-30000}"
PORT="${3:-6009}"

# Paths
DATA_PATH="data/${SCENE_NAME}"
MODEL_PATH="output/${SCENE_NAME}"
CHECKPOINT_PATH="${MODEL_PATH}/point_cloud/iteration_${ITERATION}/point_cloud.ply"
CONFIG_FILE="config/gaussian_dataset/train.json"

# Create log directory
mkdir -p logs

# Print header
echo "════════════════════════════════════════════════════════════════"
echo "🎮 Gaussian Grouping Interactive Viewer"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Job Information:"
echo "  Job ID:      $SLURM_JOB_ID"
echo "  Node:        $(hostname)"
echo "  Start Time:  $(date)"
echo ""
echo "Scene Configuration:"
echo "  Scene:       $SCENE_NAME"
echo "  Data Path:   $DATA_PATH"
echo "  Model Path:  $MODEL_PATH"
echo "  Checkpoint:  $CHECKPOINT_PATH"
echo "  Iteration:   $ITERATION"
echo "  Port:        $PORT"
echo ""

# Check if checkpoint exists
if [ ! -f "$CHECKPOINT_PATH" ]; then
    echo "❌ ERROR: Checkpoint not found at:"
    echo "   $CHECKPOINT_PATH"
    echo ""
    echo "Available checkpoints:"
    ls -lh ${MODEL_PATH}/point_cloud/*/point_cloud.ply 2>/dev/null || echo "   None found"
    echo ""
    exit 1
fi

echo "✅ Checkpoint found: $(du -h $CHECKPOINT_PATH | cut -f1)"
echo ""

# SSH Tunnel Instructions
echo "════════════════════════════════════════════════════════════════"
echo "📡 SSH TUNNEL SETUP REQUIRED"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "On your LOCAL Mac, run this command:"
echo ""
echo "  ssh -L ${PORT}:$(hostname):${PORT} ${USER}@greatlakes.arc-ts.umich.edu"
echo ""
echo "Or use the helper script:"
echo ""
echo "  ~/mac_tunnel.sh $(hostname)"
echo ""
echo "Then connect your viewer client to localhost:${PORT}"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Load environment
echo "Loading environment..."
module load python3.10-anaconda cuda/11.3.0
source ~/.bashrc
conda activate gaussian_grouping

# Change to project directory
cd ~/gaussian-grouping

# Viewer controls info
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "🎮 VIEWER CONTROLS (in SIBR client)"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "  Mouse:"
echo "    Left drag      → Rotate camera"
echo "    Right drag     → Pan camera"
echo "    Scroll wheel   → Zoom in/out"
echo ""
echo "  Keyboard:"
echo "    T              → Toggle training on/off"
echo "    R              → Reset camera view"
echo "    ESC            → Exit viewer"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""

# Start viewer
echo "Starting viewer server on port ${PORT}..."
echo "Viewer will run for up to 4 hours (or until cancelled)"
echo ""
echo "To monitor: tail -f logs/viewer_${SLURM_JOB_ID}.log"
echo "To stop:    scancel ${SLURM_JOB_ID}"
echo ""
echo "Server starting now..."
echo "════════════════════════════════════════════════════════════════"
echo ""

# Run the viewer
python train.py \
    -s "$DATA_PATH" \
    -m "$MODEL_PATH" \
    --start_checkpoint "$CHECKPOINT_PATH" \
    --port "$PORT" \
    --ip 0.0.0.0 \
    --test_iterations -1 \
    --save_iterations -1 \
    --config_file "$CONFIG_FILE"

# Cleanup message
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "Viewer stopped at $(date)"
echo "Total runtime: $SECONDS seconds"
echo "════════════════════════════════════════════════════════════════"
