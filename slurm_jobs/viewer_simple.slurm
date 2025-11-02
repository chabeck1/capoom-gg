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

# Simple viewer that loads trained model and allows real-time interaction

SCENE_NAME="${1:-bear}"
ITERATION="${2:-30000}"
PORT="${3:-6009}"

DATA_PATH="data/${SCENE_NAME}"
MODEL_PATH="output/${SCENE_NAME}"
CONFIG_FILE="config/gaussian_dataset/train.json"

mkdir -p logs

echo "════════════════════════════════════════════════════════════════"
echo "🎮 Gaussian Grouping Real-Time Viewer"
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
echo "  Iteration:   $ITERATION"
echo "  Port:        $PORT"
echo ""

echo "════════════════════════════════════════════════════════════════"
echo "📡 SSH TUNNEL - RUN THIS ON YOUR MAC:"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "ssh -L ${PORT}:$(hostname):${PORT} ${USER}@greatlakes.arc-ts.umich.edu"
echo ""
echo "Then connect SIBR viewer to localhost:${PORT}"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Load environment
module load python3.10-anaconda cuda/11.3.0
source ~/.bashrc
conda activate gaussian_grouping

cd ~/gaussian-grouping

echo "Starting viewer server on port ${PORT}..."
echo ""

# Run viewer without checkpoint - it will load from the model_path
python train.py \
    -s "$DATA_PATH" \
    -m "$MODEL_PATH" \
    --iteration "$ITERATION" \
    --port "$PORT" \
    --ip 0.0.0.0 \
    --test_iterations -1 \
    --save_iterations -1 \
    --config_file "$CONFIG_FILE"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "Viewer stopped at $(date)"
echo "════════════════════════════════════════════════════════════════"
