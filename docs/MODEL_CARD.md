# Old Church Slavonic OCR — Model Card v6

## Model Details
- **Model name:** YOLOv8n OCS v6
- **Version:** v6
- **Model type:** Character-level object detection
- **Architecture:** YOLOv8n
- **Intended deployment:** Dynamic ONNX for offline inference in the Flutter Android app and Gradio demo
- **Status:** TODO: confirm release status and model artifact availability

## Intended Use
Detect character bounding boxes for Old Church Slavonic (OCS) manuscript pages written in Ustav script, then support line grouping and reading-order reconstruction.

The model is intended for research, archival exploration, and as an aid to human transcription. Its output should be reviewed by a qualified reader and is not a verified transcription.

## Out of Scope
- Titlo and diacritic recognition or abbreviation expansion
- Translation, lemmatization, or semantic interpretation
- Glagolitic, poluustav, vyaz, or other scripts and hands
- Generalization to manuscripts outside the documented source

## Training Data
- **Source:** TODO: document manuscript collection and permissions
- **Pages:** 237 real manuscript pages
- **Annotations:** Approximately 97,500 character boxes; 37 documented classes, including 35 learnable classes and 2 documented unlearnable classes
- **Annotation tool:** Roboflow
- **Synthetic pre-training:** Ustav font renderings using KlimentStd and Menaion, with rotation, noise, and ink-bleed augmentation
- **Data split:** TODO: document exact train/validation/test page IDs and split method
- **Known rare classes:** ѳ (8 boxes) and ѿ (10 boxes)

## Training Procedure
- **Base model:** YOLOv8n
- **Random seed:** 7
- **Hardware:** Colab free tier, Tesla T4 when available
- **Hyperparameters:** TODO: record the pinned configuration and training schedule
- **Coverage guardrail:** Training should stop if any learnable class is absent from any data split

## Evaluation
- **Test set:** 22 held-out pages
- **Primary metric:** mAP50
- **Target:** mAP50 ≥ 0.85 across at least 35 learnable classes
- **Additional evaluation:** Character Error Rate (CER), per-page results, and per-class AP50
- **Measured results:** TODO: add results from the final held-out evaluation
- **Per-class failures and mitigations:** TODO: document classes with AP50 < 0.75 in `EVALUATION.md`

## Limitations and Risks
- Synthetic-to-real domain gap may reduce performance on manuscript ink and page texture.
- Performance is sensitive to glyph scale; the expected training glyph size is approximately 25 px.
- Recall may decrease on heavily faded pages.
- Touching or merged glyphs may remain difficult to separate.
- Rare classes ѳ and ѿ have too few examples for reliable detection; document their observed performance rather than implying dependable recognition.
- Scans skewed beyond ±10° are outside the documented augmentation range.
- Titlo marks, middle dots, and other unmodeled symbols may be ignored or filtered.

## Deployment and Parity
- **Export format:** Dynamic ONNX
- **Expected input sizes:** 320 and 1280
- **Parity check:** Compare ONNX detections with the PyTorch baseline; acceptable difference is within ±2 boxes under the defined parity procedure.
- **Offline behavior:** Inference must not make network calls.
- **APK size target:** ≤ 40 MB
- **Runtime targets:** < 2 s per crop and < 6 s per full page on the target device or Colab CPU
- **Artifact checksum and download:** TODO: add release URL and checksum when the model is published

## Privacy and Responsible Use
Manuscript images may be unpublished or culturally sensitive. Keep inference local and do not upload images without authorization. The detector can make errors and must not be treated as an authoritative scholarly transcription.

## Version History
- **v6:** TODO: record release date, training run, and changes from the previous version.
