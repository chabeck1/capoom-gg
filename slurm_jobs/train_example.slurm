#!/bin/bash
#SBATCH --job-name=gg_train
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --nodes=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=08:00:00
#SBATCH --output=logs/train_%j.log
#SBATCH --error=logs/train_%j.err

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

# Training command - CUSTOMIZE THIS FOR YOUR DATASET
# Example for bear dataset:
# bash script/train.sh bear 1

# Example for custom dataset:
# DATASET_PATH="data/your_dataset"
# python train.py -s $DATASET_PATH --port 6009

# Add your training command here:
echo ""
echo "Starting training on bear dataset..."
bash script/train.sh bear 1

echo ""
echo "Job completed at $(date)"
