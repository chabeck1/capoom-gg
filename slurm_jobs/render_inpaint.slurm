#!/bin/bash
#SBATCH --job-name=gg_render_inpaint
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --nodes=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --time=01:00:00
#SBATCH --output=logs/render_inpaint_%j.log
#SBATCH --error=logs/render_inpaint_%j.err

# Create log directory if it doesn't exist
mkdir -p logs

# Print job info
echo "Job started on $(hostname) at $(date)"
echo "Job ID: $SLURM_JOB_ID"
echo "GPU info:"
nvidia-smi

# Load modules and activate environment
module load python3.10-anaconda cuda/11.3.0
source ~/.bashrc
conda activate gaussian_grouping

# Verify environment
echo ""
echo "Python: $(which python)"
echo "PyTorch: $(python -c 'import torch; print(torch.__version__)')"
echo "CUDA available: $(python -c 'import torch; print(torch.cuda.is_available())')"

# Change to project directory
cd ~/gaussian-grouping

# The inpainting training already completed, but rendering failed due to OOM
# This job just re-renders with more memory allocated

echo ""
echo "Rendering inpainted scene with more memory..."
echo "The model was already trained - this just creates the renders"
echo ""

# Re-run just the inpainting (which will skip training since it's done)
bash script/edit_object_inpaint.sh output/bear config/object_inpaint/bear.json

echo ""
echo "Rendering complete!"
echo "Results saved to: output/bear/train/ours_object_inpaint/"
echo "Job completed at $(date)"
