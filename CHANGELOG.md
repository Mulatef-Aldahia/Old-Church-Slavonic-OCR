# Changelog

All notable changes to the Old Church Slavonic OCR project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-10-27

### 🎉 Initial Stable Release

Complete end-to-end OCR pipeline for Old Church Slavonic manuscripts, from training to mobile deployment.

### Added

#### Core Pipeline
- **Issue #1:** Flutter APK with offline ONNX inference support
- **Issue #2:** Synthetic page generator with rotation and noise augmentation
- **Issue #3:** Pre-trained YOLOv8n model on synthetic OCS corpus
- **Issue #4:** Coverage guardrail for augmentation pipeline (silent class drop fix)
- **Issue #5:** Fine-tuned v6 model on 237 manually annotated real manuscript pages
- **Issue #6:** Dynamic ONNX export with PyTorch parity check (±2 boxes tolerance)
- **Issue #7:** SRS-compliant column-aware line/word builder with modular CER evaluation
- **Issue #8:** Comprehensive final documentation and project wrap-up

#### Documentation
- System Requirements Specification (`docs/SRS.md`)
- Detailed Evaluation Report (`docs/EVALUATION.md`)
- Dataset Card (`docs/DATASET_CARD.md`)
- Model Card (`docs/MODEL_CARD.md`)
- Synthetic Generation Guide (`docs/SYNTHETIC_GENERATION.md`)
- Development Log (`docs/DEV_LOG.md`)

#### Evaluation Tools
- Modular CER calculation with semantic accuracy (`evaluation/cer.py`)
- Column-aware text reconstruction (`evaluation/column_builder.py`)
- PyTorch vs ONNX parity check (`training/parity_check.py`)

### Performance Highlights
| Metric | Value |
|--------|-------|
| mAP50 | 0.8714 ✅ |
| Precision | 0.9113 |
| Recall | 0.8613 |
| Inference Speed | ~79 ms/image |
| Training Pages | 237 |
| Character Classes | 37 |

### Changed
- Migrated post-processing scripts to `evaluation/` directory for better separation of concerns
- Improved CER calculation to correctly distinguish between model deletions and hallucinated insertions
- Updated `releases/README.md` with professional artifact documentation

### Removed
- Redundant `evaluation/word_builder.py` (functionality merged into `column_builder.py`)
- Duplicate `evaluation/parity_check.py` (kept `training/parity_check.py`)

### Fixed
- Silent class drop issue in augmentation pipeline
- Dynamic ONNX input compatibility across image sizes (320×320 and 1280×1280)

---

## [Unreleased]

### Planned
- Language model integration for post-OCR text correction
- Support for additional historical handwriting styles
- Web-based interactive demo (Gradio/Streamlit)
- Hugging Face Model Hub publication

---

## Version History Summary

| Version | Date | Milestone |
|---------|------|-----------|
| v1.0.0 | 2026-10-27 | Initial stable release |
| v0.6.0 | 2026-10-20 | Fine-tuned on real corpus |
| v0.5.0 | 2026-10-15 | Coverage guardrail added |
| v0.3.0 | 2026-10-10 | Pre-trained on synthetic data |

---

**Maintained by:** Mulatef Aldahia  
**Repository:** https://github.com/Mulatef-Aldahia/Old-Church-Slavonic-OCR