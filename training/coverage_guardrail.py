"""
Coverage Guardrail for OCS Character Detection Pipeline
=======================================================
Issue #4: Fixes silent drop of 16 classes during augmentation remapping.

This module provides a mandatory pre-training check that aborts the pipeline
if any learnable class is missing from any data split (train / val).

Usage (CLI):
    python coverage_guardrail.py --labels data/labels --classes 0 1 2 ... 36

Usage (from finetune_v6.py):
    from coverage_guardrail import enforce_coverage
    enforce_coverage('data/labels', list(range(37)))
"""

from pathlib import Path
from typing import Dict, List, Set


def check_coverage(labels_dir: str, expected_classes: List[int]) -> Dict[str, Set[int]]:
    """
    يتحقق من وجود كل الفئات المتوقعة في كل تقسيم (train / val).

    Args:
        labels_dir: مسار المجلد الذي يحتوي على train/ و val/
        expected_classes: قائمة الفئات المتوقعة (مثل list(range(37)))

    Returns:
        قاموس {اسم_التقسيم: مجموعة_الفئات_المفقودة}
    """
    splits = ['train', 'val']
    missing: Dict[str, Set[int]] = {}

    for split in splits:
        split_dir = Path(labels_dir) / split
        if not split_dir.exists():
            missing[split] = set(expected_classes)
            print(f"⚠️  {split}: المجلد غير موجود → جميع الفئات مفقودة")
            continue

        found: Set[int] = set()
        label_files = list(split_dir.glob('*.txt'))
        if not label_files:
            missing[split] = set(expected_classes)
            print(f"⚠️  {split}: لا توجد ملفات labels")
            continue

        for label_file in label_files:
            with open(label_file, 'r', encoding='utf-8') as f:
                for line in f:
                    parts = line.strip().split()
                    if parts:
                        try:
                            found.add(int(parts[0]))
                        except ValueError:
                            pass

        missing_in_split = set(expected_classes) - found
        if missing_in_split:
            missing[split] = missing_in_split
            print(f"❌ {split}: فئات مفقودة ({len(missing_in_split)}) = {sorted(missing_in_split)}")
        else:
            print(f"✅ {split}: تغطية كاملة ({len(found)} فئة)")

    return missing


def enforce_coverage(labels_dir: str, expected_classes: List[int]) -> None:
    """
    يفرض فحص التغطية ويُجهض التدريب عند اكتشاف أي نقص.
    تُستدعى كـ"أول سطر" في finetune_v6.py قبل أي تدريب.
    """
    print("=" * 60)
    print("🛡️  Coverage Guardrail (Issue #4)")
    print("=" * 60)
    print(f"  Labels dir : {labels_dir}")
    print(f"🔢  Expected   : {len(expected_classes)} classes "
          f"[{min(expected_classes)}..{max(expected_classes)}]")
    print("-" * 60)

    missing = check_coverage(labels_dir, expected_classes)

    print("-" * 60)
    if missing:
        total = sum(len(v) for v in missing.values())
        details = "\n".join(
            f"   • {split}: {sorted(classes)}"
            for split, classes in missing.items()
        )
        raise RuntimeError(
            f"⛔ Coverage guardrail FAILED — {total} missing-class instance(s).\n"
            f"{details}\n\n"
            "Training ABORTED. Fix the augmentation / label-remapping pipeline "
            "before retrying."
        )

    print("✅ Coverage guardrail PASSED — all classes present in all splits.")
    print("=" * 60)


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(
        description='Coverage guardrail for OCS dataset (Issue #4)'
    )
    parser.add_argument('--labels', required=True,
                        help='Path to labels root (must contain train/ and val/)')
    parser.add_argument('--classes', nargs='+', type=int, required=True,
                        help='List of expected class indices, e.g. 0 1 2 ... 36')
    args = parser.parse_args()

    enforce_coverage(args.labels, args.classes)