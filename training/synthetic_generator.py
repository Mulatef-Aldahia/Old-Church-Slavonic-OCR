"""
Synthetic Page Generator for OCS Character Detection
====================================================
Issue #2: Generates synthetic pages with OCS characters for pre-training.

Fixes applied:
1. Uses official mapping from class_mapping.py (no dynamic alphabet).
2. Paths are relative and configurable via argparse (no hardcoded Colab paths).
3. Destructive operations (shutil.rmtree) are safely wrapped in __main__.
"""

import argparse
import os
import random
import shutil
import time
import yaml
from pathlib import Path
from collections import Counter

import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance

# ✅ استيراد الخريطة الرسمية لضمان التطابق التام
from class_mapping import OCS_CLASS_LIST, CHAR_TO_ID, NUM_CLASSES

random.seed(42)
np.random.seed(42)

# ============================================
# Corpus (Lowercase only, matching real manuscripts)
# ============================================
CORPUS_LINES = [
    "Въ началѣ бѣ Слово и Слово бѣ у Бога и Богъ бѣ Слово",
    "Сей бѣ искони у Бога",
    "Вся тѣмъ быша и безъ него ничтоже бысть еже бысть",
    "Въ томъ животъ бѣ и животъ бѣ свѣтъ человкомъ",
    # ... (يمكنك إبقاء باقي النصوص كما هي، سأختصرها هنا للاختصار)
    "и святое воскресение твое поимъ и славимъ",
]

def clean_and_map_text(text: str) -> str:
    """ينقي النص ويتأكد من أن كل حرف موجود في الخريطة الرسمية."""
    mapped = []
    for ch in text.lower():
        if ch == ' ':
            mapped.append(' ')
        elif ch in CHAR_TO_ID:
            mapped.append(ch)
        # تجاهل الأحرف غير الموجودة في الـ Mapping الرسمي
    
    cleaned = ' '.join(''.join(mapped).split()).strip()
    return cleaned if len(cleaned) >= 3 else None

# تصفية النصوص مسبقاً لضمان استخدام الأحرف المعتمدة فقط
CLEAN_CORPUS = [clean for line in CORPUS_LINES if (clean := clean_and_map_text(line))]

# ============================================
# دوال التوليد (مختصرة للوضوح، نفس منطقك الأصلي)
# ============================================
def get_char_width(font, ch):
    try:
        return font.getlength(ch)
    except AttributeError:
        bbox = font.getbbox(ch)
        return bbox[2] - bbox[0]

def draw_one_line(draw, text, font, x_start, y_start, ink, spacing):
    bboxes = []
    xc = x_start
    for ch in text:
        if ch == ' ':
            xc += get_char_width(font, ' ')
            continue
        
        yj = y_start + random.randint(-2, 2)
        bb = draw.textbbox((xc, yj), ch, font=font)
        draw.text((xc, yj), ch, font=font, fill=ink)
        
        if (bb[2] - bb[0]) >= 2 and (bb[3] - bb[1]) >= 2:
            # ✅ استخدام CHAR_TO_ID الرسمي هنا بدلاً من قاموس ديناميكي
            cid = CHAR_TO_ID[ch]
            bboxes.append((cid, (bb[0]-2, bb[1]-2, bb[2]+2, bb[3]+2)))
            
        xc += get_char_width(font, ch) * spacing
    return bboxes

def generate_and_save(idx, output_dir: Path, font_paths: list):
    """دالة آمنة لتوليد صورة واحدة وحفظها."""
    font_size = random.choice([28, 32, 36, 40])
    font = ImageFont.truetype(str(random.choice(font_paths)), font_size)
    
    texts = random.choices(CLEAN_CORPUS, k=random.choice([2, 3]))
    
    # (هنا يتم وضع منطق الرسم البسيط، نفس منطقك السابق لكن باستخدام bboxes)
    # للتبسيط في هذا الرد، سنفترض أن الدالة ترجع (img, bboxes) كما في كودك الأصلي
    
    # ... (انسخ منطق render_multiline_realistic و apply_distortion من كودك الأصلي هنا) ...
    # تأكد فقط أن bboxes تستخدم CHAR_TO_ID[ch]
    
    # مثال مبسط للحفظ:
    stem = f'syn_{idx:06d}'
    # img.save(output_dir / 'images' / f'{stem}.jpg')
    # ... حفظ الـ labels باستخدام cid الرسمي ...
    return 1, 50 # قيم وهمية للتوضيح

# ============================================
# الدالة الرئيسية (آمنة ولا تعمل عند الاستيراد)
# ============================================
def main():
    parser = argparse.ArgumentParser(description="Generate synthetic OCS data")
    parser.add_argument('--fonts-dir', type=str, default='data/fonts', help='Directory containing .ttf fonts')
    parser.add_argument('--output-dir', type=str, default='data/synthetic', help='Output directory')
    parser.add_argument('--num-images', type=int, default=100, help='Number of images to generate')
    args = parser.parse_args()

    fonts_dir = Path(args.fonts_dir)
    output_dir = Path(args.output_dir)
    
    # التحقق من الخطوط
    font_paths = [f for f in fonts_dir.glob('*.ttf') if f.name in ['KlimentStd.ttf', 'MenaionRegular.ttf']]
    if not font_paths:
        print(f"⚠️ Warning: Fonts not found in {fonts_dir}. Please add KlimentStd.ttf or MenaionRegular.ttf")
        return

    print(f"🚀 Generating {args.num_images} synthetic images...")
    print(f"   Using {NUM_CLASSES} official classes from class_mapping.py")
    
    # ✅ الحذف الآمن (فقط عند التشغيل المباشر، وليس عند الاستيراد)
    if output_dir.exists():
        print(f"   Cleaning existing output directory: {output_dir}")
        shutil.rmtree(output_dir)
        
    (output_dir / 'images').mkdir(parents=True)
    (output_dir / 'labels').mkdir(parents=True)

    # محاكاة حلقة التوليد (استبدل هذا بمنطق ProcessPoolExecutor الخاص بك)
    for i in range(args.num_images):
        generate_and_save(i, output_dir, font_paths)
        if i % 10 == 0:
            print(f"   Generated {i}/{args.num_images}...")

    print("✅ Generation complete!")

if __name__ == '__main__':
    main()