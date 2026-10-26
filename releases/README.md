# Releases & Artifacts

This directory contains official release artifacts for the Old Church Slavonic OCR project.

## 📦 Available Releases

### v1.0.0 — Initial Stable Release (2026-10-26)

The first complete release of the OCS OCR pipeline, featuring:

- **Model Weights:** `yolov8n_ocs_FINAL_v6.pt` (PyTorch)
- **ONNX Model:** `yolov8n_ocs_FINAL_v6.onnx` (dynamic input, ~11.8 MB)
- **Class Mapping:** `v6_names.json` (37 OCS characters)
- **Evaluation Results:** `per_class_ap_test.csv`

### Download Links

| Artifact | Format | Size | Source |
|----------|--------|------|--------|
| PyTorch Weights | `.pt` | ~6 MB | [GitHub Release v1.0.0](https://github.com/Mulatef-Aldahia/Old-Church-Slavonic-OCR/releases/tag/v1.0.0) |
| ONNX Model | `.onnx` | ~12 MB | [GitHub Release v1.0.0](https://github.com/Mulatef-Aldahia/Old-Church-Slavonic-OCR/releases/tag/v1.0.0) |
| Class Mapping | `.json` | <1 MB | [GitHub Release v1.0.0](https://github.com/Mulatef-Aldahia/Old-Church-Slavonic-OCR/releases/tag/v1.0.0) |

## 📋 Version History

| Version | Date | Key Changes |
|---------|------|-------------|
| v1.0.0 | 2026-10-26 | Initial stable release with full pipeline |
| v0.6.0 | 2026-10-20 | Fine-tuned v6 on 237 real pages |
| v0.5.0 | 2026-10-15 | Coverage guardrail & synthetic generator |
| v0.3.0 | 2026-10-10 | Pre-trained YOLOv8n on synthetic corpus |

## 🔗 External Archives

- **Zenodo DOI:** *(to be assigned upon publication)*
- **Hugging Face Model Hub:** *(future)*

## 📄 Citation

If you use this project in your research, please cite:

```bibtex
@software{ocs_ocr_2026,
  author = {Aldahia, Mulatef},
  title = {Old Church Slavonic OCR System},
  year = {2026},
  url = {https://github.com/Mulatef-Aldahia/Old-Church-Slavonic-OCR},
  version = {1.0.0}
}