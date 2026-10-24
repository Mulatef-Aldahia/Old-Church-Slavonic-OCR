import os, random, shutil, yaml, time
import numpy as np
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance
from collections import Counter
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
from concurrent.futures import ProcessPoolExecutor, as_completed

random.seed(42); np.random.seed(42)

DRIVE_ROOT = Path('/content/drive/MyDrive/OCS_Project')
FONTS_DIR  = DRIVE_ROOT / 'fonts'
LOCAL_OUT  = Path('/content/stage3')

# ============================================
# Corpus بالصغيرة فقط (مطابق للمخطوطة الحقيقية)
# ============================================
CORPUS_LINES = [
    "Въ началѣ бѣ Слово и Слово бѣ у Бога и Богъ бѣ Слово",
    "Сей бѣ искони у Бога",
    "Вся тѣмъ быша и безъ него ничтоже бысть еже бысть",
    "Въ томъ животъ бѣ и животъ бѣ свѣтъ человкомъ",
    "и свѣтъ въ тьмѣ свѣтитъ ся и тьма его не объятъ",
    "Бысть человѣкъ посланъ отъ Бога имя ему Іоаннъ",
    "Сей приде во свѣдѣтельство да свѣдѣтельствуетъ о свѣтѣ",
    "да вьси вѣрують ему",
    "Не бѣ той свѣтъ нъ да свѣдѣтельствуетъ о свѣтѣ",
    "Бѣ свѣтъ истиньныи иже просвѣщаеть всѣка человка",
    "грядуща въ миръ",
    "Въ мирѣ бѣ и миръ тѣмъ бысть и миръ его не позна",
    "Въ своѣ приде и свои его не прияша",
    "елици же прияша его дасть имъ область чадамъ Божиимъ быти",
    "вѣрующимъ во имя его",
    "Книга родства Ісуса Христа сына Давыдова сына Авраамля",
    "Авраамъ роди Ісаака", "Ісаакъ же роди Іакова",
    "Іаковъ же роди Іуду и братію его",
    "Іуда же роди Фареса и Зару отъ Ѳамары",
    "Фаресъ же роди Есрома", "Есромъ же роди Арама",
    "Арамъ же роди Аминадава", "Аминадавъ же роди Наассона",
    "Наассонъ же роди Салмона",
    "Отче нашъ иже еси на небесѣхъ", "да свѣтитъ ся имя твое",
    "да приидеть цѣсарьствіе твое",
    "да будетъ воля твоя яко на небеси и на земли",
    "хлѣбъ нашъ насущьныи даждь намъ дьньсь",
    "и отъпусти намъ дългы наша",
    "яко и мы отпущааемъ должьникомъ нашим",
    "и не введи насъ въ напасть", "нъ избави насъ отъ лукаваго",
    "яко твое есть цѣсарьство и сила и слава",
    "въ вѣкы вѣкомъ аминь",
    "Блаженъ мужъ иже не иде на совѣтъ нечестивых",
    "и на пути грѣшьныхъ не ста", "и на сѣдалищи губителѣмъ не сѣде",
    "нъ въ законѣ Господни воля его",
    "и въ законѣ его поучитъ ся день и нощь",
    "И будетъ яко древо насажденое при исходищихъ водъ",
    "еже плодъ свой даетъ во время свое", "и листъ его не отпадеть",
    "и вся елика аще творитъ оуспѣеть",
    "Не тако нечестивіи не тако",
    "нъ яко прахъ егоже отъметаеть вѣтръ отъ лица земли",
    "Господи помилуй", "Христе помилуй",
    "Слава Отцу и Сыну и Святому Духу",
    "и нынѣ и присно и въ вѣкы вѣкомъ", "Аминь",
    "Пріидите поклонимъ ся цареви нашему Богу",
    "Пріидите поклонимъ ся и припадемъ Христу",
    "цареви нашему Богу",
    "Пріидите поклонимъ ся и припадемъ самому Христу",
    "цареви и Богу нашему",
    "Въ время оно рече Ісусъ ученикомъ своимъ",
    "Азъ есмь пастырь добрый", "Пастырь добрый душу свою кладетъ за овцѣ",
    "А наемьникъ иже не пастырь овцамъ",
    "Видитъ волка грядуща и оставляетъ овцѣ и бѣжитъ",
    "И волкъ расхититъ овцѣ",
    "Свѣте тихій святыя славы", "безсмертнаго Отца небеснаго",
    "святаго блаженаго Ісусе Христе", "пришедше на западъ солнца",
    "видѣвше свѣтъ вечерній", "поимъ Отца Сына и Святаго Духа Бога",
    "И видѣвъ Ісусъ народы многы", "възыде на гору",
    "и сѣдшу ему приступиша къ нему ученици его",
    "И отверзъ уста своя", "учаше ихъ глаголя",
    "Блажени нищіи духомъ", "яко тѣхъ есть цѣсарьствіе небесное",
    "Блажени плачущіи", "яко тіи утѣшени будутъ",
    "Блажени кротцыи", "яко тіи наслѣдятъ землю",
    "Блажени алчущіи и жаждущіи правды", "яко тіи насытятся",
    "Въ началѣ сотвори Богъ небо и землю",
    "Земля же бѣ невидима и неустроена", "и тьма верху бездны",
    "и Духъ Божій ношашеся верху воды",
    "И рече Богъ да будетъ свѣтъ", "И бысть свѣтъ",
    "И видѣ Богъ свѣтъ яко добро", "и разлучи Богъ между свѣтомъ и тьмою",
    "И нарече Богъ свѣтъ день", "и тьму нарече нощь",
    "И бысть вечеръ и бысть утро", "день единъ",
    "Боже свѣтъ и творче свѣта", "просвѣти очи мои умныя",
    "да не усну въ смерть", "да не речетъ врагъ мой", "одолѣхъ ему",
    "Воскресение Христово видѣвше", "поклонимъ ся святому Господу Ісусу",
    "единому безгрѣшному",
    "Твоему кресту покланяемся Христе",
    "и святое воскресение твое поимъ и славимъ",
]

