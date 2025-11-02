#!/bin/bash
# Quick test script for catalog pipeline monitoring
# Usage: ./scripts_user/monitor_catalog_test.sh [job_id]

JOB_ID=${1:-$(squeue -u $USER -n test_catalog -h -o "%i" | head -1)}

if [ -z "$JOB_ID" ]; then
    echo "No test_catalog job found. Provide job ID manually:"
    echo "Usage: ./scripts_user/monitor_catalog_test.sh <job_id>"
    exit 1
fi

echo "=================================================="
echo "Monitoring Catalog Test Job: $JOB_ID"
echo "=================================================="

# Check job status
echo ""
echo "Job Status:"
squeue -j "$JOB_ID" --format="%.18i %.9P %.30j %.8T %.10M %.6D %R" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "Job $JOB_ID not in queue (completed or failed)"
    echo ""
    echo "Recent job history:"
    sacct -j "$JOB_ID" --format=JobID,JobName,State,ExitCode,Elapsed,MaxRSS
fi

# Show log file
LOG_FILE="logs/test_catalog_${JOB_ID}.out"
ERR_FILE="logs/test_catalog_${JOB_ID}.err"

if [ -f "$LOG_FILE" ]; then
    echo ""
    echo "=================================================="
    echo "Output Log (last 50 lines):"
    echo "=================================================="
    tail -50 "$LOG_FILE"
else
    echo ""
    echo "Log file not yet created: $LOG_FILE"
fi

if [ -f "$ERR_FILE" ] && [ -s "$ERR_FILE" ]; then
    echo ""
    echo "=================================================="
    echo "Error Log:"
    echo "=================================================="
    tail -50 "$ERR_FILE"
fi

# Check for catalog creation
echo ""
echo "=================================================="
echo "Catalog Status:"
echo "=================================================="
if [ -d "catalog/bear" ]; then
    echo "✓ Bear catalog exists"
    ls -lh catalog/bear/
    
    if [ -f "catalog/bear/metadata.json" ]; then
        echo ""
        echo "Metadata:"
        cat catalog/bear/metadata.json
    fi
else
    echo "⚠ Bear catalog not yet created"
fi

# Check detection results
echo ""
echo "=================================================="
echo "Detection Results:"
echo "=================================================="
OBJ_IDS="output/bear/train/ours_30000_text/object_ids---bear.json"
if [ -f "$OBJ_IDS" ]; then
    echo "✓ Detection file exists"
    cat "$OBJ_IDS"
else
    echo "⚠ Detection not yet complete"
fi

# Check removal results
echo ""
echo "=================================================="
echo "Removal Results:"
echo "=================================================="
REMOVAL_DIR="output/bear/train/ours_object_removal/iteration_30000/renders"
if [ -d "$REMOVAL_DIR" ]; then
    NUM_RENDERS=$(ls "$REMOVAL_DIR"/*.png 2>/dev/null | wc -l)
    echo "✓ Removal complete: $NUM_RENDERS images rendered"
else
    echo "⚠ Removal not yet complete"
fi

echo ""
echo "=================================================="
echo "To watch log in real-time:"
echo "  tail -f $LOG_FILE"
echo "=================================================="
