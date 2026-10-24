# Old Church Slavonic OCR

Character-level detection and OCR for Old Church Slavonic (OCS) manuscripts written in
**Ustav (Uncial) script**, built with YOLOv8n and deployed as an offline Flutter APK,
a dynamic ONNX model, and a Gradio web demo.

## Brief Description
Medieval OCS manuscripts cannot be processed by commercial OCR: touching glyphs, faded
ink, stains, titlo marks, and two-column layouts break modern engines. This project
detects each character as a bounding box (37 classes), reconstructs columns → lines →
words, and reports Character Error Rate (CER) against manual references.

## Team
- Mulatef Aldahia — sole developer (requirements, annotation, training, deployment, docs)

## Expected Technologies
- Python, PyTorch, Ultralytics YOLOv8n
- ONNX Runtime (dynamic input), Gradio
- Flutter / Dart (Android APK)
- Git, GitHub (Issues, Projects, PRs)

## Results (held-out test, 22 pages / 8,982 boxes)
| Metric | Value |
|---|---|
| mAP50 (37 classes) | **0.878** |
| mAP50-95 | 0.822 |
| Precision / Recall | 0.911 / 0.861 |
| Mean AP50, 35 learnable classes | 0.908 |
| ONNX↔PyTorch parity | 75/75 boxes (crop), ±0 |

## Pipeline
```
Synthetic pages (KlimentStd/Menaion fonts, rotation+noise+ink-bleed)
        → Pre-train → Class mapping → Fine-tune (237 pages, ~97.5k boxes)
        → Coverage guardrail → Export dynamic ONNX → Flutter APK / Gradio
```

## Repository Structure
- `training/` — synthetic generator, fine-tuning, ONNX export, parity check
- `evaluation/` — CER metric, column-aware word builder
- `app/` — Flutter source + ONNX assets for the offline APK
- `notebooks/` — reproducible Colab notebooks per stage
- `docs/` — SRS, MODEL_CARD, DATASET_CARD, EVALUATION, DEV_LOG

## Quick Start
```python
from ultralytics import YOLO
model = YOLO('yolov8n_ocs_FINAL_v6_dynamic.onnx')   # see releases/
r = model.predict('page.jpg', imgsz=1280, conf=0.25)  # >1200px→1280 else 320
```

## Project Documents
- [Mini-SRS](docs/SRS.md) · [Model Card](docs/MODEL_CARD.md)
- [Dataset Card](docs/DATASET_CARD.md) · [Evaluation](docs/EVALUATION.md)
- [Dev Log](docs/DEV_LOG.md) · [AI Usage Log](AI_Log.md)

## Working Method
All changes flow through: Issue → Branch (`type/issue-N-desc`) → Commit → Push →
Pull Request (self-review checklist) → Merge → Issue closed.
Tracked on the GitHub Project board: Backlog → Ready → In Progress → In Review → Done.

## License
MIT