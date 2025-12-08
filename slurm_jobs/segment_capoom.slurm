#!/bin/bash
#SBATCH --job-name=segment_capoom
#SBATCH --output=logs/segment_capoom_%j.log
#SBATCH --error=logs/segment_capoom_%j.err
#SBATCH --time=02:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32GB
#SBATCH --partition=standard

# Load environment
source ~/.bashrc
module load python3.10-anaconda
module load cuda/11.3.0
conda activate gaussian_grouping

# Set paths
INPUT_PLY="$HOME/gaussian-grouping/output/capoom_ply/point_cloud/iteration_100/point_cloud.ply"
OUTPUT_DIR="$HOME/gaussian-grouping/output/capoom_ply/point_cloud/iteration_100"

echo "Starting segmentation on CAPOOM point cloud"
echo "Input: $INPUT_PLY"
echo "Number of CPUs: $SLURM_CPUS_PER_TASK"

# Run color-based segmentation with KMeans (k=8)
echo "Running color KMeans segmentation (k=8)..."
python tools/segment_ply.py \
  --input $INPUT_PLY \
  --mode color_kmeans \
  --n-clusters 8 \
  --output ${OUTPUT_DIR}/segmented_color_k8.ply

# Run color-based segmentation with KMeans (k=12)
echo "Running color KMeans segmentation (k=12)..."
python tools/segment_ply.py \
  --input $INPUT_PLY \
  --mode color_kmeans \
  --n-clusters 12 \
  --output ${OUTPUT_DIR}/segmented_color_k12.ply

# Run spatial DBSCAN clustering
echo "Running DBSCAN spatial segmentation..."
python tools/segment_ply.py \
  --input $INPUT_PLY \
  --mode dbscan \
  --eps 0.5 \
  --min-samples 20 \
  --output ${OUTPUT_DIR}/segmented_spatial_dbscan.ply

echo "Segmentation complete!"
echo "Output files:"
ls -lh ${OUTPUT_DIR}/segmented_*.ply
