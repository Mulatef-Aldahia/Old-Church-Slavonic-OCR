!pip install -q ultralytics
import shutil, yaml, torch
from pathlib import Path
from ultralytics import YOLO

assert torch.cuda.is_available(), "❌ فعّل GPU أولًا (Runtime -> Change runtime -> T4)"
print(f"🎮 GPU: {torch.cuda.get_device_name(0)}")

# ============================================
# المسارات
# ============================================
LOCAL_DATA = Path('/content/stage3')       # ✅ البيانات موجودة هنا مسبقاً
RUNS       = Path('/content/runs')         # ✅ حفظ محلي سريع (يتجنب بطء Drive)
DRIVE      = Path('/content/drive/MyDrive/OCS_Project')

# ============================================
# 1) التحقق من البيانات في /content/stage3
# ============================================
assert LOCAL_DATA.exists(), "❌ المجلد /content/stage3 غير موجود!"
n_train = len(list((LOCAL_DATA/'images'/'train').glob('*.jpg')))
n_val   = len(list((LOCAL_DATA/'images'/'val').glob('*.jpg')))
print(f"📊 البيانات في /content/stage3: train={n_train} | val={n_val}")
assert n_train > 0, "❌ لا توجد صور في train!"

# ============================================
# 2) التحقق من data.yaml
# ============================================
yaml_path = LOCAL_DATA / 'data.yaml'
assert yaml_path.exists(), "❌ ملف data.yaml غير موجود!"
with open(yaml_path, encoding='utf-8') as f:
    orig = yaml.safe_load(f)
print(f"✅ data.yaml جاهز: {orig['nc']} فئة")

# ============================================
# 3) تدريب مع استئناف تلقائي (حفظ محلي سريع)
# ============================================
RUNS.mkdir(parents=True, exist_ok=True)
last_pt = RUNS/'gpu_pretrain'/'weights'/'last.pt'

if last_pt.exists():
    print("🔄 استئناف من checkpoint المحلي (last.pt)")
    model = YOLO(str(last_pt))
    results = model.train(resume=True)
else:
    print("🚀 تدريب جديد — الحفظ المحلي كل epoch (سريع وآمن)")
    model = YOLO('yolov8n.pt')
    results = model.train(
        data=str(yaml_path),
        epochs=60, imgsz=640, batch=64, device='0', workers=8,
        lr0=0.01, lrf=0.01, momentum=0.937, weight_decay=0.0005, warmup_epochs=3,
        hsv_h=0.015, hsv_s=0.4, hsv_v=0.3,
        degrees=2.0, translate=0.05, scale=0.3, shear=1.0,
        flipud=0.0, fliplr=0.0, mosaic=0.5, mixup=0.0, copy_paste=0.0,
        patience=15,
        save=True,
        save_period=-1,  # ✅ إلغاء حفظ epoch5, epoch10... لتسريع العملية (last.pt يُحفظ تلقائياً كل epoch)
        rect=True,
        project=str(RUNS), name='gpu_pretrain', exist_ok=True,
        plots=True, verbose=True
    )

# ============================================
# 4) حفظ النهائي في Drive + تقييم (يُنفذ فقط عند اكتمال التدريب)
# ============================================
best_pt = RUNS/'gpu_pretrain'/'weights'/'best.pt'

if best_pt.exists():
    FINAL = DRIVE/'models'
    FINAL.mkdir(parents=True, exist_ok=True)
    final_path = FINAL/'yolov8n_ocs_gpu_pretrained.pt'
    shutil.copy(best_pt, final_path)

    print("\n📊 التقييم النهائي على test set...")
    m = YOLO(str(best_pt)).val(
        data=str(yaml_path),
        imgsz=640,
        batch=32,
        split='test',
        device='0'
    )

    print(f"\n🎯 mAP50={m.box.map50:.4f} | mAP50-95={m.box.map:.4f} | P={m.box.mp:.4f} | R={m.box.mr:.4f}")
    print(f"✅ النموذج النهائي محفوظ في Drive: {final_path}")
else:
    print("⚠️ لم يكتمل التدريب بعد (انقطعت الجلسة قبل النهاية، أعد التشغيل للاستئناف)")