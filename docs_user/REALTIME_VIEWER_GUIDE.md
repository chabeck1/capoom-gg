# Real-Time Scene Editing Guide for Gaussian Grouping

## Quick Start

### 1. Start the Viewer Server on ARC @ GLC

```bash
# Submit the viewer job
sbatch slurm_jobs/viewer_job.slurm

# Check which compute node it's running on
squeue -u chabeck

# Monitor the log to see the exact hostname
tail -f logs/viewer_*.log
```

The log will show something like:
```
Job started on gl3001.arc-ts.umich.edu at ...
ssh -L 6009:gl3001:6009 chabeck@greatlakes.arc-ts.umich.edu
```

### 2. Create SSH Tunnel from Your Mac

Open a terminal on your Mac and run:
```bash
ssh -L 6009:<COMPUTE_NODE>:6009 chabeck@greatlakes.arc-ts.umich.edu
```

Replace `<COMPUTE_NODE>` with the actual node (e.g., `gl3001.arc-ts.umich.edu`).

Keep this terminal window open while using the viewer.

### 3. Connect with a Viewer Client

#### Option A: SIBR Viewer (Recommended for Real-Time Editing)

The official viewer from the Gaussian Splatting paper:

1. **Install on your Mac:**
   ```bash
   # Clone the original Gaussian Splatting repo
   git clone https://github.com/graphdeco-inria/gaussian-splatting --recursive
   cd gaussian-splatting
   
   # Build SIBR viewers (requires CMake, CUDA not needed for viewer only)
   cd SIBR_viewers
   cmake -Bbuild . -DCMAKE_BUILD_TYPE=Release
   cmake --build build -j24 --target install
   ```

2. **Run the remote viewer:**
   ```bash
   ./install/bin/SIBR_remoteGaussian_app --port 6009
   ```

3. **Controls:**
   - Left mouse: Rotate camera
   - Right mouse: Pan camera
   - Scroll wheel: Zoom
   - Press 'T' to start/stop training
   - Press 'R' to reset view

#### Option B: SuperSplat (Web-Based, No Real-Time)

For quick visualization without real-time training:

1. Download the `.ply` file from your scene:
   ```bash
   scp chabeck@greatlakes.arc-ts.umich.edu:~/gaussian-grouping/output/bear/point_cloud/iteration_30000/point_cloud.ply .
   ```

2. Go to https://playcanvas.com/supersplat/editor

3. Upload the `.ply` file

**Note:** This doesn't connect to live training, just for viewing final results.

#### Option C: Web Viewer (Coming Soon)

A custom web-based viewer that can connect to the training server via WebSocket.

## Editing Capabilities

### During Training
When connected via SIBR viewer, you can:
- **View in real-time** as the model trains
- **Control camera** to inspect different angles
- **Toggle training** on/off to pause and inspect
- **Adjust rendering parameters** like scaling modifier

### After Training
For object-level editing, use the command-line tools:

1. **Extract objects:**
   ```bash
   python capoom_street_furniture.py --mode extract \
       --scene output/bear \
       --objects "bear"
   ```

2. **Add objects to scenes:**
   ```bash
   python capoom_street_furniture.py --mode add \
       --scene output/bear \
       --objects bear \
       --position 5.0,0.0,1.5 \
       --rotation 0,45,0 \
       --scale 1.0
   ```

3. **Remove objects:**
   ```bash
   python edit_object_removal.py \
       -m output/bear \
       --iteration 30000 \
       --object_id <id>
   ```

## Customizing the Viewer

### Change the Scene

Edit `slurm_jobs/viewer_job.slurm`:

```bash
python train.py -s data/<YOUR_SCENE> -m output/<YOUR_SCENE> \
    --start_checkpoint output/<YOUR_SCENE>/point_cloud/iteration_30000/point_cloud.ply \
    --port 6009 \
    --ip 0.0.0.0
```

### Change the Port

If port 6009 is busy, use a different port:

```bash
python train.py ... --port 6010 --ip 0.0.0.0
```

Then update your SSH tunnel:
```bash
ssh -L 6010:<COMPUTE_NODE>:6010 chabeck@greatlakes.arc-ts.umich.edu
```

### Extend Time Limit

Edit the SLURM script:
```bash
#SBATCH --time=04:00:00  # 4 hours instead of 1
```

## Troubleshooting

### "Connection refused" on Mac
- Check that the SSH tunnel is active
- Verify the compute node hostname is correct
- Make sure the viewer server started (check logs)

### Viewer server not starting
- Check GPU availability: `squeue -u chabeck`
- Review error log: `cat logs/viewer_*.err`
- Verify conda environment is activated

### Poor performance / lag
- Reduce the number of Gaussians being rendered
- Use a simpler scene for testing
- Check network latency with `ping greatlakes.arc-ts.umich.edu`

### Multiple SSH hops
If you need to jump through multiple servers:
```bash
# On your Mac
ssh -L 6009:localhost:6009 <jump_host>

# Then on jump_host
ssh -L 6009:<compute_node>:6009 chabeck@greatlakes.arc-ts.umich.edu
```

## Advanced: Custom Web Viewer

If you want a browser-based solution that works natively on Mac, I can create:

1. **WebSocket bridge** to convert the TCP socket to WebSocket
2. **Three.js viewer** for rendering Gaussian Splats in browser
3. **Web UI** for scene editing controls

Let me know if you'd like me to implement this!

## Network GUI Protocol

The viewer communicates via a simple JSON protocol:

**Server → Client (Rendered Image)**
```json
{
  "resolution_x": 800,
  "resolution_y": 600,
  "train": true,
  "fov_y": 0.8,
  "fov_x": 1.2,
  "z_near": 0.01,
  "z_far": 100.0,
  "view_matrix": [...],
  "view_projection_matrix": [...],
  "shs_python": false,
  "rot_scale_python": false,
  "keep_alive": true,
  "scaling_modifier": 1.0
}
```

**Client → Server (Camera Control)**
The server renders from the camera position and sends back the image.

## References

- Original Gaussian Splatting Paper: https://repo-sam.inria.fr/fungraph/3d-gaussian-splatting/
- SIBR Viewer Documentation: https://gitlab.inria.fr/sibr/sibr_core
- Gaussian Grouping Paper: https://arxiv.org/abs/2312.00732
