"""
Fine-tune v6 — OCS Character Detection (Issue #5)
==============================================================
Fine-tunes YOLOv8n on the real OCS corpus (37 classes, ~97.5k boxes)
using the v6 recipe: AdamW, imgsz=1280, freeze=0.

Includes mandatory coverage guardrail (Issue #4) that aborts training
if any class is missing from any data split.

Usage:
    python training/finetune_v6.py --data data/real_ocs.yaml --epochs 100
"""

# ============================================================
# Issue #4 — Coverage guardrail (MUST be the FIRST import)
# ============================================================
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent))

from coverage_guardrail import enforce_coverage

# Abort training immediately if any of the 37 classes is missing.
enforce_coverage('data/labels', list(range(37)))
# ============================================================

from pathlib import Path
from ultralytics import YOLO
import pandas as pd
from class_mapping import ID_TO_CHAR, NUM_CLASSES


# --------------------------- Hyper-parameters (v6 Recipe) ---------------------------
MODEL_NAME   = 'yolov8n_ocs_v6'
DATA_YAML    = 'data/real_ocs.yaml'          # ✅ مطابق لاسم الملف الفعلي
PRETRAINED   = 'runs/pretrain/synthetic_v8n/weights/best.pt'  # ✅ من Issue #3
EPOCHS       = 100
IMGSZ        = 1280                           # ✅ v6 recipe
BATCH        = 16
LR0          = 0.01                           # ✅ v6 recipe (كان 0.001 - خطأ)
LRF          = 0.01
MOMENTUM     = 0.937
WEIGHT_DECAY = 0.0005
FREEZE       = 0                              # ✅ v6 recipe: train all layers
PATIENCE     = 20
OPTIMIZER    = 'AdamW'                        # ✅ v6 recipe (صريح الآن)
PROJECT      = 'runs/fine-tune'
NAME         = MODEL_NAME


def main() -> None:
    print("=" * 70)
    print(f"🚀 Starting fine-tune v6: {MODEL_NAME}")
    print("=" * 70)
    print(f"   data      : {DATA_YAML}")
    print(f"   pretrained: {PRETRAINED}")
    print(f"   epochs    : {EPOCHS} | imgsz: {IMGSZ} | batch: {BATCH}")
    print(f"   optimizer : {OPTIMIZER} | lr0: {LR0} | freeze: {FREEZE}")
    print("=" * 70)

    # التحقق من وجود ملف البيانات
    if not Path(DATA_YAML).exists():
        print(f"⚠️ Data file not found: {DATA_YAML}")
        print("   Please ensure data/real_ocs.yaml exists with train/val/test splits")
        return

    # تحميل الأوزان المُدربة مسبقاً
    model = YOLO(PRETRAINED)

    # ✅ التدريب بوصفة v6 الدقيقة
    results = model.train(
        data=DATA_YAML,
        epochs=EPOCHS,
        imgsz=IMGSZ,
        batch=BATCH,
        optimizer=OPTIMIZER,        # ✅ AdamW صريح
        lr0=LR0,                    # ✅ 0.01 (v6 recipe)
        lrf=LRF,
        momentum=MOMENTUM,
        weight_decay=WEIGHT_DECAY,
        freeze=FREEZE,              # ✅ 0 = train all layers
        patience=PATIENCE,
        project=PROJECT,
        name=NAME,
        save=True,
        plots=True,
        device=0,
        workers=4,
        verbose=True
    )

    print(f"\n✅ Fine-tune v6 finished.")
    print(f"   Best weights: {PROJECT}/{NAME}/weights/best.pt")
    print(f"   Final metrics: mAP50={results.results_dict.get('metrics/mAP50(B)', 0):.4f}")

    # ✅ التقييم على test split (22 صفحة)
    print("\n" + "=" * 70)
    print("📊 Evaluating on held-out 22-page test split...")
    print("=" * 70)

    val_results = model.val(
        data=DATA_YAML,
        split='test',
        imgsz=IMGSZ,
        batch=BATCH,
        device=0,
        verbose=True
    )

    # ✅ استخراج وحفظ Per-class AP كـ CSV
    print("\n💾 Saving per-class AP results...")
    results_data = []
    for class_id in range(NUM_CLASSES):
        ap50 = float(val_results.box.ap50[class_id]) if class_id < len(val_results.box.ap50) else 0.0
        char = ID_TO_CHAR.get(class_id, '?')
        results_data.append({
            'Class_ID': class_id,
            'Character': char,
            'AP50': round(ap50, 4)
        })

    df = pd.DataFrame(results_data)
    output_csv = Path('results/per_class_ap_test.csv')
    output_csv.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(output_csv, index=False)
    print(f"✅ Saved to {output_csv}")

    # طباعة النتائج النهائية
    print("\n" + "=" * 70)
    print("🎯 Final Results (Test Split)")
    print("=" * 70)
    print(f"mAP50:     {val_results.box.map50:.4f}")
    print(f"mAP50-95:  {val_results.box.map:.4f}")
    print(f"Precision: {val_results.box.mp:.4f}")
    print(f"Recall:    {val_results.box.mr:.4f}")
    print("=" * 70)


if __name__ == '__main__':
    main()