def is_ocs_char(ch):
    cp = ord(ch)
    return (0x0400 <= cp <= 0x04FF) or (0xA640 <= cp <= 0xA69F) or \
           (0x2C80 <= cp <= 0x2CFF) or (0x2DE0 <= cp <= 0x2DFF)

# ✅ تحويل Corpus كله للصغيرة
CLEAN_CORPUS = []
for line in CORPUS_LINES:
    clean = ''.join(ch for ch in line if is_ocs_char(ch) or ch == ' ')
    clean = ' '.join(clean.split()).lower()
    if len(clean) >= 5:
        CLEAN_CORPUS.append(clean)

OCS_EXTRA_CHARS = list("ѣѫѧѩѭѡѿѯѱѳѵꙗꙋїі")

chars = set(ch for line in CLEAN_CORPUS for ch in line if ch != ' ')
chars.update(OCS_EXTRA_CHARS)

ALPHABET = [' '] + sorted(chars)
CHAR2ID  = {ch: i for i, ch in enumerate(ALPHABET)}

print(f"✅ عدد الفئات (صغيرة فقط، مع المسافة): {len(ALPHABET)}")
print(f"✅ لا حروف كبيرة: {not any(c.isupper() for c in ALPHABET)}")
print(f"✅ أسطر Corpus: {len(CLEAN_CORPUS)}")
print(f"\nالأبجدية:\n{''.join(ALPHABET)}")

# ============================================
# الخطوط + الأوزان
# ============================================
weights_map = {
    'KlimentStd.ttf':      .60,
    'MenaionRegular.ttf':  .40,
}

font_paths, font_weights = [], []
for f, w in weights_map.items():
    p = FONTS_DIR / f
    if p.exists():
        font_paths.append(p)
        font_weights.append(w)
        print(f"  ✅ {f} (وزن {w:.2f})")
    else:
        print(f"  ❌ {f} غير موجود")

assert len(font_paths) > 0, "❌ لا توجد خطوط صالحة في مجلد fonts!"

# ============================================
# الخلفيات
# ============================================
bg_files = sorted((DRIVE_ROOT/'backgrounds').glob('*.jpg'))
BG_COLORS = [(245,235,220),(235,225,210),(225,215,200),(240,230,215),(250,243,230)]
print(f"✅ الخلفيات: {len(bg_files)}")

# ============================================
# دوال التوليد
# ============================================
INK_COLORS = [(95,62,38),(110,75,45),(75,48,28),(130,95,55),(60,40,25)]
FONT_SIZES = [28, 32, 36, 40, 44]
LINES_PER_IMAGE = [2, 3]

