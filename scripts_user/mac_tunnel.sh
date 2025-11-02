#!/bin/bash
# Mac-side SSH Tunnel Setup for Gaussian Grouping Viewer
# Save this file on your Mac and run it

set -e

echo "════════════════════════════════════════════════════════════════"
echo "🚇 Gaussian Grouping Viewer - Mac SSH Tunnel"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Configuration
REMOTE_USER="chabeck"
REMOTE_HOST="greatlakes.arc-ts.umich.edu"
LOCAL_PORT="6009"
REMOTE_PORT="6009"

# Check if compute node was provided as argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <compute_node>"
    echo ""
    echo "Example:"
    echo "  $0 gl3001.arc-ts.umich.edu"
    echo ""
    echo "To find the compute node:"
    echo "  1. SSH to Great Lakes"
    echo "  2. Run: ./scripts_user/setup_viewer_tunnel.sh"
    echo "  3. Copy the compute node name from the output"
    echo ""
    exit 1
fi

COMPUTE_NODE="$1"

echo "📡 Setting up SSH tunnel..."
echo "   Local port: $LOCAL_PORT"
echo "   Remote node: $COMPUTE_NODE"
echo "   Remote port: $REMOTE_PORT"
echo ""

# Check if port is already in use
if lsof -Pi :$LOCAL_PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo "⚠️  Port $LOCAL_PORT is already in use on your Mac."
    echo ""
    echo "Options:"
    echo "  1. Kill the existing process: kill \$(lsof -t -i:$LOCAL_PORT)"
    echo "  2. Use a different port: edit this script"
    echo ""
    exit 1
fi

echo "✅ Port $LOCAL_PORT is available"
echo ""
echo "🔗 Establishing tunnel..."
echo "   (You may be prompted for your Great Lakes password)"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "Once connected, the tunnel will remain open until you press Ctrl+C"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Create the tunnel
ssh -L ${LOCAL_PORT}:${COMPUTE_NODE}:${REMOTE_PORT} ${REMOTE_USER}@${REMOTE_HOST} \
    -N -o ServerAliveInterval=60 -o ServerAliveCountMax=3

echo ""
echo "Tunnel closed."
