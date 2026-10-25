"""
Export fine-tuned model to ONNX for offline inference
======================================================
Issue #5: Creates portable ONNX model for Flutter app deployment.

The exported model is placed in app/models/ alongside the Flutter app,
ready for offline inference via ONNX Runtime.

Features:
- Dynamic input sizes (supports 320 and 1280)
- Simplified graph for faster inference
- Opset 12 for broad compatibility

Usage:
    python training/export_onnx.py --weights runs/fine-tune/v6_real_corpus/weights/best.pt
"""

import argparse
from pathlib import Path
from ultralytics import YOLO


def main():
    parser = argparse.ArgumentParser(description="Export model to ONNX")
    parser.add_argument('--weights', type=str, 
                        default='runs/fine-tune/v6_real_corpus/weights/best.pt',
                        help='Path to trained weights')
    parser.add_argument('--output', type=str, 
                        default='app/models/oko_model.onnx',  # ✅ مسار Flutter
                        help='Output ONNX path (default: app/models/oko_model.onnx)')
    parser.add_argument('--imgsz', type=int, default=1280, 
                        help='Image size (default: 1280)')
    args = parser.parse_args()

    weights_path = Path(args.weights)
    if not weights_path.exists():
        print(f"⚠️ Weights file not found: {weights_path}")
        print("   Please train the model first using finetune_v6.py")
        return

    print("=" * 70)
    print("📦 Exporting model to ONNX for Flutter app")
    print("=" * 70)
    print(f"   Weights: {weights_path}")
    print(f"   Output : {args.output}")
    print(f"   ImgSz  : {args.imgsz}")
    print("-" * 70)

    model = YOLO(str(weights_path))

    # YOLO يحفظ ONNX تلقائياً بجانب ملف الأوزان
    model.export(
        format='onnx',
        imgsz=args.imgsz,
        dynamic=True,      # ✅ Dynamic input sizes (320 و 1280)
        simplify=True,     # ✅ Simplified graph
        opset=12           # ✅ Broad compatibility
    )

    # نقل الملف إلى مجلد Flutter app
    auto_path = weights_path.with_suffix('.onnx')
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    if auto_path.exists():
        if auto_path != output_path:
            auto_path.rename(output_path)
        print(f"✅ ONNX model saved to: {output_path}")
        print(f"   Size: {output_path.stat().st_size / 1024 / 1024:.2f} MB")
        print(f"   Ready for Flutter app in app/models/")
    else:
        print(f"⚠️ ONNX file not found at expected location")

    # ✅ إنشاء ملف v6_names.json تلقائياً (أسماء الفئات)
    try:
        from class_mapping import OCS_CLASS_LIST
        names_json = output_path.parent / 'v6_names.json'
        import json
        with open(names_json, 'w', encoding='utf-8') as f:
            json.dump({str(i): ch for i, ch in enumerate(OCS_CLASS_LIST)}, 
                      f, ensure_ascii=False, indent=2)
        print(f"✅ Class names saved to: {names_json}")
    except Exception as e:
        print(f"⚠️ Could not generate names JSON: {e}")

    print("=" * 70)


if __name__ == '__main__':
    main()