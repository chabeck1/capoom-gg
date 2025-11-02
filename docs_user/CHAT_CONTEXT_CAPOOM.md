Capoom / Gaussian-Grouping — Chat Context & Project Summary

Purpose

This file is a single, comprehensive context document you can paste into a new chat to bring an assistant up to speed on the Capoom project and your current work state. It captures the high-level goals, architecture, data & commands, experiments, current status, lessons learned, troubleshooting notes, and next steps. Use it as the context seed when starting new conversations.

1) Project summary (one-paragraph)

You are building a digital-twin pipeline for Capoom AV testing that uses Gaussian Grouping (Gaussian Splatting) for 3D scene reconstruction and object segmentation, GroundingDINO + SAM for text-based detection, and a catalog system to extract and re-insert 3D object assets. The pipeline supports object removal, extraction to a catalog, and addition of catalog objects back into scenes. The goal is to create verifiable scenario testing (e.g., adding/removing street furniture) for autonomous vehicle validation.

2) Key components & repo layout (quick reference)

- Core project: /home/chabeck/gaussian-grouping
- Main scripts and tools:
  - `train.py` — train Gaussian Grouping on a scene
  - `render.py` — render images and object visualizations from trained model
  - `render_lerf_mask.py` — run text detection pipeline (GroundingDINO + SAM + IoA) and produce object_id lists
  - `capoom_street_furniture.py` — core capoom tool: detect / extract / add / remove objects and manage catalog
  - `edit_object_removal.py` — object removal pipeline using learned classifier and masks
  - `metrics.py` — compute PSNR / SSIM / LPIPS (needs lpips dependency)
  - `inspect_scene_objects.py` — quick helper to inspect object counts from classifier (added during analysis)
  - `evaluate_segmentation.py` — compute pixel accuracy & mean IoU vs ground truth (added during analysis)
  - slurm_jobs/* — SLURM job scripts to run training, extraction, addition, rendering, inspection, evaluation
- Data / outputs:
  - `data/<scene>/` — images, COLMAP sparse/ camera info, optional ground-truth object masks
  - `output/<scene>/point_cloud/iteration_<N>/` — trained point cloud + classifier
  - `catalog/<object_name>/gaussians.pt` + `metadata.json` — extracted object asset
  - `output/<scene>/point_cloud/iteration_30000_modified/point_cloud.ply` — scenes modified with added objects

3) Pipeline & workflows

A. Training (per-scene)
- Inputs: images (COLMAP format), camera poses (COLMAP), optional object masks (`data/<scene>/object_mask`) for supervised segmentation
- Run: `sbatch slurm_jobs/train_job.slurm -s <data/scene> -m output/scene` (or `python train.py ...` locally)
- Output: `point_cloud.ply` and `classifier.pth` at `output/scene/point_cloud/iteration_<iter>/`
- PSNR example: Bear scene reported PSNR ≈ 28.61 dB at 30k iterations (good visual quality)

B. Text-based detection (GroundingDINO + SAM + IoA)
- Run: `python render_lerf_mask.py -m output/scene --iteration 30000 --text "bear"` or similar multi-text
- Steps: GroundingDINO finds bounding boxes, SAM refines to pixel masks, IoA matches 2D masks to 3D object IDs by intersection-over-area
- Output: `object_ids---<text>.json` (list of object IDs), visualizations (grounded-sam---*.png)

C. Catalog creation (extract)
- `capoom_street_furniture.py --scene output/scene --mode extract --objects "name1;name2"` or use SLURM `catalog_extract_job.slurm`
- Extraction uses the per-Gaussian classifier probabilities and applies an extraction threshold (default 0.5). It saves `gaussians.pt` and `metadata.json` for each catalog asset.
- Typical extracted counts: bear -> 328,583 Gaussians

D. Catalog insertion (add)
- `capoom_street_furniture.py --mode add --scene output/scene --objects <catalog_name> --position x,y,z --rotation rx,ry,rz --scale 1.0`
- Important: use `--scale 1.0` (scale >1 spreads Gaussians and causes transparency, scale 1.2 caused ghostly bear)
- SLURM wrapper `catalog_add_job.slurm` accepted `<target_scene> <catalog_obj> <x,y,z> <rx,ry,rz> <scale>` and produced `iteration_30000_modified/point_cloud.ply`

E. Rendering modified scenes
- Current `render.py` expects an integer iteration value; modified scenes are saved under `iteration_30000_modified` (string suffix), so rendering with `--iteration 30000_modified` fails. Workarounds: copy classifier and necessary files into a standard numeric-named iteration folder or modify `render.py` to accept non-integer iteration names.

4) Visual outputs

- Concat images (in `output/<scene>/train/ours_<iter>/concat/`) are horizontally stacked (5 panels):
  1. GT image (original photo)
  2. Rendered image (model reconstruction)
  3. GT object mask (human-labeled segmentation; present if ground truth provided)
  4. Predicted object mask (model predictions from classifier)
  5. Render object features (RGB visualization of internal 16D object features)

Notes:
- Panels 1 & 2: reconstruction (PSNR measurement uses these)
- Panels 3 & 4: segmentation comparison (GT vs model predictions)
- Panel 5: debugging internal features, not used for decisions

5) What each tool creates and where to look

- `output/<scene>/train/ours_30000/concat/*.png` — five-panel visualization
- `output/<scene>/point_cloud/iteration_30000/` — `point_cloud.ply`, `classifier.pth` (trained checkpoint)
- `catalog/<object>/` — `gaussians.pt` and `metadata.json`
- `output/<scene>/train/ours_30000_text/object_ids---<text>.json` — detected object IDs from text
- `data/<scene>/object_mask/` — human-labeled per-frame masks (if present)

6) Key findings from debugging & experiments (concise summary)

- Extraction threshold vs density:
  - Extraction masks are applied per-Gaussian using the classifier probabilities. The threshold (default 0.5) is per-Gaussian probability of belonging to the selected object ID.
  - Lowering threshold (e.g., 0.3) will include less-confident Gaussians, filling peripheral surface detail, at the cost of potentially more background noise.
- Scaling effect:
  - Scaling a catalog object's coordinates >1.0 spreads the same number of Gaussians into a larger volume (volume scales with scale^3). E.g., 1.2× scale → ~1.728× volume. That reduces Gaussian density and causes the inserted object to appear transparent/ghostly.
  - Rule: Use scale=1.0 for catalog insertion unless you explicitly want a larger object and are willing to increase Gaussian count.
- Class ID mapping & evaluation pitfalls:
  - Model learns object clusters and uses internal numeric IDs (0..N). GT labels are human IDs. Direct IoU-based evaluation can be misleading if ID numbers don't align (the model's object 117 could be the human-labeled 34). You need to align IDs (match via IoA or Hungarian matching) before computing IoU.
  - The earlier low pixel accuracy (~9.25%) came from not aligning IDs for evaluation — the model had good segmentation but different ID numbering.
- Rendering & iteration naming:
  - `render.py` expects integer iteration values. Modified scenes saved as `iteration_30000_modified` break this expectation and will not render directly using `--iteration`.

7) Ground truth & what it is useful for

- For the bear dataset, GT masks exist under `data/bear/object_mask/` (96 frames). They are human-created segmentation masks with discrete object labels (86 unique objects). GT was used during training (the training code reads `viewpoint_cam.objects` and uses it in `loss_obj`).
- GT is valuable for:
  - Supervised learning of segmentation (improves boundaries and correctness)
  - Evaluation (PSNR, IoU, per-class accuracy) if you align IDs
  - Verifying and debugging specific object extraction quality

8) How to evaluate & verify model accuracy (recommended practice for Capoom)

- DO NOT rely solely on the model's own confidence scores. Use externally verifiable metrics and human spot checks.
- Recommended multi-pronged approach for new datasets (no GT):
  1. Cross-detection agreement: run GroundingDINO, YOLO/other detectors, and CLIP-based checks — high agreement increases trust
  2. Temporal consistency: require object presence in many frames (>50% or scene-dependent threshold)
  3. Geometric consistency: check physical plausibility (height above ground, size ranges)
  4. Catalog matching: compare detected object feature signatures to verified objects in the catalog
  5. Human-in-the-loop spot checks: sample small percent of detections for manual verification and maintain running accuracy estimates
  6. Map & external data checks (OpenStreetMap, Street View) where available
- Tools added to repository to help:
  - `inspect_scene_objects.py` (counts & confidences for each object ID)
  - `evaluate_segmentation.py` (pixel accuracy, mean IoU; needs aligned IDs or nearest-ID matching to be meaningful)

9) Current state of bear scene (facts)

- Trained model: `output/bear/point_cloud/iteration_30000/` — contains ~2.95M Gaussians
- Extracted bear catalog: `catalog/bear/gaussians.pt` — 328,583 Gaussians (metadata.json present)
- Modified scene after adding bear (scale 1.0): `output/bear/point_cloud/iteration_30000_modified/point_cloud.ply` — file was created and confirmed to be larger by ~102 MB (added Gaussians)
- PSNR from training: ~28.61 dB (good visual quality)
- Model detected 87 object clusters; ground truth lists 86 human-labeled objects (close correspondence)
- Concat visuals exist in `output/bear/train/ours_30000/concat/` showing gt vs predictions for several frames

10) Useful commands & quick recipes

- Train scene (SLURM):
  sbatch slurm_jobs/train_job.slurm -s data/scene -m output/scene

- Detect via text (quick):
  python render_lerf_mask.py -m output/scene --iteration 30000 --text "stop sign;traffic light"

- Extract a catalog object (SLURM):
  sbatch slurm_jobs/catalog_extract_job.slurm output/scene "object name"

- Add catalog object (SLURM):
  sbatch slurm_jobs/catalog_add_job.slurm output/scene catalog_name 5.0,0.0,1.5 0,45,0 1.0

- Inspect which object IDs exist (quick):
  python inspect_scene_objects.py --scene output/bear

- Evaluate segmentation (requires predictions rendered and possibly ID alignment):
  sbatch slurm_jobs/eval_segmentation.slurm output/bear

11) Troubleshooting notes (common failures and fixes)

- Error: `render.py` fails for iteration name `30000_modified` -> `--iteration` expects an integer
  Fix: copy modified files into a numeric iteration folder OR adjust `render.py` to accept string iteration values.

- Ghostly inserted object after add:
  Cause: scale >1 (e.g., 1.2) spread Gaussians into larger volume
  Fix: use scale=1.0 or re-extract with higher threshold or increase Gaussians

- Low segmentation IoU result:
  Cause: misaligned IDs between GT and model predictions
  Fix: match objects (IoA/Hungarian matching) before computing per-class IoU; use spatial overlap to align model IDs to GT IDs

- `metrics.py` fails due to missing `lpipsPyTorch` dependency
  Fix: `pip install lpips-pytorch` or use the provided `lama/requirements.txt` to add missing packages

12) Lessons learned (operational)

- Use `scale=1.0` by default when adding catalog objects.
- Extraction threshold 0.5 gives a conservative, high-confidence extraction; lower to 0.3 if object appears sparse.
- ID alignment is essential for meaningful segmentation evaluation — implement an automatic ID matching (IoA-based or Hungarian) before computing IoU.
- SAM is a helpful tool for generating masks from text queries but is not a replacement for ground truth training masks.

13) Next steps (suggested priorities for the Capoom project)

- Implement ID-alignment utility to compute true IoU vs GT automatically after matching model IDs to human IDs.
- Create a small semi-supervised workflow that uses SAM to generate pseudo-labels for important objects (stop signs, traffic lights, hydrants), then fine-tune the model on those pseudo-labels.
- Add an automated check in `catalog_add_job.slurm` to ensure a numeric iteration exists for render.py or allow render.py to accept string iterations.
- Add monitoring metrics and a simple dashboard (one-page) that tracks detection agreement, temporal consistency, and per-scene accuracy over time.

14) Contact & provenance

- Repository: `git remote` set to your project workspace
- Key authors / contributors: (project owner likely you / research group) — check `README.md` for more precise authorship

---

End of summary file. Paste the content of this file into a new chat to give the assistant full context about Capoom and the Gaussian-Grouping pipeline.
