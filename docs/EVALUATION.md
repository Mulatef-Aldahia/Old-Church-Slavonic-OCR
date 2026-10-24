# Evaluation Report: OCS OCR v6.0

## Dataset

### Overview
- **Total Pages:** 237 manually annotated manuscript pages
- **Total Boxes:** ~97,500 character bounding boxes
- **Classes:** 37 OCS characters (35 learnable + 2 rare)
- **Annotation Tool:** Roboflow

### Data Split
| Split | Pages | Percentage | Boxes (approx.) |
|-------|-------|------------|-----------------|
| Train | 193 | 81.4% | ~79,000 |
| Validation | 22 | 9.3% | ~9,000 |
| Test | 22 | 9.3% | 8,982 |

### Class Distribution
- **Most common:** н (787 boxes), е (717 boxes), о (608 boxes)
- **Least common:** ѳ (8 boxes), ѿ (10 boxes), ф (9 boxes)
- **Average boxes per page:** ~410

## Training Configuration

### Hardware & Software
- **Platform:** Google Colab (Free Tier)
- **GPU:** NVIDIA Tesla T4 (16GB VRAM)
- **Framework:** Ultralytics YOLOv8 8.4.187
- **Python:** 3.13.16
- **PyTorch:** 2.11.0+cu130

### Hyperparameters (v6 Recipe)
| Parameter | Value |
|-----------|-------|
| Optimizer | AdamW |
| Learning Rate (initial) | 0.01 |
| Learning Rate (final) | 0.01 |
| Momentum | 0.937 |
| Weight Decay | 0.0005 |
| Image Size | 1280×1280 |
| Batch Size | 16 |
| Epochs | 100 (early stopping) |
| Patience | 20 epochs |
| Freeze | 0 (all layers trained) |

### Augmentation
| Transformation | Parameters |
|----------------|------------|
| HSV-Hue | ±0.015 |
| HSV-Saturation | ±0.4 |
| HSV-Value | ±0.3 |
| Rotation | ±2° |
| Translation | ±5% |
| Scale | ±30% |
| Shear | ±1° |
| Mosaic | 0.5 probability |
| MixUp | 0.0 (disabled) |
| Copy-Paste | 0.0 (disabled) |

## Results

### Overall Metrics (Test Split - 22 pages)
| Metric | Value |
|--------|-------|
| **mAP50** | **0.8714** ✅ |
| **mAP50-95** | **0.8167** |
| **Precision** | **0.9113** |
| **Recall** | **0.8613** |
| **Total Inferences** | 22 images |
| **Total Detections** | 8,982 boxes |

### Performance Analysis
✅ **Target Met:** mAP50 = 0.8714 ≥ 0.85 (target achieved)

**Strengths:**
- High precision (0.9113) indicates low false positive rate
- Strong recall (0.8613) shows good detection coverage
- mAP50-95 of 0.8167 demonstrates robust bounding box localization

### Per-Class AP50 (37 Classes)

| Class ID | Character | AP50 | Status |
|----------|-----------|------|--------|
| 0 | (space) | 0.9277 | ✅ Excellent |
| 1 | а | 0.6800 | ⚠️ Moderate |
| 2 | б | 0.9114 | ✅ Excellent |
| 3 | в | 0.8734 | ✅ Good |
| 4 | г | 0.9289 | ✅ Excellent |
| 5 | д | 0.9312 | ✅ Excellent |
| 6 | е | 0.9312 | ✅ Excellent |
| 7 | ж | 0.8904 | ✅ Good |
| 8 | з | 0.9219 | ✅ Excellent |
| 9 | и | 0.9178 | ✅ Excellent |
| 10 | й | 0.8703 | ✅ Good |
| 11 | к | 0.8869 | ✅ Good |
| 12 | л | 0.9143 | ✅ Excellent |
| 13 | м | 0.9226 | ✅ Excellent |
| 14 | н | 0.9143 | ✅ Excellent |
| 15 | о | 0.9226 | ✅ Excellent |
| 16 | п | 0.9203 | ✅ Excellent |
| 17 | р | 0.9251 | ✅ Excellent |
| 18 | с | 0.9420 | ✅ Excellent |
| 19 | т | 0.8901 | ✅ Good |
| 20 | у | 0.8483 | ✅ Good |
| 21 | ф | 0.9079 | ✅ Excellent |
| 22 | х | 0.8937 | ✅ Good |
| 23 | ц | 0.9451 | ✅ Excellent |
| 24 | ч | 0.9504 | ✅ Excellent |
| 25 | ш | 0.9379 | ✅ Excellent |
| 26 | щ | 0.9332 | ✅ Excellent |
| 27 |  | 0.9454 | ✅ Excellent |
| 28 | ы | 0.9031 | ✅ Excellent |
| 29 | ь | 0.6489 | ⚠️ Moderate |
| 30 | ю | 0.9186 | ✅ Excellent |
| 31 | я | 0.8536 | ✅ Good |
| 32 | і | 0.9358 | ✅ Excellent |
| 33 | ї | 0.9302 | ✅ Excellent |
| 34 | (unknown) | 0.9548 | ✅ Excellent |
| 35 | ѣ | 0.2082 | ❌ Poor |
| 36 | ѧ | 0.5617 | ⚠️ Moderate |

