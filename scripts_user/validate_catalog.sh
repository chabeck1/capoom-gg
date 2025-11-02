#!/bin/bash
# Validate catalog extraction results
# Usage: ./scripts_user/validate_catalog.sh <catalog_name>

CATALOG_NAME=${1:-"bear"}
CATALOG_DIR="catalog/$CATALOG_NAME"

echo "=================================================="
echo "Capoom Catalog Validation"
echo "Catalog: $CATALOG_NAME"
echo "=================================================="

if [ ! -d "$CATALOG_DIR" ]; then
    echo "❌ ERROR: Catalog directory not found: $CATALOG_DIR"
    exit 1
fi

echo "✓ Catalog directory exists"

# Check for required files
echo ""
echo "File Check:"
echo "----------"

if [ -f "$CATALOG_DIR/gaussians.pt" ]; then
    SIZE=$(stat -f%z "$CATALOG_DIR/gaussians.pt" 2>/dev/null || stat -c%s "$CATALOG_DIR/gaussians.pt" 2>/dev/null)
    SIZE_MB=$(echo "scale=2; $SIZE / 1048576" | bc)
    echo "✓ gaussians.pt exists (${SIZE_MB} MB)"
else
    echo "❌ gaussians.pt missing"
    exit 1
fi

if [ -f "$CATALOG_DIR/metadata.json" ]; then
    echo "✓ metadata.json exists"
else
    echo "❌ metadata.json missing"
    exit 1
fi

# Validate Gaussian data
echo ""
echo "Gaussian Data Validation:"
echo "------------------------"

python3 << EOF
import torch
import json
import sys

try:
    # Load Gaussians
    data = torch.load('$CATALOG_DIR/gaussians.pt')
    print(f"✓ Successfully loaded Gaussian data")
    print(f"\nKeys in data: {list(data.keys())}")
    
    # Check each component
    required_keys = ['xyz', 'features_dc', 'scaling', 'rotation', 'opacity']
    for key in required_keys:
        if key in data:
            shape = data[key].shape
            print(f"  {key}: {shape}")
        else:
            print(f"  ❌ Missing key: {key}")
            sys.exit(1)
    
    # Count Gaussians
    num_gaussians = data['xyz'].shape[0]
    print(f"\n✓ Total Gaussians: {num_gaussians:,}")
    
    if num_gaussians < 100:
        print(f"⚠ WARNING: Very few Gaussians ({num_gaussians}), extraction may have failed")
    elif num_gaussians > 1000000:
        print(f"⚠ WARNING: Very many Gaussians ({num_gaussians}), may include background")
    else:
        print(f"✓ Gaussian count looks reasonable")
    
    # Load and validate metadata
    with open('$CATALOG_DIR/metadata.json', 'r') as f:
        metadata = json.load(f)
    
    print(f"\nMetadata:")
    print(f"  Name: {metadata.get('name', 'N/A')}")
    print(f"  Object IDs: {metadata.get('object_ids', 'N/A')}")
    print(f"  Source: {metadata.get('source_scene', 'N/A')}")
    print(f"  Centroid: {metadata.get('centroid', 'N/A')}")
    print(f"  Size: {metadata.get('size', 'N/A')}")
    
    # Cross-check
    if metadata.get('num_gaussians') != num_gaussians:
        print(f"⚠ WARNING: Metadata count ({metadata.get('num_gaussians')}) doesn't match actual ({num_gaussians})")
    else:
        print(f"✓ Metadata count matches actual Gaussians")
    
    print(f"\n✅ VALIDATION PASSED")
    sys.exit(0)
    
except Exception as e:
    print(f"\n❌ VALIDATION FAILED: {e}")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "=================================================="
    echo "✅ Catalog '$CATALOG_NAME' is valid and ready to use"
    echo "=================================================="
    echo ""
    echo "Next steps:"
    echo "  1. Test addition to scene:"
    echo "     sbatch slurm_jobs/catalog_add_job.slurm output/bear $CATALOG_NAME 5.0,0.0,1.5"
    echo ""
    echo "  2. View catalog contents:"
    echo "     ls -lh $CATALOG_DIR/"
    echo ""
    echo "  3. Check metadata:"
    echo "     cat $CATALOG_DIR/metadata.json"
else
    echo ""
    echo "=================================================="
    echo "❌ Catalog validation failed"
    echo "=================================================="
    exit 1
fi
