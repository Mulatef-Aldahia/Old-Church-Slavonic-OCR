# Old Church Slavonic OCR — Model Card v6

## Model Details
- **Model name:** YOLOv8n OCS v6
- **Version:** v6.0.0
- **Model type:** Character-level object detection
- **Architecture:** YOLOv8n
- **Intended deployment:** Dynamic ONNX for offline inference in the Flutter Android app and Gradio demo
- **Status:** ✅ Released (v1.0.0)

## Intended Use
Detect character bounding boxes for Old Church Slavonic (OCS) manuscript pages written in Ustav script, then support line grouping and reading-order reconstruction.

The model is intended for research, archival exploration, and as an aid to human transcription. Its output should be reviewed by a qualified reader and is not a verified transcription.

## Out of Scope
- Titlo and diacritic recognition or abbreviation expansion
- Translation, lemmatization, or semantic interpretation
- Glagolitic, poluustav, vyaz, or other scripts and hands
- Generalization to manuscripts outside the documented source

## Training Data
- **Source:** Manually annotated OCS corpus (237 manuscript pages)
- **Pages:** 237 real manuscript pages
- **Annotations:** Approximately 97,500 character boxes; 37 classes
- **Annotation tool:** Roboflow
- **Synthetic pre-training:** Ustav font renderings using KlimentStd and Menaion, with rotation, noise, and ink-bleed augmentation
- **Data split:** 
  - Train: 193 pages (81.4%)
  - Validation: 22 pages (9.3%)
  - Test: 22 pages (9.3%)
- **Known rare classes:** ѳ (8 boxes) and ѿ (10 boxes)

## Training Procedure
- **Base model:** YOLOv8n pretrained on synthetic corpus
- **Random seed:** 42
- **Hardware:** Google Colab, Tesla T4 GPU
- **Hyperparameters:**
  - Optimizer: AdamW
  - Image size: 1280x1280
  - Batch size: 16
  - Epochs: 100 (early stopping patience=20)
  - Freeze: 0 (all layers trained)
  - Learning rate: 0.01 (initial), 0.01 (final)
  - Momentum: 0.937
  - Weight decay: 0.0005
  - Augmentation: HSV (h=0.015, s=0.4, v=0.3), rotation (±2°), translation (5%), scale (30%), shear (1°), mosaic (0.5)
- **Coverage guardrail:** ✅ Implemented - training stops if any learnable class is absent from any data split

## Evaluation
- **Test set:** 22 held-out pages (8,982 character boxes)
- **Primary metric:** mAP50
- **Target:** mAP50 ≥ 0.85 across at least 35 learnable classes
- **Additional evaluation:** Character Error Rate (CER), per-page results, and per-class AP50
- **Measured results:**
  - **mAP50:** 0.8714
  - **mAP50-95:** 0.8167
  - **Precision:** 0.9113
  - **Recall:** 0.8613
- **Per-class failures and mitigations:**
  - ѣ (Yat): AP50=0.2082 (rare class, needs more data)
  - ѳ (Fita): AP50=0.5617 (only 8 boxes in dataset)
  - ы (Yery): AP50=0.6489 (moderate performance)
  - All other classes: AP50 > 0.68

## Limitations and Risks
- Synthetic-to-real domain gap may reduce performance on manuscript ink and page texture.
- Performance is sensitive to glyph scale; the expected training glyph size is approximately 25-40 px.
- Recall may decrease on heavily faded pages.
- Touching or merged glyphs may remain difficult to separate.
- Rare classes ѳ and ѿ have too few examples for reliable detection; document their observed performance rather than implying dependable recognition.
- Scans skewed beyond ±10° are outside the documented augmentation range.
- Titlo marks, middle dots, and other unmodeled symbols may be ignored or filtered.

## Deployment and Parity
- **Export format:** Dynamic ONNX (yolov8n_ocs_FINAL_v6.onnx)
- **Expected input sizes:** 320 and 1280
- **Parity check:** ✅ ONNX detections match PyTorch baseline within ±2 boxes
- **Offline behavior:** ✅ Inference does not make network calls
- **APK size target:** ≤ 40 MB
- **Runtime targets:** < 2 s per crop and < 6 s per full page on target device or Colab CPU
- **Artifact checksum and download:** 
  - **PyTorch weights:** https://github.com/Mulatef-Aldahia/Old-Church-Slavonic-OCR/releases/download/v1.0.0/oco_v6.pt
  - **ONNX model:** https://github.com/Mulatef-Aldahia/Old-Church-Slavonic-OCR/releases/download/v1.0.0/oco_v6.onnx
  - **Per-class AP:** https://github.com/Mulatef-Aldahia/Old-Church-Slavonic-OCR/releases/download/v1.0.0/per_class_ap.csv

## Privacy and Responsible Use
Manuscript images may be unpublished or culturally sensitive. Keep inference local and do not upload images without authorization. The detector can make errors and must not be treated as an authoritative scholarly transcription.

## Version History
- **v6.0.0 (2026-10-25):** 
  - Fine-tuned on 237 real OCS manuscript pages
  - mAP50=0.8714, mAP50-95=0.8167
  - Pretrained on synthetic corpus (Issue #3)
  - Coverage guardrail implemented (Issue #4)
  - Synthetic generator with balanced distribution (Issue #2)
  - Released as v1.0.0 with ONNX export