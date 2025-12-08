#!/bin/bash
# Check GPU memory usage on compute node
# Usage: ssh gl1527 'bash -s' < check_gpu_mem.sh

echo "=========================================="
echo "GPU Memory Usage - $(date)"
echo "=========================================="
echo ""

nvidia-smi --query-gpu=index,name,memory.used,memory.total,utilization.gpu --format=csv,noheader

echo ""
echo "=========================================="
echo "Detailed Memory Breakdown"
echo "=========================================="

nvidia-smi

echo ""
echo "=========================================="
echo "Process Using GPU"
echo "=========================================="

nvidia-smi pmon -c 1 2>/dev/null || nvidia-smi pmon -s m -c 1 2>/dev/null

echo ""
echo "Memory growth check:"
echo "If memory stays ~15-20 GB throughout training → SUCCESS (constant memory)"
echo "If memory keeps increasing → PROBLEM (memory leak)"