TITLO_WORDS = {'богъ','бога','богу','господь','господу','ісусъ','ісусу',
               'христосъ','христу','духъ','святыи','отець','христе'}

def get_char_width(font, ch):
    try:
        return font.getlength(ch)
    except AttributeError:
        bbox = font.getbbox(ch)
        return bbox[2] - bbox[0]

def clean_and_map_text(text):
    def map_char(ch):
        if ch in CHAR2ID:
            return ch
        if ch.lower() in CHAR2ID:
            return ch.lower()
        return None

    mapped = []
    for ch in text:
        if ch == ' ':
            mapped.append(' ')
        else:
            m = map_char(ch)
            if m is None:
                return None
            mapped.append(m)

    text = ' '.join(''.join(mapped).split()).strip()
    if len(text) < 3:
        return None
    return text

def measure_text_width(text, font, spacing):
    total_w = 0
    for ch in text:
        length = get_char_width(font, ch)
        total_w += length * (spacing if ch != ' ' else 1.0)
    return total_w

def apply_distortion(img):
    if random.random() < 0.5:
        img = img.filter(ImageFilter.GaussianBlur(random.uniform(0.3, 1.0)))

    if random.random() < 0.4:
        img = img.filter(ImageFilter.MinFilter(3)) if random.random() < 0.5 else img.filter(ImageFilter.MaxFilter(3))

    if random.random() < 0.5:
        arr = np.array(img).astype(np.float32)
        arr += np.random.normal(0, random.uniform(2, 8), arr.shape)
        img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))

    if random.random() < 0.5:
        img = ImageEnhance.Contrast(img).enhance(random.uniform(0.85, 1.0))

    if random.random() < 0.3:
        ov = Image.new('RGBA', img.size, (0, 0, 0, 0))
        od = ImageDraw.Draw(ov)
        w, h = img.size
        x0, y0, x1, y1 = random.randint(0, w), random.randint(0, h), random.randint(0, w), random.randint(0, h)
        od.ellipse(
            [min(x0, x1), min(y0, y1), max(x0, x1), max(y0, y1)],
            fill=(140, 110, 70, random.randint(30, 80))
        )
        img = Image.alpha_composite(img.convert('RGBA'), ov).convert('RGB')

    return img

def draw_one_line(draw, text, font, x_start, y_start, ink, spacing):
    bboxes = []
    word_boxes = []
    cur = None
    xc = x_start

    for ch in text:
        if ch == ' ':
            if cur:
                word_boxes.append(cur)
                cur = None
            xc += get_char_width(font, ' ')
            continue

        yj = y_start + random.randint(-3, 3)
        bb = draw.textbbox((xc, yj), ch, font=font)

        ink_var = tuple(
            min(255, max(0, int(c * random.uniform(0.85, 1.15))))
            for c in ink
        )

        draw.text((xc, yj), ch, font=font, fill=ink_var)

        if (bb[2] - bb[0]) >= 2 and (bb[3] - bb[1]) >= 2:
            bboxes.append((CHAR2ID[ch], (bb[0]-2, bb[1]-2, bb[2]+2, bb[3]+2)))

        if cur is None:
            cur = [bb[0], bb[1], bb[2], bb[3], ch]
        else:
            cur[1] = min(cur[1], bb[1])
            cur[2] = max(cur[2], bb[2])
            cur[3] = max(cur[3], bb[3])
            cur[4] += ch

        xc += get_char_width(font, ch) * spacing

    if cur:
        word_boxes.append(cur)

    for x0, y0, x1, y1, wtxt in word_boxes:
        if wtxt.lower() in TITLO_WORDS and random.random() < 0.8:
            mx = (x0 + x1) // 2
            ty = max(y0 - 10, 2)
            draw.arc([mx-12, ty-4, mx+12, ty+4], 180, 0, fill=ink, width=2)
            draw.ellipse([mx-2, ty+1, mx+2, ty+5], fill=ink)

    return bboxes

