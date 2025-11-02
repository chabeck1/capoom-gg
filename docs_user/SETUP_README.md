# Gaussian Grouping Setup on Great Lakes (UMich)

## Environment Setup Complete ✓

The conda environment `gaussian_grouping` has been created with:
- Python 3.8
- PyTorch 1.12.1 with CUDA 11.3 support
- All Python dependencies (numpy, scipy, opencv, wandb, lpips, etc.)

## ⚠️ Important: CUDA Extensions Need GPU Node

The CUDA extensions (`diff-gaussian-rasterization` and `simple-knn`) **cannot** be built on login nodes. They need to be compiled on a GPU node.

### Option 1: Submit SLURM Job to Build Extensions (Recommended)

1. Edit `build_extensions.slurm` and replace `YOUR_ACCOUNT` with your Great Lakes account
2. Submit the job:
   ```bash
   sbatch build_extensions.slurm
   ```
3. Monitor the job:
   ```bash
   squeue -u $USER
   ```
4. Check the output log when complete:
   ```bash
   cat build_extensions_*.log
   ```

### Option 2: Interactive GPU Session

1. Request an interactive GPU node:
   ```bash
   salloc --account=YOUR_ACCOUNT --partition=gpu --nodes=1 --gres=gpu:1 --time=01:00:00 --mem=16G
   ```

2. Once on the GPU node, run:
   ```bash
   cd ~/gaussian-grouping
   bash build_cuda_extensions.sh
   ```

3. Exit the interactive session when done:
   ```bash
   exit
   ```

## Using the Environment

### Quick activation:
```bash
source ~/gaussian-grouping/activate_env.sh
```

### Manual activation:
```bash
source ~/.bashrc
module load python3.10-anaconda cuda/11.3.0
conda activate gaussian_grouping
```

## Verifying Installation

After building CUDA extensions on a GPU node, verify:

```bash
# On a GPU node
python -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}')"
python -c "import diff_gaussian_rasterization; print('diff_gaussian_rasterization OK')"
python -c "import simple_knn; print('simple_knn OK')"
```

## Running Training/Inference

Always run on GPU nodes via SLURM:

```bash
#!/bin/bash
#SBATCH --job-name=gaussian_grouping
#SBATCH --account=YOUR_ACCOUNT
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --time=24:00:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=8

source ~/.bashrc
module load python3.10-anaconda cuda/11.3.0
conda activate gaussian_grouping

cd ~/gaussian-grouping
# Your training command here
python train.py --your-args
```

## Available GPU Partitions on Great Lakes

- `gpu` - Standard GPU partition
- `gpu_preempt` - Preemptible, cheaper
- Check available GPUs: `sinfo -p gpu -o "%20N %10c %10m %25f %10G"`

## Troubleshooting

### If CUDA extensions fail to build:
- Make sure you're on a GPU node (check with `nvidia-smi`)
- Verify CUDA module is loaded: `echo $CUDA_HOME`
- Check GPU architecture matches (V100, A100, etc.)

### If PyTorch doesn't see CUDA:
- This is normal on login nodes
- Always run actual training/inference on GPU nodes via SLURM

## Files Created

- `activate_env.sh` - Quick environment activation
- `build_cuda_extensions.sh` - Build extensions on GPU node
- `build_extensions.slurm` - SLURM job to build extensions
- `setup_env.sh` - Initial environment setup (already run)
- `fix_setup.sh` - PyTorch fix script (already run)
- `complete_setup.sh` - Complete setup script (already run)

## Next Steps

1. Build CUDA extensions (see options above)
2. Prepare your dataset
3. Create SLURM job scripts for training
4. Submit jobs and monitor progress

## Reference

- Original repo: https://github.com/lkeab/gaussian-grouping
- Great Lakes docs: https://arc.umich.edu/greatlakes/