### Performance Categories
- **Excellent (AP50 ≥ 0.90):** 24 classes (64.9%)
- **Good (0.80 ≤ AP50 < 0.90):** 9 classes (24.3%)
- **Moderate (0.60 ≤ AP50 < 0.80):** 3 classes (8.1%)
- **Poor (AP50 < 0.60):** 1 class (2.7%)

### Failure Analysis

#### Worst Performing Classes

**1. ѣ (Yat) - AP50=0.2082**
- **Issue:** Severely underperforming
- **Cause:** Very rare in dataset, possible confusion with similar glyphs
- **Mitigation:** Need targeted data augmentation or synthetic generation for this character

**2. ѧ (Little Yus) - AP50=0.5617**
- **Issue:** Moderate performance
- **Cause:** Limited examples, complex shape
- **Mitigation:** Increase representation in training set

**3. ь (Soft Sign) - AP50=0.6489**
- **Issue:** Below target threshold
- **Cause:** Small size, often appears in clusters
- **Mitigation:** Focus on small glyph detection improvements

**4. а (Az) - AP50=0.6800**
- **Issue:** Surprisingly low for common character
- **Cause:** High variability in handwritten forms
- **Mitigation:** More diverse augmentation for this character

#### Best Performing Classes
- **ѡ (Omega):** AP50=0.9548
- **ч (Cherv):** AP50=0.9504
- **щ (Shta):** AP50=0.9454
- **ц (Tsi):** AP50=0.9451

### Speed & Efficiency
| Metric | Value |
|--------|-------|
| Preprocessing | 30.8 ms/image |
| Inference | 31.7 ms/image |
| Postprocessing | 16.7 ms/image |
| **Total** | **~79 ms/image** |

### Comparison with Pre-training
| Model | mAP50 | mAP50-95 | Precision | Recall |
|-------|-------|----------|-----------|--------|
| Pre-trained (Synthetic) | ~0.85* | ~0.75* | - | - |
| Fine-tuned (Real) | **0.8714** | **0.8167** | **0.9113** | **0.8613** |
| **Improvement** | **+~2%** | **+~6%** | - | - |

*Estimated from Issue #3 results

## Known Limitations

1. **Rare Classes:** ѳ and ѿ have insufficient training data (<10 boxes each)
2. **Small Glyphs:** Performance decreases for characters <20px height
3. **Faded Manuscripts:** Recall drops on low-contrast pages
4. **Touching Characters:** Merged bounding boxes in dense text regions
5. **Rotation Sensitivity:** Pages rotated >10° show degraded performance
6. **Font Domain Gap:** Some synthetic-to-real transfer issues remain

## Recommendations for Future Work

1. **Data Collection:**
   - Add more examples of rare characters (ѳ, ѿ, ѣ)
   - Include diverse handwriting styles and periods
   - Balance class distribution

2. **Augmentation:**
   - Increase rotation range to ±15°
   - Add perspective transforms
   - Implement elastic deformations

3. **Model Architecture:**
   - Experiment with YOLOv8n vs YOLOv8s trade-offs
   - Consider character-specific detectors for rare classes
   - Add titlo mark detection as separate task

4. **Post-processing:**
   - Implement line grouping algorithm
   - Add language model for character sequence correction
   - Develop confidence-based filtering

## Reproducibility

### Dependencies