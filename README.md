# 📜 Old Church Slavonic OCR System

<p align="center">
  <strong>Bringing Medieval Manuscripts to Life with AI</strong><br>
  <em>End-to-End OCR Pipeline • YOLOv8 • Flutter Ready • SRS-Compliant</em>
</p>

<p align="center">
  <a href="https://github.com/Mulatef-Aldahia/Old-Church-Slavonic-OCR/releases/tag/v1.0.0">
    <img src="https://img.shields.io/badge/📦_Release-v1.0.0-blue?style=for-the-badge&logo=github&logoColor=white" alt="Release">
  </a>
  <a href="docs/EVALUATION.md">
    <img src="https://img.shields.io/badge/📊_mAP50-0.8714-green?style=for-the-badge&logo=python&logoColor=white" alt="mAP50">
  </a>
  <a href="https://github.com/Mulatef-Aldahia/Old-Church-Slavonic-OCR/actions">
    <img src="https://img.shields.io/badge/✅_Build-Passing-brightgreen?style=for-the-badge&logo=github-actions" alt="Build">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/📄_License-MIT-yellow?style=for-the-badge" alt="License">
  </a>
  <a href="https://github.com/Mulatef-Aldahia/Old-Church-Slavonic-OCR/issues?q=is%3Aissue+is%3Aclosed">
    <img src="https://img.shields.io/badge/🎯_Issues-8%2F8%20Done-success?style=for-the-badge&logo=github" alt="Issues">
  </a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/🐍_Python-3.13-3776AB?style=flat-square&logo=python&logoColor=white" alt="Python">
  <img src="https://img.shields.io/badge/🔥_PyTorch-2.11-EE4C2C?style=flat-square&logo=pytorch&logoColor=white" alt="PyTorch">
  <img src="https://img.shields.io/badge/🎯_YOLOv8n-Ultralytics-00A1E0?style=flat-square" alt="YOLOv8">
  <img src="https://img.shields.io/badge/📱_Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/📦_ONNX-1.23-005CED?style=flat-square&logo=onnx" alt="ONNX">
</p>

---

## 🌍 Visitors Zone: Overview & Impact

### ❓ Why This Project?
Medieval **Old Church Slavonic (OCS)** manuscripts, written in the ancient **Ustav (Uncial) script**, are cultural treasures. However, commercial OCR engines (like Tesseract or Google Vision) completely fail to process them due to:
- Touching and overlapping glyphs (ligatures).
- Faded ink, stains, and degraded parchment.
- Complex two-column layouts and titlo marks (diacritics).

**Our Solution:** A specialized, end-to-end AI pipeline that detects, reconstructs, and evaluates OCS text with production-ready accuracy.

### 🔄 How It Works (The Pipeline)

```mermaid
graph LR
    A[📜 Manuscript Image] -->|YOLOv8n Detection| B(📦 Character Boxes)
    B -->|SRS-Compliant Logic| C[📐 Column & Line Builder]
    C -->|Word Segmentation| D[📝 Reconstructed Text]
    D -->|Levenshtein Distance| E[📊 CER Evaluation]
    
    B -.->|ONNX Export| F[📱 Flutter Mobile App]
    
    style A fill:#f9f,stroke:#333,stroke-width:2px
    style E fill:#9f9,stroke:#333,stroke-width:2px
    style F fill:#99f,stroke:#333,stroke-width:2px