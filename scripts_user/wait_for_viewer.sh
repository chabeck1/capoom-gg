#!/bin/bash
# Wait for viewer job to start and show connection info

JOB_ID="$1"

if [ -z "$JOB_ID" ]; then
    # Find the most recent viewer job
    JOB_ID=$(squeue -u $USER -n gg_viewer -h -o "%A" | head -n 1)
    if [ -z "$JOB_ID" ]; then
        echo "❌ No viewer job found"
        echo "Start one with: sbatch slurm_jobs/viewer_interactive.slurm"
        exit 1
    fi
fi

echo "════════════════════════════════════════════════════════════════"
echo "⏳ Waiting for Viewer Job $JOB_ID to Start..."
echo "════════════════════════════════════════════════════════════════"
echo ""

# Wait for job to start
while true; do
    STATUS=$(squeue -j $JOB_ID -h -o "%T" 2>/dev/null)
    
    if [ -z "$STATUS" ]; then
        echo "❌ Job $JOB_ID not found (may have failed or completed)"
        echo ""
        echo "Check error log: cat logs/viewer_${JOB_ID}.err"
        exit 1
    fi
    
    if [ "$STATUS" = "RUNNING" ]; then
        echo "✅ Job is RUNNING!"
        break
    fi
    
    echo "Status: $STATUS ($(date +%T))"
    sleep 5
done

# Get compute node
COMPUTE_NODE=$(squeue -j $JOB_ID -h -o "%N")

if [[ ! $COMPUTE_NODE == *".arc-ts.umich.edu" ]]; then
    FULL_NODE="${COMPUTE_NODE}.arc-ts.umich.edu"
else
    FULL_NODE="$COMPUTE_NODE"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "🎉 VIEWER IS STARTING!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Job ID: $JOB_ID"
echo "Node:   $COMPUTE_NODE"
echo ""
echo "Waiting for viewer server to initialize (15 seconds)..."
sleep 15

# Check if viewer started
LOG_FILE="logs/viewer_${JOB_ID}.log"
if [ -f "$LOG_FILE" ] && grep -q "Starting 3D viewer" "$LOG_FILE"; then
    echo "✅ Viewer server is running!"
else
    echo "⚠️  Viewer may still be initializing..."
    echo "Check log: tail -f $LOG_FILE"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "📡 SSH TUNNEL COMMAND FOR YOUR MAC"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Open a NEW terminal on your Mac and run:"
echo ""
echo "ssh -L 6009:${FULL_NODE}:6009 ${USER}@greatlakes.arc-ts.umich.edu"
echo ""
echo "Keep that terminal open, then connect your viewer to localhost:6009"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "📺 SIBR VIEWER (on your Mac, after SSH tunnel is up)"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "./install/bin/SIBR_remoteGaussian_app --port 6009"
echo ""
echo "Or for quick view, download the .ply file:"
echo "scp ${USER}@greatlakes.arc-ts.umich.edu:~/gaussian-grouping/output/bear/point_cloud/iteration_30000/point_cloud.ply ~/"
echo ""
echo "════════════════════════════════════════════════════════════════"
