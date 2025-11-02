#!/bin/bash
# Setup SSH Tunnel for Real-Time Gaussian Grouping Viewer
# Run this script on the ARC @ GLC login node

set -e

echo "════════════════════════════════════════════════════════════════"
echo "🚇 SSH Tunnel Setup for Real-Time Viewer"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Check if a viewer job is running
VIEWER_JOBS=$(squeue -u $USER -n gg_viewer -h)

if [ -z "$VIEWER_JOBS" ]; then
    echo "❌ No viewer job is currently running."
    echo ""
    echo "Start a viewer job first:"
    echo "  sbatch slurm_jobs/viewer_job.slurm"
    echo ""
    exit 1
fi

# Get the compute node
COMPUTE_NODE=$(squeue -u $USER -n gg_viewer -h -o "%N" | head -n 1)
JOB_ID=$(squeue -u $USER -n gg_viewer -h -o "%A" | head -n 1)

if [ -z "$COMPUTE_NODE" ]; then
    echo "❌ Could not determine compute node."
    exit 1
fi

echo "✅ Viewer job found!"
echo "   Job ID: $JOB_ID"
echo "   Node: $COMPUTE_NODE"
echo ""

# Check if the viewer server has started
LOG_FILE="logs/viewer_${JOB_ID}.log"
if [ -f "$LOG_FILE" ]; then
    echo "📋 Checking viewer status..."
    if grep -q "Starting 3D viewer" "$LOG_FILE"; then
        echo "✅ Viewer server is starting/started"
    else
        echo "⚠️  Viewer may not have started yet. Check the log:"
        echo "   tail -f $LOG_FILE"
    fi
    echo ""
fi

# Add .arc-ts.umich.edu suffix if not present
if [[ ! $COMPUTE_NODE == *".arc-ts.umich.edu" ]]; then
    FULL_NODE="${COMPUTE_NODE}.arc-ts.umich.edu"
else
    FULL_NODE="$COMPUTE_NODE"
fi

echo "════════════════════════════════════════════════════════════════"
echo "📡 SSH Tunnel Command for Your Mac"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Copy and run this command on your LOCAL Mac terminal:"
echo ""
echo "ssh -L 6009:${FULL_NODE}:6009 ${USER}@greatlakes.arc-ts.umich.edu"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "After setting up the tunnel:"
echo ""
echo "Option A - SIBR Viewer (for real-time editing):"
echo "  1. Build SIBR viewer from gaussian-splatting repo"
echo "  2. Run: ./install/bin/SIBR_remoteGaussian_app --port 6009"
echo ""
echo "Option B - Custom connection:"
echo "  Connect your client to localhost:6009"
echo ""
echo "Option C - Web browser (if web viewer is set up):"
echo "  Open: http://localhost:6009"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "To monitor the viewer server:"
echo "  tail -f $LOG_FILE"
echo ""
echo "To stop the viewer:"
echo "  scancel $JOB_ID"
echo ""
