#!/bin/bash
#SBATCH --job-name=inspect_grouping
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --gpus-per-node=1
#SBATCH --time=00:20:00
#SBATCH --output=logs/inspect_grouping_%j.out
#SBATCH --error=logs/inspect_grouping_%j.err

cd /home/chabeck/gaussian-grouping
source activate_env.sh

echo "========================================="
echo "Inspecting High-Res Model"
echo "========================================="
python inspect_grouping_results.py --model_path output/mcity_grouping_highres

echo ""
echo "========================================="
echo "Inspecting Half-Res Model"
echo "========================================="
python inspect_grouping_results.py --model_path output/mcity_grouping_only
