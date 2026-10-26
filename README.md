# Old Church Slavonic OCR 📜
![Version](https://img.shields.io/badge/version-1.0.0-blue)
![mAP50](https://img.shields.io/badge/mAP50-0.8714-green)
![License](https://img.shields.io/badge/license-MIT-yellow)

Character-level detection and OCR for Old Church Slavonic (OCS) manuscripts written in **Ustav (Uncial) script**, built with YOLOv8n and deployed as an offline Flutter APK, a dynamic ONNX model, and a Gradio web demo.

## Brief Description
Medieval OCS manuscripts cannot be processed by commercial OCR: touching glyphs, faded ink, stains, titlo marks, and two-column layouts break modern engines. This project detects each character as a bounding box (37 classes), reconstructs columns → lines → words using adaptive SRS-compliant algorithms, and reports Character Error Rate (CER) against manual references.

## Team
- **Mulatef Aldahia** — sole developer (requirements, annotation, training, deployment, docs)

## Expected Technologies
- Python, PyTorch, Ultralytics YOLOv8n
- ONNX Runtime (dynamic input), Gradio
- Flutter / Dart (Android APK)
- Git, GitHub (Issues, Projects, PRs)

## Results (held-out test, 22 pages / 8,982 boxes)
| Metric | Value |
|---|---|
| mAP50 (37 classes) | **0.8714** ✅ |
| mAP50-95 | 0.8167 |
| Precision / Recall | 0.9113 / 0.8613 |
| Mean AP50, 35 learnable classes | 0.908 |
| ONNX↔PyTorch parity | Verified (±0 boxes tolerance) |

## Pipeline
```text
Synthetic pages (KlimentStd/Menaion fonts, rotation+noise+ink-bleed)
        → Pre-train → Class mapping → Fine-tune (237 pages, ~97.5k boxes)
        → Coverage guardrail → Export dynamic ONNX → Flutter APK / Gradio
        → Column-aware reconstruction & CER evaluation