# Old Church Slavonic OCR — Mini-SRS

## 1. Problem Description
Researchers and archivists working with Old Church Slavonic (OCS) manuscripts written in
Ustav (Uncial) script have no usable OCR tool. Commercial engines are trained on modern
print and fail on medieval hands: touching glyphs, faded ink, stains, titlo abbreviations,
irregular word spacing, and two-column layouts. Transcription therefore remains fully
manual, slow (hours per page), and error-prone.

## 2. Proposed Solution
A character-level detection and reading pipeline:
1. Pre-train YOLOv8n on synthetically rendered OCS pages (Ustav fonts with rotation,
	 noise, and ink-bleed augmentation).
2. Fine-tune on 237 real manuscript pages annotated manually at character level
	 (~97,500 boxes, 37 classes).
3. Reconstruct reading order: automatic column splitting, line grouping, and word
	 building from inter-glyph horizontal gaps.
4. Deploy offline via a dynamic ONNX model inside a Flutter APK and a Gradio web demo.

## 3. Target Users
- Slavic paleography researchers
- Manuscript archivists and digital-humanities labs
- Graduate students of historical linguistics
- Editors of critical editions of OCS texts

## 4. Project Scope (In Scope)
- Character-box detection for 35 learnable OCS classes (+2 documented unlearnable classes)
- Automatic two-column splitting and line grouping on full pages
- Word reconstruction using a horizontal-gap heuristic
- Character Error Rate (CER) evaluation against a manual reference
- Synthetic page generator (rotation, noise, ink-bleed)
- ONNX export with a PyTorch parity check (±2 boxes)
- Offline Android APK and Gradio demo
- Reproducible notebooks for every pipeline stage

## 5. Out of Scope
- Titlo/diacritic recognition and abbreviation expansion
- Translation, lemmatization, or semantic search
- Glagolitic and cursive scripts (poluustav, vyaz)
- Generalization to other manuscripts or hands
- Cloud services, user accounts, online synchronization

## 6. Functional Requirements
- **FR-01**: The system shall detect character bounding boxes for at least 35 OCS classes
	with mAP50 ≥ 0.85 on a held-out test split of 22 pages.
- **FR-02**: The system shall group detections into text lines and split two-column
	layouts automatically when the inter-column gap exceeds 8% of page width.
- **FR-03**: The system shall reconstruct words by inserting separators where the
	horizontal gap between consecutive glyphs exceeds 0.5 × median glyph width.
- **FR-04**: The system shall compute CER against a manually transcribed reference and
	report per-page and mean values.
- **FR-05**: The training pipeline shall enforce a coverage guardrail that aborts the run
	if any learnable class is absent from any data split.
- **FR-06**: The system shall export the model to dynamic ONNX accepting both 320 and
	1280 input sizes with ±2-box parity against the PyTorch baseline.
- **FR-07**: The Android APK shall run inference fully offline and display boxes plus
	extracted line text.

## 7. Non-Functional Requirements
- **NFR-01**: APK size shall not exceed 40 MB.
- **NFR-02**: Inference shall take < 2 s per crop and < 6 s per full page on a mid-range
	Android device or Colab CPU.
- **NFR-03**: Training shall be reproducible via fixed seeds (seed=7) and pinned
	hyperparameters.
- **NFR-04**: Every class with AP50 < 0.75 shall be documented with root cause and
	mitigation in MODEL_CARD and EVALUATION.
- **NFR-05**: No network calls shall occur during inference (privacy of unpublished
	manuscripts).

## 8. Assumptions & Constraints
- Single developer; one-semester timeline.
- Single manuscript source: 237 pages, Ustav script, brown ink, two columns.
- GPU available only through Colab free tier (Tesla T4, session-limited).
- Rare classes (ѳ: 8 boxes, ѿ: 10 boxes) cannot reach usable AP; documented, not fixed.
- Annotation performed in Roboflow; synthesis fonts: KlimentStd and Menaion.

## 9. Preliminary Risks & Edge Cases
**Risks**
- Domain gap between synthetic pre-training and real manuscript ink.
- Scale sensitivity: inference resolution must match training glyph size (~25 px).
- Recall drop on heavily faded pages.
- ONNX/PyTorch numerical drift after export.

**Edge Cases**
- **EC-01**: Input image < 600 px (crop) vs > 1200 px (full page) → automatic imgsz rule
	(320 vs 1280).
- **EC-02**: Blank margins or empty regions → zero detections must return empty text
	gracefully, without crashing.
- **EC-03**: Narrow column gutter (< 8% of width) → fall back to single-column reading.
- **EC-04**: Touching or merged glyphs → NMS IoU 0.7; residual merges documented.
- **EC-05**: Dead class 0 ("space") firing on punctuation → filtered post-inference.
- **EC-06**: Skewed scans beyond ±10° → documented limitation (augmentation covers ±10°).
- **EC-07**: Middle dots (·) and titlo marks are not classes → ignored or filtered.
- **EC-08**: Duplicate image submissions in the app → stateless, idempotent inference.