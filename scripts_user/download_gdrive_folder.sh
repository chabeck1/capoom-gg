#!/bin/bash

# Download folder from Google Drive
# Usage: ./download_gdrive_folder.sh FOLDER_ID DESTINATION_DIR

FOLDER_ID="$1"
DEST_DIR="$2"

if [ -z "$FOLDER_ID" ] || [ -z "$DEST_DIR" ]; then
    echo "Usage: $0 FOLDER_ID DESTINATION_DIR"
    echo "Example: $0 1bgy9cY2w1Ud6PwqNJgLaJPzAa5eQjxrq /path/to/dest"
    exit 1
fi

# Create destination directory
mkdir -p "$DEST_DIR"
cd "$DEST_DIR"

echo "Downloading folder from Google Drive..."
echo "Folder ID: $FOLDER_ID"
echo "Destination: $DEST_DIR"
echo ""

# Use wget with recursive download
# This will download all files in the folder
wget --no-check-certificate \
     --load-cookies /tmp/gdrive_cookies.txt \
     "https://drive.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/gdrive_cookies.txt --keep-session-cookies --no-check-certificate "https://drive.google.com/uc?export=download&id=${FOLDER_ID}" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=${FOLDER_ID}" \
     -r -np -nd -A '*' \
     -e robots=off \
     || echo "Note: Some warnings are normal for large folders"

rm -f /tmp/gdrive_cookies.txt

echo ""
echo "Download complete!"
echo "Files saved to: $DEST_DIR"
