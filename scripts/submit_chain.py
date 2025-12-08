#!/usr/bin/env python3
"""
Submit a chain of training jobs to overcome the 8-hour time limit.
Usage: python submit_chain.py --name mcity_1B --total_iters 1000000 --iters_per_job 100000
"""

import os
import sys
import argparse
import subprocess
import time

def submit_job(script_path, dependency_id=None):
    """Submit a SLURM job with optional dependency."""
    cmd = ['sbatch']
    if dependency_id:
        cmd.extend([f'--dependency=afterok:{dependency_id}'])
    cmd.append(script_path)
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error submitting job: {result.stderr}")
        sys.exit(1)
        
    # Parse job ID (Output: "Submitted batch job 123456")
    job_id = result.stdout.strip().split()[-1]
    return job_id

def create_slurm_script(job_name, iteration_start, iteration_end, prev_checkpoint, output_dir, script_dir):
    """Create a SLURM script for a specific training segment."""
    
    # Determine start checkpoint argument
    if prev_checkpoint:
        checkpoint_arg = f"--start_checkpoint {prev_checkpoint}"
    else:
        checkpoint_arg = ""
        
    # Determine save iterations (save at end of this job)
    save_iters = f"{iteration_end}"
    
    # Determine checkpoint iterations (save at end of this job)
    checkpoint_iters = f"{iteration_end}"
    
    # Determine test iterations (every 10k or at end)
    test_iters = f"{iteration_end}"

    script_content = f"""#!/bin/bash
#SBATCH --job-name={job_name}_{iteration_end}
#SBATCH --account=entr490s113y25_class
#SBATCH --partition=spgpu
#SBATCH --qos=class
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --gpus-per-node=1
#SBATCH --time=08:00:00
#SBATCH --mail-type=FAIL
#SBATCH --output=logs/{job_name}_{iteration_end}_%j.out
#SBATCH --error=logs/{job_name}_{iteration_end}_%j.err

# Environment setup
cd {os.getcwd()}
source activate_env.sh

echo "========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Segment: {iteration_start} -> {iteration_end}"
echo "Start time: $(date)"
echo "========================================="

# Train Gaussian Grouping
python train.py \\
    -s data/mcity \\
    --model_path {output_dir} \\
    --config_file config/gaussian_dataset/train.json \\
    --iterations {iteration_end} \\
    {checkpoint_arg} \\
    --save_iterations {save_iters} \\
    --checkpoint_iterations {checkpoint_iters} \\
    --test_iterations {test_iters} \\
    --eval

echo ""
echo "========================================="
echo "Segment completed!"
echo "End time: $(date)"
echo "========================================="
"""
    
    script_path = os.path.join(script_dir, f"{job_name}_{iteration_end}.slurm")
    with open(script_path, 'w') as f:
        f.write(script_content)
    
    return script_path

def main():
    parser = argparse.ArgumentParser(description="Submit chained training jobs")
    parser.add_argument("--name", type=str, required=True, help="Job name prefix")
    parser.add_argument("--start_iter", type=int, default=0, help="Start iteration for the chain")
    parser.add_argument("--total_iters", type=int, default=1000000, help="Total iterations to train")
    parser.add_argument("--iters_per_job", type=int, default=100000, help="Iterations per job (approx 8 hours)")
    parser.add_argument("--output_dir", type=str, default=None, help="Output directory")
    parser.add_argument("--dependency", type=str, default=None, help="Job ID to depend on for the first job")
    
    args = parser.parse_args()
    
    if args.output_dir is None:
        args.output_dir = f"output/{args.name}"
        
    # Create directories
    os.makedirs("slurm_jobs/chains", exist_ok=True)
    os.makedirs("logs", exist_ok=True)
    
    current_iter = args.start_iter
    last_job_id = args.dependency
    
    print(f"Preparing chain for {args.name}:")
    print(f"  Start iteration: {current_iter:,}")
    print(f"  Total iterations: {args.total_iters:,}")
    print(f"  Step size: {args.iters_per_job:,}")
    print(f"  Output: {args.output_dir}")
    if last_job_id:
        print(f"  Initial Dependency: {last_job_id}")
    print("-" * 40)
    
    while current_iter < args.total_iters:
        start_iter = current_iter
        end_iter = min(current_iter + args.iters_per_job, args.total_iters)
        
        # Determine checkpoint path from previous job
        if start_iter > 0:
            prev_checkpoint = os.path.join(args.output_dir, f"chkpnt{start_iter}.pth")
        else:
            prev_checkpoint = None
            
        # Create script
        script_path = create_slurm_script(
            args.name, 
            start_iter, 
            end_iter, 
            prev_checkpoint, 
            args.output_dir,
            "slurm_jobs/chains"
        )
        
        # Submit job
        job_id = submit_job(script_path, last_job_id)
        
        if last_job_id:
            print(f"Submitted {os.path.basename(script_path)} (ID: {job_id}) -> Depends on {last_job_id}")
        else:
            print(f"Submitted {os.path.basename(script_path)} (ID: {job_id}) -> First job")
            
        last_job_id = job_id
        current_iter = end_iter
        
    print("-" * 40)
    print("Chain submission complete!")
    print(f"Monitor with: squeue -u {os.environ.get('USER')}")

if __name__ == "__main__":
    main()