def render_multiline_realistic(texts, font):
    mapped_lines = []
    for text in texts:
        t = clean_and_map_text(text)
        if t is not None:
            mapped_lines.append(t)

    if len(mapped_lines) < 2:
        return None, []

    pad_x = 28
    pad_y = 24
    ascent, descent = font.getmetrics()
    line_h = int(ascent + descent + random.randint(8, 16))
    spacing = random.uniform(1.08, 1.25)

    widths = []
    for line in mapped_lines:
        widths.append(measure_text_width(line, font, spacing))

    W = int(max(widths) + pad_x * 2 + random.randint(10, 40))
    H = int(line_h * len(mapped_lines) + pad_y * 2 + random.randint(5, 20))

    if bg_files:
        bg = Image.open(str(random.choice(bg_files))).convert('RGB')
        if random.random() < 0.5:
            bg = bg.rotate(random.uniform(-3, 3), expand=False)
        img = bg.resize((W, H))
    else:
        img = Image.new('RGB', (W, H), random.choice(BG_COLORS))

    draw = ImageDraw.Draw(img)
    ink = random.choice(INK_COLORS)

    all_bboxes = []
    y = pad_y

    for line in mapped_lines:
        indent = random.randint(0, 18)
        x_start = pad_x + indent

        line_bboxes = draw_one_line(
            draw=draw,
            text=line,
            font=font,
            x_start=x_start,
            y_start=y,
            ink=ink,
            spacing=spacing
        )

        all_bboxes.extend(line_bboxes)
        y += line_h + random.randint(-2, 5)

    if random.random() < 0.6:
        fill = img.getpixel((0, 0))
        if isinstance(fill, tuple) and len(fill) == 4:
            fill = fill[:3]
        img = img.rotate(random.uniform(-1.2, 1.2), expand=False, fillcolor=fill)

    return img, all_bboxes

# ============================================
# ✅ دالة Worker للمعالجة المتوازية
# ============================================
def generate_and_save(idx):
    random.seed(42 + idx)
    np.random.seed(42 + idx)

    fp = random.choices(font_paths, weights=font_weights, k=1)[0]
    font = ImageFont.truetype(str(fp), random.choice(FONT_SIZES))

    n_lines = random.choice(LINES_PER_IMAGE)
    texts = random.choices(CLEAN_CORPUS, k=n_lines)

    img, bboxes = render_multiline_realistic(texts, font)
    if img is None or not bboxes:
        return 0, 0

    img = apply_distortion(img)

    stem = f'real_{idx:06d}'
    img.save(LOCAL_OUT/'images'/f'{stem}.jpg', quality=93)

    W, H = img.size
    lines = []

    for cid, (x0, y0, x1, y1) in bboxes:
        x0 = max(0, min(x0, W-1))
        y0 = max(0, min(y0, H-1))
        x1 = max(0, min(x1, W-1))
        y1 = max(0, min(y1, H-1))

        bw = max(1, x1 - x0)
        bh = max(1, y1 - y0)

        xc_ = min(max(((x0 + x1) / 2) / W, 0), 1)
        yc_ = min(max(((y0 + y1) / 2) / H, 0), 1)
        w_  = min(max(bw / W, 0), 1)
        h_  = min(max(bh / H, 0), 1)

        lines.append(f"{cid} {xc_:.6f} {yc_:.6f} {w_:.6f} {h_:.6f}")

    (LOCAL_OUT/'labels'/f'{stem}.txt').write_text('\n'.join(lines))

    return 1, len(lines)

# ============================================
# حلقة التوليد 30,000 صورة — كل صورة 2 أو 3 أسطر
# ============================================
if LOCAL_OUT.exists():
    shutil.rmtree(LOCAL_OUT)

for sub in ['images', 'labels']:
    (LOCAL_OUT/sub).mkdir(parents=True)

NUM_IMAGES = 30000
stats = {'images': 0, 'boxes': 0, 'skipped': 0}

start_time = time.time()
N_WORKERS = min(8, os.cpu_count() or 2)

print(f"\n🚀 بدء توليد {NUM_IMAGES} صورة متعددة الأسطر باستخدام {N_WORKERS} نوى CPU...")
print("✅ كل صورة ستحتوي عشوائياً على سطرين أو ثلاثة أسطر.")
print("⚠️ ملاحظة: رسم الخطوط TTF عبر PIL يعتمد على CPU، لذلك نستخدم Multiprocessing لأقصى سرعة.")

