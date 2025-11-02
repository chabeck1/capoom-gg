# Gaussian Grouping Training Guide

## Prerequisites

### 1. Build CUDA Extensions (ONE-TIME SETUP)
Before training, you MUST build the CUDA extensions on a GPU node:

```bash
# Option 1: Submit build job
cd ~/gaussian-grouping
sbatch build_extensions.slurm

# Option 2: Interactive session
salloc --account=lsa1 --partition=spgpu --gres=gpu:1 --time=01:00:00
cd ~/gaussian-grouping
bash build_cuda_extensions.sh
exit
```

Verify installation (on GPU node):
```bash
python -c "import diff_gaussian_rasterization; print('✓ OK')"
python -c "import simple_knn; print('✓ OK')"
```

## Data Preparation

### Option 1: Use Pre-converted Datasets
Download from [Hugging Face](https://huggingface.co/mqye/Gaussian-Grouping/tree/main):

```bash
# Create data directory
mkdir -p ~/gaussian-grouping/data

# Download datasets (examples):
cd ~/gaussian-grouping/data
# Use wget, rsync, or download from Hugging Face
```

Expected structure:
```
data/
├── bear/
├── lerf/
│   └── figurines/
└── mipnerf360/
    └── counter/
```

### Option 2: Prepare Your Own Dataset

1. **Organize images:**
```
your_dataset/
└── input/
    ├── image_001.jpg
    ├── image_002.jpg
    └── ...
```

2. **Convert with COLMAP:**
```bash
python convert.py -s /path/to/your_dataset
```

3. **Generate SAM masks** (requires DEVA environment - optional step):
```bash
bash script/prepare_pseudo_label.sh your_dataset 1
```

## Training Jobs

### Quick Start: Submit Training Job

1. **Copy the example script:**
```bash
cp train_example.slurm my_training.slurm
```

2. **Edit for your dataset:**
```bash
nano my_training.slurm
# Uncomment and modify the training command
```

3. **Submit:**
```bash
sbatch my_training.slurm
```

4. **Monitor:**
```bash
squeue -u $USER
tail -f logs/train_*.log
```

### Training Commands

#### Pre-converted datasets:
```bash
# Bear dataset
bash script/train.sh bear 1

# Figurines dataset
bash script/train_lerf.sh lerf/figurines 1

# Counter dataset
bash script/train.sh mipnerf360/counter 2
```

#### Custom dataset:
```bash
python train.py -s data/your_dataset --port 6009
```

## GPU Partition Selection

Choose based on your needs and budget:

| Partition | Cost/Month | CPUs | Memory | Best For |
|-----------|-----------|------|--------|----------|
| **spgpu** | $78.10 | 4 | 48GB | Most training (recommended) |
| **gpu** | $118.33 | 20 | 90GB | CPU-heavy workloads |
| **gpu_mig40** | $118.33 | 8 | 125GB | High memory needs |

### Adjusting Resources

Edit your SLURM script:

```bash
#SBATCH --partition=spgpu     # Change partition
#SBATCH --gres=gpu:1          # Number of GPUs (1-4)
#SBATCH --cpus-per-task=4     # CPU cores
#SBATCH --mem=32G             # Memory
#SBATCH --time=24:00:00       # Time limit (HH:MM:SS)
```

## Monitoring Training

### Check job status:
```bash
squeue -u $USER
```

### View live logs:
```bash
tail -f logs/train_*.log
```

### Cancel job:
```bash
scancel <job-id>
```

### Check GPU usage (on running node):
```bash
srun --jobid=<job-id> --pty nvidia-smi
```

## Output Files

Training outputs are typically saved to:
```
output/<scene_name>/
├── point_cloud/
│   └── iteration_XXX/
├── cameras/
└── cfg_args
```

## Common Issues

### CUDA extensions not found:
- Make sure you built them on a GPU node first
- Verify: `python -c "import diff_gaussian_rasterization"`

### Out of memory:
- Reduce batch size in training config
- Request more memory: `--mem=48G`
- Use spgpu or gpu_mig40 partition

### Job pending too long:
- Try `spgpu` partition (often faster availability)
- Check availability: `sinfo -p spgpu`

## Cost Estimation

Estimate job cost before running:
```bash
my_job_estimate --cores 4 --memory 32gb --partition spgpu --gpu 1
```

## Example: Complete Workflow

```bash
# 1. Build CUDA extensions (one-time)
cd ~/gaussian-grouping
sbatch build_extensions.slurm

# 2. Prepare data
mkdir -p data
cd data
# Download or prepare your dataset

# 3. Create training script
cd ~/gaussian-grouping
cp train_example.slurm train_bear.slurm
nano train_bear.slurm  # Edit training command

# 4. Submit training
sbatch train_bear.slurm

# 5. Monitor
squeue -u $USER
tail -f logs/train_*.log
```

## Useful Commands

```bash
# Activate environment
source ~/gaussian-grouping/activate_env.sh

# Check environment status
bash ~/gaussian-grouping/check_status.sh

# View all your jobs
squeue -u $USER

# View job details
scontrol show job <job-id>

# View past jobs
sacct -u $USER --format=JobID,JobName,Partition,State,Elapsed

# Estimate costs
my_job_estimate --help
```

## Next Steps After Training

1. **Render results:**
```bash
python render.py -m output/<scene_name>
```

2. **Evaluate metrics:**
```bash
python metrics.py -m output/<scene_name>
```

3. **3D editing** (see `docs/edit_removal_inpaint.md`)

## Getting Help

- Full docs: `~/gaussian-grouping/docs/`
- Quick ref: `~/gaussian-grouping/QUICK_REFERENCE.txt`
- Great Lakes help: https://arc.umich.edu/greatlakes/
- Project repo: https://github.com/lkeab/gaussian-grouping
