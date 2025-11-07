#!/bin/bash
#SBATCH --job-name=gg_render
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=01:00:00
#SBATCH --output=logs/render_%j.log
#SBATCH --error=logs/render_%j.err

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

# Render with text-prompt based segmentation
echo ""
echo "Rendering text-prompt based masks..."
python render_lerf_mask.py -m output/bear --skip_train

echo ""
echo "Rendering complete!"
echo "Results saved to: output/bear/"
echo "Job completed at $(date)"