with ProcessPoolExecutor(max_workers=N_WORKERS) as executor:
    futures = {executor.submit(generate_and_save, i): i for i in range(NUM_IMAGES)}
    done_count = 0

    for future in as_completed(futures):
        success, n_boxes = future.result()

        if success:
            stats['images'] += 1
            stats['boxes'] += n_boxes
        else:
            stats['skipped'] += 1

        done_count += 1

        if done_count % 1000 == 0:
            elapsed = time.time() - start_time
            rate = done_count / max(elapsed, 1e-6)
            eta = (NUM_IMAGES - done_count) / rate / 60
            print(
                f"  ... {done_count}/{NUM_IMAGES} "
                f"({done_count*100/NUM_IMAGES:.1f}%) | "
                f"Rate: {rate:.1f} img/s | ETA: {eta:.1f} min"
            )

print(f"\n✅ تم التوليد: {stats['images']} صورة، {stats['boxes']} BBox (تخطي {stats['skipped']})")
print(f"⏱️ الوقت الإجمالي: {(time.time() - start_time)/60:.1f} دقيقة")

# ============================================
# التقسيم
# ============================================
stems = sorted(p.stem for p in (LOCAL_OUT/'images').glob('*.jpg'))
random.shuffle(stems)

n = len(stems)
ntr = int(n * 0.7)
nva = int(n * 0.15)

splits = {
    'train': stems[:ntr],
    'val': stems[ntr:ntr+nva],
    'test': stems[ntr+nva:]
}

for sp in splits:
    for sub in ['images', 'labels']:
        (LOCAL_OUT/sub/sp).mkdir(parents=True, exist_ok=True)

    for st in splits[sp]:
        for sub, ext in [('images', '.jpg'), ('labels', '.txt')]:
            src = LOCAL_OUT/sub/f'{st}{ext}'
            if src.exists():
                src.rename(LOCAL_OUT/sub/sp/f'{st}{ext}')

print(f"✅ التقسيم: train={len(splits['train'])} | val={len(splits['val'])} | test={len(splits['test'])}")

# ============================================
# data.yaml
# ============================================
data_yaml = {
    'path': str(LOCAL_OUT),
    'train': 'images/train',
    'val': 'images/val',
    'test': 'images/test',
    'nc': len(ALPHABET),
    'names': ALPHABET
}

(LOCAL_OUT/'data.yaml').write_text(
    yaml.dump(data_yaml, allow_unicode=True),
    encoding='utf-8'
)

print("✅ data.yaml محفوظ")

# ============================================
# لا يوجد نسخ إلى Drive
# ============================================
print("✅ تم الاحتفاظ بالبيانات في القرص المحلي فقط (/content/stage3).")
print("⚠️ إذا أُعيد تشغيل Runtime سيتم حذف /content/stage3، لذلك درّب مباشرة بعد التوليد.")

# ============================================
# التحقق البصري
# ============================================
if len(splits['val']) >= 3:
    fig, axes = plt.subplots(3, 1, figsize=(16, 10))

    for ax, st in zip(axes, random.sample(splits['val'], 3)):
        img = Image.open(LOCAL_OUT/'images'/'val'/f'{st}.jpg')
        W, H = img.size
        ax.imshow(img)

        for line in (LOCAL_OUT/'labels'/'val'/f'{st}.txt').read_text().splitlines():
            cid, xc, yc, w, h = map(float, line.split())
            x0 = (xc - w/2) * W
            y0 = (yc - h/2) * H

            ax.add_patch(
                Rectangle(
                    (x0, y0),
                    w * W,
                    h * H,
                    fill=False,
                    edgecolor='lime',
                    lw=1.2
                )
            )

            ax.text(
                x0,
                max(y0 - 2, 0),
                ALPHABET[int(cid)],
                color='red',
                fontsize=7
            )

        ax.axis('off')
        ax.set_title(st)

    plt.tight_layout()
    plt.show()

# ============================================
# الإحصائيات
# ============================================
cnt = Counter()

for sp in splits:
    for lp in (LOCAL_OUT/'labels'/sp).glob('*.txt'):
        for line in lp.read_text().splitlines():
            cnt[int(line.split()[0])] += 1

print(f"✅ إجمالي BBoxes: {sum(cnt.values())}")
print(f"✅ متوسط الأحرف/صورة: {sum(cnt.values())/max(stats['images'],1):.1f}")
print(f"أكثر 5 أحرف: {[(ALPHABET[c], n) for c, n in cnt.most_common(5)]}")
print(f"أقل 5 أحرف: {[(ALPHABET[c], n) for c, n in cnt.most_common()[-5:]]}")