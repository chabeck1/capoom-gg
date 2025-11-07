#!/bin/bash
# Check status of checkpoint chain jobs
# Usage: ./check_chain_status.sh [job_name_prefix]

if [ -z "$1" ]; then
    echo "Usage: $0 <job_name_prefix>"
    echo "Example: $0 gg_3k_chk"
    exit 1
fi

PREFIX=$1

echo "========================================================================"
echo "Checkpoint Chain Status: $PREFIX"
echo "========================================================================"

# Check current jobs in queue
echo ""
echo "🔍 Jobs in Queue:"
squeue -u $USER -o "%.18i %.12j %.8T %.10M %.6D %R" | grep -E "JOBID|${PREFIX}" || echo "  No jobs in queue"

# Check recent completed jobs
echo ""
echo "✅ Recently Completed:"
sacct -u $USER --format=JobID,JobName%30,State,Elapsed,MaxRSS -S $(date -d '7 days ago' +%Y-%m-%d) | grep "${PREFIX}" | grep "COMPLETED" | tail -10

# Check for failed jobs
echo ""
echo "❌ Failed Jobs:"
sacct -u $USER --format=JobID,JobName%30,State,Elapsed -S $(date -d '7 days ago' +%Y-%m-%d) | grep "${PREFIX}" | grep -E "FAILED|TIMEOUT|CANCELLED" | tail -10 || echo "  No failed jobs"

# Check for checkpoints
echo ""
echo "💾 Saved Checkpoints:"
OUTPUT_DIR=$(ls -d output/${PREFIX}* 2>/dev/null | head -1)
if [ -n "$OUTPUT_DIR" ]; then
    ls -lh ${OUTPUT_DIR}/chkpnt*.pth 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    if [ $? -ne 0 ]; then
        echo "  No checkpoints found yet"
    fi
else
    echo "  Output directory not found"
fi

# Check latest log
echo ""
echo "📋 Latest Log (last 20 lines):"
LATEST_LOG=$(ls -t logs/${PREFIX}*.log 2>/dev/null | head -1)
if [ -n "$LATEST_LOG" ]; then
    echo "  File: $LATEST_LOG"
    echo "  ---"
    tail -20 "$LATEST_LOG" | sed 's/^/  /'
else
    echo "  No logs found yet"
fi

echo ""
echo "========================================================================"
