"""
PyTorch vs ONNX Parity Check
=============================
Issue #6: Verifies that the exported ONNX model produces detections
within ±2 boxes of the PyTorch baseline on both crop and full-page samples.

Usage:
    python training/parity_check.py --weights model.pt --onnx model.onnx --samples img1.jpg img2.jpg
"""

import argparse
import sys
from pathlib import Path
from ultralytics import YOLO


def count_detections(results):
    """عدّ عدد الصناديق المكتشفة بعد تطبيق NMS."""
    if hasattr(results, 'boxes') and results.boxes is not None:
        return len(results.boxes)
    return 0


def run_parity_check(pt_model, onnx_model, image_path, imgsz, conf=0.25):
    """قارن نتائج PyTorch و ONNX على صورة واحدة باستخدام نفس المحرك."""
    
    # 1) PyTorch inference (يطبق NMS تلقائياً)
    pt_results = pt_model.predict(
        source=str(image_path),
        imgsz=imgsz,
        conf=conf,
        verbose=False,
        device='cpu'  # لضمان التكافؤ مع ONNX CPU
    )
    pt_count = count_detections(pt_results[0])

    # 2) ONNX inference (Ultralytics تطبق NMS تلقائياً هنا أيضاً)
    onnx_results = onnx_model.predict(
        source=str(image_path),
        imgsz=imgsz,
        conf=conf,
        verbose=False,
        device='cpu'
    )
    onnx_count = count_detections(onnx_results[0])

    # 3) حساب الفرق
    diff = abs(pt_count - onnx_count)
    status = "✅ PASS" if diff <= 2 else "❌ FAIL"

    return pt_count, onnx_count, diff, status


def main():
    parser = argparse.ArgumentParser(description="PyTorch vs ONNX Parity Check")
    parser.add_argument('--weights', type=str, required=True, help='PyTorch weights path (.pt)')
    parser.add_argument('--onnx', type=str, required=True, help='ONNX model path (.onnx)')
    parser.add_argument('--samples', type=str, nargs='+', required=True, help='Sample image paths')
    parser.add_argument('--imgsz', type=int, nargs='+', default=[320, 1280], help='Image sizes to test')
    parser.add_argument('--conf', type=float, default=0.25, help='Confidence threshold')
    args = parser.parse_args()

    print("=" * 70)
    print("🔍 PyTorch vs ONNX Parity Check (Issue #6)")
    print("=" * 70)

    # تحميل النماذج (Ultralytics تدعم تحميل ONNX مباشرة!)
    print("Loading models...")
    pt_model = YOLO(args.weights)
    onnx_model = YOLO(args.onnx)  # ✅ تحميل ONNX ومعالجة NMS تلقائياً

    print(f"PyTorch model: {args.weights}")
    print(f"ONNX model   : {args.onnx}")
    print(f"Image sizes  : {args.imgsz}")
    print(f"Test samples : {len(args.samples)}")
    print(f"Confidence   : {args.conf}")
    print("-" * 70)

    total_tests = 0
    passed_tests = 0

    for imgsz in args.imgsz:
        print(f"\n📏 Testing imgsz={imgsz}")
        print("-" * 50)
        for sample in args.samples:
            sample_path = Path(sample)
            if not sample_path.exists():
                print(f"  ⚠️ Sample not found: {sample}")
                continue

            pt_count, onnx_count, diff, status = run_parity_check(
                pt_model, onnx_model, sample_path, imgsz, conf=args.conf
            )
            total_tests += 1
            if diff <= 2:
                passed_tests += 1

            print(f"  {sample_path.name:<30} | PT: {pt_count:3d} | ONNX: {onnx_count:3d} | Diff: {diff:2d} | {status}")

    print("\n" + "=" * 70)
    print(f"📊 Results: {passed_tests}/{total_tests} tests passed")
    pass_rate = (passed_tests / max(total_tests, 1)) * 100
    print(f"   Pass rate: {pass_rate:.1f}%")
    print(f"   Acceptance criterion: ±2 boxes")
    
    if pass_rate >= 90:
        print("   ✅ PARITY CHECK PASSED")
    else:
        print("   ⚠️ PARITY CHECK NEEDS REVIEW")
    print("=" * 70)


if __name__ == '__main__':
    # ✅ للتشغيل المباشر في Colab (احذف أو علّق هذا الجزء عند الاستخدام كـ script)
    # sys.argv = [
    #     'parity_check.py',
    #     '--weights', '/content/drive/MyDrive/OCS_Project_MultiLine/models/yolov8n_ocs_FINAL_v6.pt',
    #     '--onnx', '/content/drive/MyDrive/OCS_Project_MultiLine/models/yolov8n_ocs_FINAL_v6.onnx',
    #     '--samples', '/content/drive/MyDrive/Annotation 2026-10-01 025543.png',
    #     '--imgsz', '320', '1280',
    #     '--conf', '0.25'
    # ]
    main()