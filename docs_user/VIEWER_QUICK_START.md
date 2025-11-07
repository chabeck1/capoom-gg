# 🎮 Quick Start: Real-Time Viewer

## Step 1: Start the Viewer Server

```bash
# On Great Lakes
sbatch slurm_jobs/viewer_job.slurm
```

Check which node it's running on:
```bash
squeue -u chabeck
tail -f logs/viewer_*.log
```

You'll see output like:
```
📡 To connect from your Mac, run this command:

   ssh -L 6009:gl3001.arc-ts.umich.edu:6009 chabeck@greatlakes.arc-ts.umich.edu
```

## Step 2: Create SSH Tunnel (on your Mac)

Copy the exact command from the log and run it in a Mac terminal:

```bash
ssh -L 6009:gl3001.arc-ts.umich.edu:6009 chabeck@greatlakes.arc-ts.umich.edu
```

**Keep this terminal open!**

## Step 3: Connect with SIBR Viewer

### Option A: Install SIBR Viewer (Recommended)

```bash
# On your Mac - one time setup
git clone https://github.com/graphdeco-inria/gaussian-splatting --recursive
cd gaussian-splatting/SIBR_viewers
cmake -Bbuild . -DCMAKE_BUILD_TYPE=Release
cmake --build build -j8 --target install
```

Then run:
```bash
cd gaussian-splatting/SIBR_viewers
./install/bin/SIBR_remoteGaussian_app --port 6009
```

### Option B: Use Web Viewer (Simple but Limited)

Open `web_viewer.html` in your browser - but note this is just a placeholder.
For full functionality, use SIBR viewer.

## Controls (SIBR Viewer)

- **Left mouse drag**: Rotate camera
- **Right mouse drag**: Pan camera  
- **Mouse wheel**: Zoom
- **T key**: Toggle training on/off
- **R key**: Reset camera view
- **ESC**: Disconnect

## To View a Different Scene

```bash
# Edit the scene name when submitting
sbatch slurm_jobs/viewer_job.slurm mcity_sync_12498
```

Or edit `slurm_jobs/viewer_job.slurm` to change the default scene.

## Troubleshooting

**"Connection refused"**
- Make sure SSH tunnel is still running
- Check the viewer server is running: `squeue -u chabeck`
- Verify correct hostname in SSH command

**"Checkpoint not found"**
- Train the scene first before viewing
- Or specify a different scene that's already trained

**Viewer is laggy**
- Your Mac's GPU is rendering, not Great Lakes
- Close other applications
- Try a smaller scene first (e.g., mcity_sync_1002)

## Current Trained Scenes

- ✅ `mcity_sync_1002` - 1,002 images (ready to view)
- ⏳ `mcity_sync_12498` - training now
- ✅ `mcity_sync_300_lowmem` - 300 images
- ✅ `mcity_sync_600` - 600 images

---

**Full Guide**: See `REALTIME_VIEWER_GUIDE.md` for detailed documentation.
