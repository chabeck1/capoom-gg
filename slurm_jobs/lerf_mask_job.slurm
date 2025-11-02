#!/bin/bash
#SBATCH --job-name=lerf_mask
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --gres=gpu:1
#SBATCH --time=00:30:00
#SBATCH --output=logs/lerf_mask_%j.log

# Load conda
source activate_env.sh

echo "Running text-based object detection with GroundingDINO + SAM..."
echo "This will identify which object IDs correspond to text queries"
echo ""

# Run LERF mask rendering with custom text prompts
# You can specify any objects you think might be in the scene
python render_lerf_mask.py -s data/bear -m output/bear --text "bear;rocks;ground;grass;trees;water;sky"

echo ""
echo "✅ Text-based object detection complete!"
echo "Results saved to: output/bear/train/ours_30000_text/"
echo "Check the visualizations to see which object IDs match each text prompt"
