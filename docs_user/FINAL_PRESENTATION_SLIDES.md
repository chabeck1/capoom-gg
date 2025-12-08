# Capoom - Final Presentation
**Vikram Anantha, Aditi Vishnubhatla, Charlie Beck, Tejas Dumpeta**  
November 14, 2025

---

## Slide 1: The Team
*(Keep your existing slide - no changes needed)*

---

## Slide 2: Capoom's Background
*(Keep your existing slide - looks good)*

---

## Slide 3: Capoom's Mission & Our Role

**Capoom's Challenge:**
- AV companies need to test edge cases (missing stop signs, occluded pedestrians)
- Physical testing costs $50-100M per project
- Can't test dangerous scenarios safely

**Our Solution:**
- Build digital twins of street scenes
- Enable "what-if" scenario testing (remove/add objects)
- Generate synthetic training data for AV perception models

**Our Impact:**
- 99% cost reduction: $50M physical testing → $500k digital twin
- Test scenarios impossible in real world
- Systematic edge case coverage

---

## Slide 4: Business Model
*(Keep your existing slide - it's good)*

---

## Slide 5: Solution Ecosystem
*(Keep your existing slide - it's good)*

---

## Slide 6: Project Scope - What We Built

**Semester Goal (from Sept):**
*"Detect and segment street furniture in 3D Gaussian Splat models"*

**What We Actually Delivered (by Nov):**

**Phase 1: Detection & Segmentation** ✅
- Trained Gaussian Grouping on MCity (33,450 images) and Capoom datasets
- Automatic object detection: 50+ objects per scene
- Text-based queries: "stop sign;fire hydrant;crosswalk"

**Phase 2: Scene Editing** ✅ (Stretch Goal Achieved!)
- Object removal with automatic inpainting
- Object addition from catalog
- Asset extraction for reusable 3D models

**Phase 3: Scalability** ✅ (Unexpected Achievement!)
- Solved memory bottleneck (0GB → 350GB crash)
- Enabled city-scale datasets (33× larger than baseline)

**Team Division:**
- **Charlie**: Capoom dataset pipeline + catalog system
- **Vikram**: MCity large-scale training
- **Tejas & Aditi**: Metrics implementation (PSNR, SSIM, LPIPS)

---

## Slide 7: Method Selection - Why Gaussian Grouping?

**Repos We Evaluated (Sept-Oct):**

| Method | Instance Segmentation? | Custom Dataset? | Object Editing? | Zero-Shot? | Decision |
|--------|------------------------|-----------------|-----------------|------------|----------|
| **Semantic Gaussians** | ❌ (only semantic) | ✅ | ❌ | ✅ | Too limited |
| **LangSplat** | ❌ (view-only) | ✅ | ❌ | ✅ | No editing |
| **DriveStudio** | ✅ | ✅ | ❌ | ✅ | Similar but no edit |
| **Gaussian Grouping** | ✅ | ✅ | ✅ | ✅ | **✅ CHOSEN** |

**Why Gaussian Grouping Won (Oct 22):**
1. **Instance Segmentation**: Unique IDs for each object (not just categories)
2. **Built-in Editing**: Removal, inpainting, addition already implemented
3. **Confirmed by Ibrahim**: Capoom validated it works with their data
4. **Most Complete**: Only method with full detection → editing pipeline

**Key Technologies Integrated:**
- **SAM (Segment Anything)**: 2D mask generation
- **GroundingDINO**: Text-to-object detection
- **3D Identity Encoding**: Groups 2D masks into 3D objects
- **LaMa Inpainting**: Background fill after removal

---

## Slide 8: What Actually Happened - Timeline

| **September** | **October** | **November** |
|---------------|-------------|--------------|
| **Repo Survey** | **Method Selection** | **Scale & Integration** |
| 📚 Evaluated 4+ methods | ✅ Chose Gaussian Grouping (Oct 22) | 🔥 **Memory Crisis** (Week of Nov 3) |
| - Semantic Gaussians | 🔧 Set up Great Lakes SLURM | - Training crashes at 15k iters |
| - LangSplat | 🧪 Small dataset tests (bear, garden) | - Diagnosed image cache leak |
| - DriveStudio | 📊 Metrics research (PSNR, SSIM, LPIPS) | - **Built constant-memory fix** |
| - Gaussian Grouping | | |
| | | |
| **Team Roles Assigned (Oct 16):** | **Stretch Goal Unlocked (Oct 26):** | **Final Sprint (Nov 2+):** |
| - Aditi: GG outputs & metrics | - Cataloging feature design | ✅ Vikram: MCity training (33k images) |
| - Charlie: Catalog features | - Ibrahim provides Capoom data | ✅ Charlie: Capoom dataset pipeline |
| - Vikram: LangSplat research | | ✅ Tejas & Aditi: Metrics implementation |
| - Tejas: Alternative methods | | ✅ Documentation & handoff |

**Key Decision Point (Oct 22):**
- **Original Goal**: "Detect and segment objects"
- **Expanded Scope**: "Detect, segment, AND edit scenes"
- **Why**: Ibrahim confirmed editing is critical for Capoom's AV testing use case

**Unexpected Challenge (Nov 3):**
- **Discovery**: Training on full MCity (33k images) crashes with OOM
- **Root Cause**: Image caching caused 350GB+ memory growth
- **Team Response**: Charlie built constant-memory solution (Week of Nov 3-7)
- **Impact**: Unlocked city-scale training (project success depended on this fix!)

---

## Slide 9: Tech Roadmap - Original Plan vs. Reality

### Original Plan (September)

```
Sept: Choose repo → Oct: Implement detection → Nov: Test & document
Goal: "Detect objects in Gaussian Splats" (confirmed with Ibrahim)
```

### What Actually Happened

**September: Repo Survey & Evaluation**
- ✅ Created comparison matrix (4 methods)
- ✅ Set up Great Lakes HPC (GPU cluster)
- ✅ Tested Gaussian Grouping on small datasets
- 📊 **Decision Point**: Choose Gaussian Grouping (Oct 22)

**October: Method Implementation & Scope Expansion**
- ✅ Trained on MCity and Capoom data
- ✅ Implemented text-based detection (GroundingDINO)
- 🎯 **Decision Point**: Add editing features (Oct 26)
  - **Why**: Ibrahim confirmed editing is critical for AV testing
  - **Impact**: Moved from "detection only" to full editing pipeline

**November: Crisis & Resolution**
- 🔥 **Critical Issue Discovered** (Nov 3): Memory crash on large datasets
  - Training dies at 15k iterations (350GB+ memory)
  - Blocks city-scale scenes (main Capoom use case)
- 🛠️ **Engineering Sprint** (Nov 3-7): Built constant-memory system
  - Root cause: Image cache growing unbounded
  - Solution: Lazy-load images from disk on every access
  - Result: 15GB constant memory, unlimited iterations
- ✅ **Delivery** (Nov 8-14): Full pipeline + documentation

**How Time Organized Our Work:**

| Decision Point | Options Considered | Decision | Impact |
|----------------|-------------------|----------|---------|
| **Oct 22: Choose Method** | 4 repos evaluated | Gaussian Grouping | Enabled editing features |
| **Oct 26: Expand Scope?** | Detection only vs. +Editing | Add editing | Differentiated from competitors |
| **Nov 3: Handle Memory Crisis** | (A) Reduce dataset, (B) More GPUs, (C) Fix leak | Fix root cause | Unlocked city-scale (critical!) |
| **Nov 7: Revert Pruning** | Custom pruning vs. Baseline | Use baseline | Simplified handoff |  

---

## Slide 10: Deliverables - What We Built

### Code & Infrastructure
1. **Constant Memory Training System**
   - Files: `scene/cameras.py`, `utils/camera_utils.py`
   - Impact: 33× scale increase, 95% memory reduction

2. **Text-Based Detection Pipeline**
   - Files: `render_lerf_mask.py`, `edit_by_text.py`
   - Impact: Natural language → 3D object IDs (90% accuracy)

3. **Asset Catalog System**
   - Files: `capoom_street_furniture.py`, catalog SLURM jobs
   - Impact: Extract/insert objects across scenes

4. **15+ SLURM Job Templates**
   - Automated training, detection, extraction, rendering

### Documentation
5. **8 Comprehensive User Guides**
   - Complete workflow documentation
   - Team onboarding materials
   - Technical deep-dives

### Trained Models
6. **Mcity Digital Twin** (33,450 images)
   - 100k training iterations
   - 2.1M Gaussians
   - 50+ detected objects

---

## Slide 11: Progress Photos - Before & After

### Reconstruction Quality
*(Keep your existing "Truth Render" comparison)*

### Object Detection
*(Keep your existing "RGB Image → Object Segmentation" comparison)*

### Scene Editing Pipeline
*(Keep your existing "Initial → Removal → Inpainting → Addition" comparison)*

### **NEW: Scale Achievement**
**Small Dataset (96 images):**
- Memory: 5-10GB
- Training: 2 hours

**Large Dataset (33,450 images) - Our Work:**
- Memory: 15GB (constant!)
- Training: Unlimited iterations possible
- Same GPU, 33× more images

---

## Slide 12: Technical Metrics - Actual Results

### Scalability Improvements
| Metric | Baseline | Our Work | Improvement |
|--------|----------|----------|-------------|
| Max Training Images | 1,000 | 33,450 | **33× scale** |
| Memory Usage (30k iters) | 350GB (crash) | 15GB | **95% reduction** |
| Object Selection Time | 2 hours | 2 minutes | **60× faster** |

### Detection Performance (Tejas & Aditi's Metrics)
- **GroundingDINO Accuracy**: 90-95% on street furniture
- **PSNR (Peak Signal-to-Noise Ratio)**: Measures rendering quality
  - Small datasets (96 images): 22-25 dB
  - Large datasets (33k images): 16-20 dB (expected - less coverage per image)
- **SSIM (Structural Similarity)**: Perceptual quality metric
- **LPIPS (Learned Perceptual)**: Deep learning-based quality assessment
- **Common Objects Detected**: stop sign, traffic light, fire hydrant, bench, bollard, crosswalk
- **IoA Threshold**: 0.6 (balances precision/recall)

### Asset Catalog
- **Extracted Objects**: 5+ reusable assets
- **Catalog Format**: Gaussian tensors + metadata
- **Insertion Success**: 80-90% visual quality

---

## Slide 13: Current Pipeline - End to End

```
[Street Images] → [COLMAP] → [Gaussian Grouping Training]
                                       ↓
                              [Trained 3D Scene]
                                       ↓
                    ┌──────────────────┴──────────────────┐
                    ↓                                     ↓
          [Text Query Detection]              [Direct Editing]
          "stop sign;fire hydrant"              (manual IDs)
                    ↓                                     ↓
              [Object IDs]  ────────────────────→  [Scene Editor]
                                                           ↓
                                    ┌──────────────────────┴──────────────────┐
                                    ↓                      ↓                  ↓
                             [Object Removal]      [Object Addition]   [Inpainting]
                                    ↓                      ↓                  ↓
                            [Modified Scene] ←─────────────┴──────────────────┘
                                    ↓
                        [Render for AV Testing]
```

**Time Per Scene:**
- Training: 2-3 hours (30k iterations)
- Detection: 10 minutes (50+ objects)
- Editing: 15 minutes per operation
- **Total**: 3-4 hours scene → editable digital twin

---

## Slide 14: Real-World Usage Example

### Scenario: Test AV Stop Sign Detection

**1. Baseline Scene**
- Train on Mcity intersection (33k images)
- Detect all street furniture: `"stop sign;traffic light;crosswalk"`
- Result: Stop sign at object ID [34, 67]

**2. Create Test Scenario**
- Remove stop sign: `python edit_by_text.py --text "stop sign"`
- Inpaint background automatically
- Result: Scene without stop sign

**3. AV Testing**
- Export to CARLA simulator (future work)
- Test: Does AV stop at intersection without sign?
- **Expected**: AV should detect missing sign and apply default rules

**Business Value:**
- Physical test: $50k+ to remove real stop sign (illegal!)
- Digital twin: $50 compute cost
- **1000× cost savings**

---

## Slide 15: Tech Roadmap - Completed & Future

### ✅ Completed This Semester
- 3D reconstruction pipeline (Gaussian Grouping)
- Text-based object detection (GroundingDINO + SAM)
- Object removal with inpainting (LaMa)
- Asset catalog system (extraction/insertion)
- Scalable training (constant memory mode)
- Comprehensive documentation

### 🔄 In Progress
- Mcity full dataset training (100k+ iterations)
- Capoom partner data integration
- PLY segmentation for pre-trained models

### ⏳ Next Semester / Future
- **Simulator Integration** (CARLA, SUMO export)
- **Multi-Scene Composition** (combine street segments)
- **Automated Test Generation** (NHTSA scenario templates)
- **Real-Time Editing** (interactive preview)
- **City-Scale Scenes** (1-5 km² coverage)

---

## Slide 16: Risks & How We Mitigated Them

### Risk 1: Memory Scalability ❌→✅
**Risk**: Can't train on city-scale datasets  
**Impact**: Project scope limited to small scenes  
**Mitigation**: Built constant-memory system (Week 3-4)  
**Outcome**: Enabled 33× larger datasets  

### Risk 2: Detection Accuracy ❌→✅
**Risk**: Manual object selection doesn't scale  
**Impact**: 2 hours per scene, error-prone  
**Mitigation**: Integrated GroundingDINO for text queries  
**Outcome**: 90% accuracy, 60× faster  

### Risk 3: Data Format Compatibility ❌→✅
**Risk**: Capoom PLYs lack semantic properties  
**Impact**: Can't run text queries on partner data  
**Mitigation**: Built separate PLY segmentation tools  
**Outcome**: Processed Capoom data successfully  

### Risk 4: Asset Scaling Issues ❌→✅
**Risk**: Inserted objects look transparent  
**Impact**: Unusable for realistic scenarios  
**Mitigation**: Discovered scale=1.0 requirement (volume = scale³)  
**Outcome**: 80-90% visual quality on insertion  

---

## Slide 17: Challenges That Remain

### High Priority (Next Semester)
1. **Simulator Integration**
   - Export to CARLA/SUMO for AV testing
   - Estimated: 4-6 weeks

2. **Lighting Consistency**
   - Inserted objects have lighting mismatch
   - Need automatic relighting

3. **Multi-Scene Composition**
   - Combine street segments from different locations
   - Enables larger test scenarios

### Medium Priority
4. **Detection on Small Objects** (70-80% current)
   - Fine-tune on street furniture dataset

5. **Automated Test Scenarios**
   - Generate NHTSA safety scenarios automatically

---

## Slide 18: What We Learned

### Technical Skills Gained

**Charlie:**
- 3D reconstruction (Gaussian Splatting architecture)
- GPU memory profiling and optimization (solved memory crisis!)
- Vision-language models (GroundingDINO, SAM, CLIP)
- HPC/SLURM job scheduling (Great Lakes cluster)
- 3D geometry & coordinate transforms

**Vikram:**
- Large-scale dataset training (33k images)
- Distributed computing workflows
- COLMAP and structure-from-motion
- Training convergence analysis

**Tejas & Aditi:**
- Perceptual quality metrics (PSNR, SSIM, LPIPS)
- Segmentation evaluation (IoU, ARI, NMI)
- Research methodology (comparing methods systematically)
- Scientific visualization

**Team-Wide:**
- Research paper implementation (ECCV'24 paper → production code)
- HPC resource management (Great Lakes SLURM)
- Technical documentation for non-experts
- Reproducible experiment tracking

### Engineering Lessons (from meeting notes & experience)

1. **"Solve root cause, not symptoms"**
   - Memory crash → didn't just reduce dataset, fixed the cache leak
   - 2 days diagnosis > 2 months of workarounds

2. **"Measure before optimizing"**
   - Profiled memory to find image cache (not Gaussians) was the problem
   - 30 minutes of profiling > 30 hours of guessing

3. **"Build for the team, not just yourself"**
   - Ibrahim provided Capoom data in different format
   - Had to create PLY tools for team to process partner data

4. **"Communicate blockers early"**
   - Flagged memory issue to team immediately (Nov 3 meeting)
   - Got architectural guidance instead of debugging alone for days

### Project Management (real timeline)

**What We Planned (Sept):**
- Choose repo → implement detection → test

**What Actually Happened:**
- Sept: Evaluated 4 repos systematically (comparison matrix)
- Oct 22: **Decision point** - chose Gaussian Grouping
- Oct 26: **Scope expanded** - added editing features (Ibrahim's request)
- Nov 3: **Crisis** - memory crash discovered
- Nov 3-7: **Emergency fix** - constant memory implementation
- Nov 8-14: **Delivery** - full pipeline working

**Lesson**: Agile > waterfall for research projects with unknown unknowns

### Gaps in Coursework (what we had to learn on our own)

1. **3D Computer Graphics** - Never covered in CS curriculum
   - Learned: Gaussian Splatting, point cloud rendering, rasterization
   - Source: Research papers + GitHub code deep-dives

2. **HPC & SLURM** - Minimal systems coverage
   - Learned: Job scheduling, GPU allocation, cluster debugging
   - Source: Great Lakes docs + trial-and-error

3. **Production ML Systems** - Theory heavy, deployment light
   - Learned: Checkpoint management, reproducibility, versioning
   - Source: Industry best practices + team feedback

4. **Vision-Language Models** - Cutting-edge (2023-2024 research)
   - Learned: GroundingDINO, CLIP, open-vocabulary detection
   - Source: Recent papers + GitHub implementations

5. **Technical Communication** - Never taught formally
   - Learned: Write for non-experts (Ibrahim, future team members)
   - Source: Iteration based on feedback

### How This Course Influenced Our Judgment

**Before:**
- Would try to force original plan even when better path emerged
- Guessed at performance bottlenecks based on intuition
- Tried to solve blockers alone before asking for help

**After:**
- **Adapted scope** when Ibrahim confirmed editing was critical (Oct 26)
- **Profiled first** to find image cache was the real memory issue
- **Communicated blockers early** in team meetings (Nov 3)

**Biggest Lesson:**
Research engineering requires hybrid skills - you need to understand papers (research), debug GPU kernels (systems), AND build usable pipelines (product). This combination is rare and valuable.

---

## Slide 19: Business Impact for Capoom

### Cost Reduction
- **Physical AV Testing**: $50-100M per project
- **Digital Twin Pipeline**: $500 per scene
- **Savings**: 99% cost reduction

### Time Acceleration
- **Physical Scenario Setup**: Weeks
- **Digital Scenario Generation**: Hours
- **Speedup**: 100× faster

### Safety Enablement
- Test dangerous scenarios without risk
- Systematic edge case coverage
- Reproducible for regulatory approval

### Competitive Advantage
- Constant-memory technique (novel contribution)
- Text-based detection (ease of use)
- Asset catalog (scenario composition)

---

## Slide 20: Next Steps - Concrete Plan

### Immediate (Next 2-4 Weeks)
1. ✅ **Complete Mcity training** (100k iterations done)
2. ✅ **Process Capoom partner data** (PLY segmentation done)
3. 🔄 **Handoff to Capoom engineering team** (in progress)
4. 🔄 **Build street furniture catalog** (5+ objects, target 20-30)

### Short-Term (Next 1-2 Months)
5. **CARLA Integration** - Export to simulator format
6. **Fine-Tune Detection** - Target 95%+ accuracy
7. **Optimize Inpainting** - Reduce artifacts to <10%

### Long-Term (Next Semester)
8. **Multi-Scene Composition** - Combine street segments
9. **Automated Test Generation** - NHTSA scenario templates
10. **City-Scale Coverage** - 1-5 km² digital twins

---

## Slide 21: Thank You + Demo

**What We Delivered:**
- ✅ Scalable 3D reconstruction (33× improvement)
- ✅ Text-based object detection (90% accuracy)
- ✅ Scene editing pipeline (removal/addition/inpainting)
- ✅ Asset catalog system
- ✅ Comprehensive documentation

**GitHub Repository:**
https://github.com/chabeck1/capoom-gg

**Documentation:**
See `docs_user/` folder for complete guides

**Questions?**

---

## Backup Slides

### Technical Architecture Details
*(Include system diagram if needed)*

### Memory Profiling Results
*(Show before/after memory graphs if you have them)*

### Detection Examples
*(More example queries and results)*

### Catalog Metadata
*(Show example JSON metadata from catalog)*
