#!/bin/bash
# Setup rclone to sync from Mac to Great Lakes

echo "==================================================================="
echo "RCLONE SETUP: Sync from Mac to Great Lakes"
echo "==================================================================="
echo ""
echo "We'll use SFTP to connect back to your Mac."
echo ""
echo "Prerequisites on your Mac:"
echo "  1. Enable 'Remote Login' in System Settings > General > Sharing"
echo "  2. Note your Mac's IP address or hostname"
echo ""
echo "Starting rclone config..."
echo ""

export PATH="$HOME/.local/bin:$PATH"

rclone config create mac_home sftp \
    host="YOUR_MAC_IP_OR_HOSTNAME" \
    user="chabeck" \
    port=22 \
    key_file="$HOME/.ssh/id_ed25519" \
    shell_type="unix"

echo ""
echo "==================================================================="
echo "Configuration complete!"
echo ""
echo "Now you can sync with:"
echo "  rclone sync mac_home:/Users/chabeck/Downloads/perspective ~/gaussian-grouping/data/mcity/ -P"
echo ""
echo "==================================================================="
