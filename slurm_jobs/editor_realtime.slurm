#!/bin/bash
#SBATCH --job-name=bear_editor
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --nodes=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --output=logs/editor_%j.log
#SBATCH --error=logs/editor_%j.err

mkdir -p logs

echo "════════════════════════════════════════════════════════════════"
echo "🎨 Real-Time Bear Scene Editor Starting"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Job ID:   $SLURM_JOB_ID"
echo "Node:     $(hostname)"
echo "Started:  $(date)"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "📡 CRITICAL: SET UP SSH TUNNEL ON YOUR MAC NOW!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Open a terminal on your Mac and run:"
echo ""
echo "  ssh -L 6009:$(hostname):6009 chabeck@greatlakes.arc-ts.umich.edu"
echo ""
echo "Keep that terminal open!"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Load environment
module load python3.10-anaconda cuda/11.3.0
source ~/.bashrc
conda activate gaussian_grouping

cd ~/gaussian-grouping

echo "Loading trained bear model..."
echo ""

# Start the interactive viewer/editor
# This loads the trained model and lets you interact in real-time
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
echo "════════════════════════════════════════════════════════════════"
echo "Editor stopped at $(date)"
echo "════════════════════════════════════════════════════════════════"
