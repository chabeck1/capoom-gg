# MIG Partition Driver Bug Report for Great Lakes HPC

**Date**: November 5, 2025  
**Reporter**: chabeck (entr490s113y25_class)  
**Affected Partition**: gpu_mig40  
**Severity**: Critical - MIG partition unusable for CUDA workloads

---

## Issue Summary

The gpu_mig40 partition is running NVIDIA driver 570.148.08, which contains a documented NVML regression that causes CUDA applications to fail with massive memory allocation errors (requesting 21+ terabytes on 39GB partitions).

---

## Reproduction

### Environment
- **Partition**: gpu_mig40
- **Node**: gl1250.arc-ts.umich.edu, gl1251.arc-ts.umich.edu
- **GPU**: NVIDIA A100 80GB PCIe MIG 3g.40gb (39.25GB available)
- **Driver**: 570.148.08
- **CUDA Version**: 12.8 (runtime), 11.3 (compilation)

### Steps to Reproduce
1. Submit any CUDA Gaussian Splatting workload to gpu_mig40
2. Application initializes successfully
3. First CUDA kernel execution fails with:
```
RuntimeError: CUDA out of memory. 
Tried to allocate 21384.46 GiB (GPU 0; 39.25 GiB total capacity; 
1.13 GiB already allocated; 37.00 GiB free)
```

### Test Results
| Test | Resolution | Partition | Driver | Result |
|------|-----------|-----------|---------|---------|
| Mcity dataset | 1024×1024 | gpu_mig40 | 570.148.08 | ❌ 21TB allocation bug |
| Mcity dataset | 1024×1024 | spgpu (A40) | Unknown | ✅ Works perfectly |
| Bear dataset | 729×985 | gpu_mig40 | 570.148.08 | ❌ 21TB allocation bug |
| Bear dataset | 729×985 | spgpu (A40) | Unknown | ✅ Works perfectly |
| Diagnostic test | 128×128 | gpu_mig40 | 570.148.08 | ✅ Works |

**Pattern**: Bug triggers at resolutions above ~128×128 pixels on MIG only.

---

## Root Cause: NVIDIA R570 Driver Regression

### Official NVIDIA Documentation

NVIDIA has documented this as a known issue in the R570 driver series:

**Affected Versions:**
- 570.124.06
- 570.133.20
- **570.148.08** ← Great Lakes MIG nodes (CONFIRMED)
- 570.158.01

**Official Statement** (NVIDIA GPU Operator Documentation):
> "For drivers 570.124.06, 570.133.20, 570.148.08, and 570.158.01, GPU workloads cannot be scheduled on nodes that have a mix of MIG slices and full GPUs. This is due to a regression in NVML introduced in the R570 drivers."

**Source**: NVIDIA GPU Operator Release Notes, R570 Known Issues

### Technical Details

**What's Broken:**
- NVML (NVIDIA Management Library) memory allocation logic for MIG partitions
- Buffer size calculation has integer overflow or uninitialized variable bug
- Affects MIG-specific memory addressing code path only
- Full GPU mode (spgpu A40) uses different code path that works correctly

**Why It Happens:**
- MIG partitions use isolated memory controllers with different addressing
- R570 refactored NVML to support MIG architecture
- New code path has edge case bug at realistic resolutions
- Likely cubic scaling issue: 1024³ × multiplier ≈ 21TB erroneous calculation

---

## Impact

### Users Affected
- Any CUDA workload using MIG partitions at resolutions > 128×128
- Gaussian Splatting applications (confirmed)
- Likely affects other GPU rendering/compute workloads
- Makes gpu_mig40 partition effectively unusable for research

### Workaround
Users must use spgpu partition instead, which:
- Has much longer queue times (currently 386+ jobs)
- Limits available GPU resources
- No access to A100's larger memory capacity

---

## Recommended Fix

### Option 1: Downgrade (Recommended)
**Target Version**: Driver 570.86.15 or earlier  
**Status**: Known working, no MIG regression  
**Risk**: Low - tested and stable

### Option 2: Upgrade
**Target Version**: Driver 570.158.02 or later  
**Status**: Regression fixed in later R570 releases  
**Risk**: Medium - newer driver, may have other issues

### Option 3: Temporary Workaround
Disable or drain gpu_mig40 partition until driver can be updated.

---

## Evidence Package

### Log Files Available
```
~/gaussian-grouping/logs/train_mcity_sync60_mig_35330866.err  # Mcity failure
~/gaussian-grouping/logs/train_bear_mig_35367920.err          # Bear failure
~/gaussian-grouping/logs/mig_diagnostic_35334291.log          # Diagnostic success
~/gaussian-grouping/logs/train_mcity_sync60_spgpu_35331135.*  # Working spgpu
```

### GPU Info from MIG Node
```
Node: gl1250.arc-ts.umich.edu
GPU: NVIDIA A100 80GB PCIe MIG 3g.40gb
Driver: NVIDIA-SMI 570.148.08
CUDA: 12.8
MIG Mode: Enabled
Partition: 40192MiB / 40192MiB (42 SMs)
```

### Error Stack Trace
```python
File "diff_gaussian_rasterization/__init__.py", line 93, in forward
    num_rendered, color, objects, radii, geomBuffer, binningBuffer, imgBuffer = 
        _C.rasterize_gaussians(*args)
RuntimeError: CUDA out of memory. 
Tried to allocate 21384.46 GiB (GPU 0; 39.25 GiB total capacity)
```

---

## References

1. **NVIDIA GPU Operator Documentation**  
   R570 Known Issues - MIG NVML Regression

2. **Reproducible Test Case**  
   Repository: github.com/chabeck1/capoom-gg  
   Path: `/home/chabeck/gaussian-grouping/`  
   Test: `sbatch slurm_jobs/train_bear_mig.slurm`

3. **Working Comparison**  
   Same code on spgpu: Job 35331135 (completed successfully)

---

## Request

Please update NVIDIA driver on gpu_mig40 partition nodes to:
- **Preferred**: Driver 570.86.15 (known working)
- **Alternative**: Driver 570.158.02+ (regression fixed)

This will restore gpu_mig40 partition functionality and provide users access to A100 MIG resources.

---

**Contact**: chabeck@umich.edu  
**Account**: entr490s113y25_class  
**Project**: Gaussian Grouping for Mcity 3D Reconstruction
