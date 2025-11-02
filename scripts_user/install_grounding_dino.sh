#!/bin/bash
#
# Install GroundingDINO for text-based object queries
# This enables render_lerf_mask.py to work with text prompts
#

set -e

echo "Installing GroundingDINO..."

# Navigate to the DEVA directory (already exists)
cd Tracking-Anything-with-DEVA

# Clone Grounded-Segment-Anything if not already there
if [ ! -d "Grounded-Segment-Anything" ]; then
    echo "Cloning Grounded-Segment-Anything..."
    git clone https://github.com/hkchengrex/Grounded-Segment-Anything.git
else
    echo "Grounded-Segment-Anything already exists"
fi

cd Grounded-Segment-Anything

# Set environment variables
export AM_I_DOCKER=False
export BUILD_WITH_CUDA=True

# Install segment_anything (SAM)
echo "Installing Segment Anything Model..."
python -m pip install -e segment_anything

# Install GroundingDINO
echo "Installing GroundingDINO..."
python -m pip install -e GroundingDINO

cd ../..

echo ""
echo "✅ GroundingDINO installation complete!"
echo ""
echo "You can now use text-based object queries:"
echo "  python render_lerf_mask.py -s data/bear -m output/bear --text 'bear'"
