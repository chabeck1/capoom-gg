#!/bin/bash
#SBATCH --job-name=build_gdino
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --gres=gpu:1
#SBATCH --time=00:20:00
#SBATCH --output=logs/build_gdino_%j.log

source activate_env.sh

echo "Building GroundingDINO CUDA extensions..."
cd Tracking-Anything-with-DEVA/Grounded-Segment-Anything/GroundingDINO

# Build the custom CUDA ops
python setup.py build_ext --inplace

cd ../../..

echo ""
echo "✅ GroundingDINO CUDA extensions built!"
echo "Now text-based detection should work properly"
