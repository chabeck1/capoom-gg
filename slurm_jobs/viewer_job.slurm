#!/bin/bash
#SBATCH --job-name=gg_viewer
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --nodes=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#SBATCH --output=logs/viewer_%j.log
#SBATCH --error=logs/viewer_%j.err

# Create log directory if it doesn't exist
mkdir -p logs

# Print job info
echo "════════════════════════════════════════════════════════════════"
echo "🎮 3D Interactive Viewer"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Job started on $(hostname) at $(date)"
echo "Job ID: $SLURM_JOB_ID"
echo ""
echo "IMPORTANT: Set up SSH tunnel to view!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "On your LOCAL computer, run this command:"
echo "ssh -L 6009:$(hostname):6009 chabeck@greatlakes.arc-ts.umich.edu"
echo ""
echo "Then open your browser to: http://localhost:6009"
echo ""
echo "Controls:"
echo "  - Left mouse: Rotate"
echo "  - Right mouse: Pan"  
echo "  - Scroll: Zoom"
echo ""
echo "Press Ctrl+C in this terminal to stop the viewer"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Load modules and activate environment
module load python3.10-anaconda cuda/11.3.0
source ~/.bashrc
conda activate gaussian_grouping

# Change to project directory
cd ~/gaussian-grouping

# Start the viewer - will run until you cancel or time limit
echo "Starting 3D viewer on port 6009..."
echo "Viewer is running! Keep this job alive to interact with the scene."
echo ""

python train.py -s data/bear -m output/bear \
    --start_checkpoint output/bear/point_cloud/iteration_30000/point_cloud.ply \
    --port 6009 \
    --test_iterations -1 \
    --save_iterations -1 \
    --config_file config/gaussian_dataset/train.json \
    --ip 0.0.0.0

echo ""
echo "Viewer stopped at $(date)"
