#!/bin/bash
# Quick helper to get the SSH tunnel command for the viewer

echo "🔍 Checking for running viewer jobs..."
echo ""

# Get viewer job info
VIEWER_JOB=$(squeue -u chabeck -n gg_viewer -h -o "%i %t %R")

if [ -z "$VIEWER_JOB" ]; then
    echo "❌ No viewer job found!"
    echo ""
    echo "To start the viewer:"
    echo "   sbatch slurm_jobs/viewer_job.slurm"
    exit 1
fi

JOB_ID=$(echo $VIEWER_JOB | awk '{print $1}')
STATE=$(echo $VIEWER_JOB | awk '{print $2}')
NODE=$(echo $VIEWER_JOB | awk '{print $3}')

echo "Viewer Job: $JOB_ID"
echo "State: $STATE"

if [ "$STATE" = "R" ]; then
    # Running - get the full hostname from the log
    LOG_FILE="logs/viewer_${JOB_ID}.log"
    
    if [ -f "$LOG_FILE" ]; then
        echo ""
        echo "✅ Viewer is RUNNING!"
        echo ""
        echo "=================================================="
        grep "ssh -L" $LOG_FILE | tail -1
        echo "=================================================="
        echo ""
        echo "Copy the command above and run it on your Mac."
        echo "Then connect with: ./SIBR_remoteGaussian_app --port 6009"
    else
        # Fallback if log not available yet
        NODE_FULL="${NODE}.arc-ts.umich.edu"
        echo ""
        echo "✅ Viewer is RUNNING on $NODE"
        echo ""
        echo "Run this on your Mac:"
        echo "   ssh -L 6009:${NODE_FULL}:6009 chabeck@greatlakes.arc-ts.umich.edu"
    fi
elif [ "$STATE" = "PD" ]; then
    echo "⏳ Viewer is PENDING (waiting for resources)"
    echo ""
    echo "Check status: squeue -u chabeck"
else
    echo "State: $STATE"
fi

echo ""
echo "To monitor: tail -f logs/viewer_${JOB_ID}.log"
