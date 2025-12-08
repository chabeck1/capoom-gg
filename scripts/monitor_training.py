#!/usr/bin/env python3
"""
Monitor training progress, camera loading, and memory usage.
Usage: python monitor_training.py <job_id>
"""

import sys
import time
import subprocess
import re
from datetime import datetime

def get_gpu_memory():
    """Get GPU memory usage via nvidia-smi."""
    try:
        result = subprocess.run(
            ['nvidia-smi', '--query-gpu=memory.used,memory.total', '--format=csv,noheader,nounits'],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0:
            used, total = result.stdout.strip().split(',')
            return int(used), int(total)
    except:
        pass
    return None, None

def parse_log_file(log_path):
    """Parse training log for iteration info."""
    try:
        with open(log_path, 'r') as f:
            lines = f.readlines()
            
        info = {
            'iterations': [],
            'psnr': [],
            'loss': [],
            'timestamps': []
        }
        
        for line in lines:
            # Look for iteration info
            # Example: [ITER 1000] Saving Gaussians [07/11 00:35:12]
            iter_match = re.search(r'\[ITER (\d+)\].*\[(\d{2}/\d{2} \d{2}:\d{2}:\d{2})\]', line)
            if iter_match:
                info['iterations'].append(int(iter_match.group(1)))
                info['timestamps'].append(iter_match.group(2))
            
            # Look for PSNR
            # Example: Evaluating train: L1 0.0234 PSNR 23.45 [07/11 00:35:12]
            psnr_match = re.search(r'PSNR\s+([\d.]+)', line)
            if psnr_match:
                info['psnr'].append(float(psnr_match.group(1)))
        
        return info
    except:
        return None

def parse_err_file(err_path):
    """Parse stderr for current progress."""
    try:
        # Read last 50 lines for recent progress
        result = subprocess.run(['tail', '-50', err_path], capture_output=True, text=True)
        lines = result.stdout.strip().split('\n')
        
        for line in reversed(lines):
            # Look for progress bar
            # Training progress:   5%|▌         | 5234/100000 [15:23<4:45:32,  5.53it/s, Loss=0.8234]
            match = re.search(r'(\d+)%.*?\|\s*(\d+)/(\d+)\s*\[([^\]]+)\<([^\]]+),\s*([\d.]+)it/s.*?Loss=([\d.]+)', line)
            if match:
                return {
                    'percent': int(match.group(1)),
                    'current': int(match.group(2)),
                    'total': int(match.group(3)),
                    'elapsed': match.group(4),
                    'remaining': match.group(5),
                    'speed': float(match.group(6)),
                    'loss': float(match.group(7))
                }
        return None
    except:
        return None

def monitor_training(job_id):
    """Monitor training job."""
    log_path = f'/home/chabeck/gaussian-grouping/logs/train_mcity_100k_{job_id}.log'
    err_path = f'/home/chabeck/gaussian-grouping/logs/train_mcity_100k_{job_id}.err'
    
    print("=" * 80)
    print(f"MONITORING JOB {job_id}")
    print("=" * 80)
    print(f"Log: {log_path}")
    print(f"Err: {err_path}")
    print("=" * 80)
    print()
    
    last_iter = 0
    update_count = 0
    
    while True:
        update_count += 1
        current_time = datetime.now().strftime("%H:%M:%S")
        
        # Get current progress from stderr
        progress = parse_err_file(err_path)
        
        # Get GPU memory
        mem_used, mem_total = get_gpu_memory()
        
        # Parse log file for saved iterations
        log_info = parse_log_file(log_path)
        
        # Display header every 20 updates
        if update_count % 20 == 1:
            print(f"\n{'Time':<10} {'Iter':<10} {'Progress':<10} {'Speed':<12} {'Loss':<10} {'GPU Mem':<15} {'PSNR':<10}")
            print("-" * 95)
        
        # Build status line
        if progress:
            iter_str = f"{progress['current']:,}/{progress['total']:,}"
            progress_str = f"{progress['percent']:>3}%"
            speed_str = f"{progress['speed']:.2f} it/s"
            loss_str = f"{progress['loss']:.4f}"
            
            if mem_used and mem_total:
                mem_str = f"{mem_used:>5} / {mem_total:>5} MB"
                mem_pct = (mem_used / mem_total) * 100
                if mem_pct > 90:
                    mem_str += " ⚠️"
            else:
                mem_str = "N/A"
            
            # Get latest PSNR
            psnr_str = ""
            if log_info and log_info['psnr']:
                psnr_str = f"{log_info['psnr'][-1]:.2f}"
            
            print(f"{current_time:<10} {iter_str:<10} {progress_str:<10} {speed_str:<12} {loss_str:<10} {mem_str:<15} {psnr_str:<10}", flush=True)
            
            last_iter = progress['current']
        else:
            # No progress info - job may be starting or finished
            status_str = "Waiting for progress..."
            if mem_used:
                mem_str = f"{mem_used:>5} / {mem_total:>5} MB"
            else:
                mem_str = "N/A"
            print(f"{current_time:<10} {'N/A':<10} {'N/A':<10} {'N/A':<12} {'N/A':<10} {mem_str:<15} {'N/A':<10}", flush=True)
        
        # Check if job is still running
        result = subprocess.run(['squeue', '-u', 'chabeck', '-j', str(job_id)], 
                              capture_output=True, text=True)
        if str(job_id) not in result.stdout:
            print("\n" + "=" * 80)
            print("JOB COMPLETED OR NO LONGER IN QUEUE")
            print("=" * 80)
            
            # Show final stats
            if log_info and log_info['iterations']:
                print(f"\nFinal iteration: {log_info['iterations'][-1]:,}")
                if log_info['psnr']:
                    print(f"Final PSNR: {log_info['psnr'][-1]:.2f}")
            break
        
        # Wait before next update
        time.sleep(10)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python monitor_training.py <job_id>")
        print("Example: python monitor_training.py 35492853")
        sys.exit(1)
    
    job_id = sys.argv[1]
    
    try:
        monitor_training(job_id)
    except KeyboardInterrupt:
        print("\n\nMonitoring stopped by user.")
    except Exception as e:
        print(f"\nError: {e}")
