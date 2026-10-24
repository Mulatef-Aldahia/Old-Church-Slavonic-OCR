"""
Fine-tune v6 — OCS Character Detection (Issue #4 integration)
==============================================================
Fine-tunes YOLOv8n on the real OCS corpus (37 classes, ~97.5k boxes)
with a mandatory coverage guardrail that aborts training if any class
is missing from any data split.

Usage:
    python finetune_v6.py --data data/ocs_v6.yaml --epochs 100 --imgsz 1280
"""

# ============================================================
# Issue #4 — Coverage guardrail (MUST be the FIRST import)
# ============================================================
from coverage_guardrail import enforce_coverage

# Abort training immediately if any of the 37 classes is missing.
enforce_coverage('data/labels', list(range(37)))
# ============================================================

from pathlib import Path
from ultralytics import YOLO


# --------------------------- Hyper-parameters ---------------------------
MODEL_NAME   = 'yolov8n_ocs_v6'
DATA_YAML    = 'data/ocs_v6.yaml'
PRETRAINED   = 'runs/pretrain/best.pt'   # من Issue #3 (Pre-train)
EPOCHS       = 100
IMGSZ        = 1280
BATCH        = 16
LR0          = 0.001
WEIGHT_DECAY = 0.0005
FREEZE       = 0          # 0 = train all layers
PATIENCE     = 20
PROJECT      = 'runs/fine-tune'
NAME         = MODEL_NAME


def main() -> None:
    print(f"🚀 Starting fine-tune v6: {MODEL_NAME}")
    print(f"   data     : {DATA_YAML}")
    print(f"   pretrained: {PRETRAINED}")
    print(f"   epochs   : {EPOCHS} | imgsz: {IMGSZ} | batch: {BATCH}")

    model = YOLO(PRETRAINED)

    results = model.train(
        data=DATA_YAML,
        epochs=EPOCHS,
        imgsz=IMGSZ,
        batch=BATCH,
        lr0=LR0,
        weight_decay=WEIGHT_DECAY,
        freeze=FREEZE,
        patience=PATIENCE,
        project=PROJECT,
        name=NAME,
        save=True,
        plots=True,
        device=0,
    )

    print(f"✅ Fine-tune v6 finished. Best weights: {PROJECT}/{NAME}/weights/best.pt")
    print(f"   Final metrics: mAP50={results.results_dict.get('metrics/mAP50(B)', 0):.3f}")


if __name__ == '__main__':
    main()