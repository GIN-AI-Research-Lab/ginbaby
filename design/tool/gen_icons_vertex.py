# -*- coding: utf-8 -*-
"""Sinh lại toàn bộ bộ icon màu nước bằng Gemini (Vertex AI), tách nền trắng thành trong suốt rồi ghi vào app/assets/art.

Dùng:  python gen_icons_vertex.py [tên ...]      (không tham số = tất cả; tên không có đuôi .png)
Ảnh thô lưu ở design/icons/raw/<tên>.png, bản cũ được sao lưu ở design/icons/old/ trước lần ghi đầu tiên.
Xác thực bằng tài khoản gcloud đã đăng nhập trên máy, không lưu khoá trong mã.
"""
import concurrent.futures as cf
import os
import shutil
import sys
import time

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

sys.path.insert(0, os.path.dirname(__file__))
from vertex_img import generate  # noqa: E402

ROOT = r'F:\Project Ai\GinBaby'
RAW = os.path.join(ROOT, 'design', 'icons', 'raw')
OLD = os.path.join(ROOT, 'design', 'icons', 'old')
OUT = os.path.join(ROOT, 'app', 'assets', 'art')
os.makedirs(RAW, exist_ok=True)
os.makedirs(OLD, exist_ok=True)

STYLE = (
    "Cute hand-painted watercolor illustration of a single object, to be used as an icon in a baby-care mobile app. Soft pastel palette of pink, peach, cream, lilac and sage, "
    "with a clearly visible warm coral-brown outline of medium thickness, gentle watercolor shading and small white highlights, "
    "colors saturated enough to read at 48 pixels. Exactly ONE object, centered, filling about 75 percent of the frame, "
    "front or three-quarter view, children's picture-book style. Plain pure white background, no shadow, no text, no letters. Do NOT draw any circle, badge, ring, frame, border, or white die-cut sticker outline around the object; the object itself floats directly on the white background. Subject: "
)

ICONS = {
    # công cụ ghi nhanh
    'ic_thermometer': "a slim baby digital thermometer placed diagonally, white body, pink tip, small round display and a tiny heart",
    'ic_medicine': "a small pastel medicine bottle with a dosing syringe leaning against it",
    'ic_note': "a small notebook with a pencil and a tiny heart on the cover",
    # hồ sơ
    'ic_vaccine': "a cute syringe with a small round bandage and a tiny heart",
    'ic_growth': "a cute baby weighing scale with a soft measuring tape curled beside it",
    'ic_solids': "a baby bowl with a spoon and a little carrot and a slice of pumpkin",
    'ic_book': "an open picture book with a small heart bookmark",
    'ic_health': "a stethoscope whose tube forms a heart shape",
    'ic_mind': "a pink lotus flower with a tiny heart above it",
    'ic_noise': "a crescent moon with soft sound waves and a small music note",
    'ic_family': "three simple round-faced figures, mom, dad and a small baby, holding hands with tiny hearts",
    'ic_clock': "a soft round alarm clock with a pink bow",
    'ic_wonder': "a bright golden star with little sparkles and a tiny rocket",
    'ic_wallet': "a small coin purse with a few gold coins",
    'ic_fund': "a pink piggy bank with a gold coin dropping in",
    'ic_fridge': "a small cute fridge with its door open showing two milk bottles",
    'ic_star': "a golden star crown with small jewels",
    'ic_milestone': "a pair of tiny baby footprints with a small golden star and a heart above them",
    'ic_camera': "a cute soft vintage camera with a pink heart on the lens and a small flash",
    'ic_settings': "a gear with a small heart in the middle",
    # ba hoạt động chính
    'ic_pump': "a cute electric breast pump: a soft funnel shield attached to a small milk bottle with a little milk inside, pink details",
    'ic_breast': "a gentle mother cradling and breastfeeding a baby, head and shoulders only, simple and tender",
    'ic_bottle': "a baby milk bottle with a nipple, measuring marks and a little milk inside, a tiny heart on the label",
    'ic_moon': "a sleepy crescent moon with a closed-eyes smiling face, small z z letters and tiny stars",
    # màu phân
    'poop_yellow': "a cute smooth swirl of baby poop in bright yellow, little shine, tiny smiling face",
    'poop_mustard': "a cute smooth swirl of baby poop in mustard yellow-orange, little shine, tiny smiling face",
    'poop_green': "a cute smooth swirl of baby poop in olive green, little shine, tiny smiling face",
    'poop_brown': "a cute smooth swirl of baby poop in rich chocolate brown (hex 7B4A2E), clearly brown not pink, little shine, tiny smiling face",
    'poop_black': "a cute smooth swirl of baby poop in very dark charcoal black-brown, little shine, tiny smiling face",
    'poop_mucus': "a cute swirl of baby poop in pale yellow with glossy translucent mucus strands, tiny smiling face",
    'poop_silver': "a cute smooth swirl of baby poop in pale silver-grey, little shine, tiny smiling face",
    'poop_blood': "a cute smooth swirl of baby poop in brown with a few red streaks, tiny worried face",
    # kết cấu phân
    'tex_liquid': "a large watery puddle of liquid mustard yellow-brown baby stool spreading out with a few droplets around it, a wide flat irregular puddle in warm mustard yellow-brown, the puddle fills most of the frame width",
    'tex_soft': "a soft creamy dollop of baby stool, like smooth peanut butter",
    'tex_chunky': "a chunky lumpy mound of golden-brown baby stool with small seed-like bits, brown and mustard tones only",
    'tex_hard': "five or six small hard round pellets of baby stool in matte dark brown, like rabbit droppings or little brown pebbles, painted only in dark chocolate brown and umber with a simple soft highlight, absolutely no pink, purple, blue or rainbow tints",
    'tex_foam': "a yellow-green frothy foamy baby stool puddle with small bubbles",
    # lượng tã
    'diaper_few': "a clean white baby diaper with one small yellow wet drop and a tiny heart",
    'diaper_mid': "a baby diaper with a medium yellow wet patch and two drops",
    'diaper_lots': "a heavy full baby diaper with a large yellow wet patch and several drops",
    # hút sữa trái, phải
    'pump_left': "a cute breast pump funnel with a small milk bottle, with a small pink heart on the LEFT side of the bottle",
    'pump_right': "a cute breast pump funnel with a small milk bottle, with a small lilac heart on the RIGHT side of the bottle",
}


SCENE_STYLE = (
    "Soft hand-painted watercolor children's picture-book illustration, warm pastel palette of cream, blush pink, peach and sage green, "
    "delicate thin warm-brown outlines, gentle shading, rosy cheeks, tiny floating hearts and small leafy sprigs as decoration. "
    "The whole composition is complete and centered, large, filling about 88 percent of the frame with very small margins. The hair, skin and clothing are painted in color directly up to the outer edge of the figure: absolutely NO white outline, NO white halo, NO sticker border, NO light rim around the hair or clothes, and the clothing is fully drawn to a natural hem (not torn, not faded, not cropped). Plain pure white background, no frame, no border, no text, no letters, no shadow on the ground. Scene: "
)

SCENES = {
    'hero_mom_baby': "a young mother with a brown hair bun and closed eyes smiling, tenderly hugging her sleeping baby, shown from the head to the waist, wearing a plain soft green top whose bottom edge is a clean smooth curve (no ragged, torn or faded hem), a few pink hearts and leafy sprigs around",
    'hero_baby_awake': "a young mother with a brown hair bun, eyes closed, cheek to cheek hugging her baby who is awake with big calm eyes in a cream onesie, head and upper body, pink hearts and leafy sprigs around",
    'hero_pump': "a young mother with a brown hair bun and closed eyes, in a cream cardigan, using a double electric breast pump with two milk bottles filled with milk, upper body, pink hearts and leafy sprigs around",
    'hero_diaper': "a young mother with a brown hair bun gently changing the diaper of her happily laughing baby lying on a soft mat, a small box of wipes and a teddy bear next to them, pink hearts around",
    'baby_sleep': "a cute newborn baby in a lilac onesie sleeping peacefully on a soft pillow, with tiny stars and a small heart, no square background tile, no rectangle",
    'rainbow': "a small pastel rainbow with soft arcs of pink, peach, sage and lilac and two tiny clouds",
}


def cut_white(path_in, path_out, size=384, boost=1.0):
    im = Image.open(path_in).convert('RGB')
    a = np.asarray(im).astype(np.float32)
    # điểm "gần trắng" nối với mép ảnh là nền; vùng trắng bên trong đồ vật được viền bao lại nên được giữ
    dist = 255 - a.min(axis=2)
    bgish = dist < 22
    lab, n = ndimage.label(bgish)
    edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    bg = np.isin(lab, list(edge))
    # Viền trắng/kem do người vẽ thêm sát mép (kiểu nhãn dán) hoặc do khử răng cưa: bóc các điểm sáng, ít màu nằm trong dải 6 điểm ảnh sát nền
    mx, mn = a.max(axis=2), a.min(axis=2)
    sat = (mx - mn) / np.maximum(mx, 1)
    light = (mn > 200) & (sat < 0.20)
    for _ in range(6):
        ring = ndimage.binary_dilation(bg, iterations=1) & ~bg
        bg = bg | (ring & light)
    alpha = np.where(bg, 0.0, 1.0)
    # mép mềm 1 điểm ảnh
    alpha = ndimage.gaussian_filter(alpha, 0.7)
    alpha = np.clip((alpha - 0.30) / 0.70, 0, 1)
    # khử viền: điểm trong suốt một phần lấy màu của điểm đặc gần nhất (không còn lẫn màu trắng của nền)
    solid = alpha > 0.97
    if solid.any():
        _, (iy, ix) = ndimage.distance_transform_edt(~solid, return_indices=True)
        fixed = a[iy, ix]
        a = np.where((alpha < 0.97)[..., None], fixed, a)
    rgba = np.dstack([a, alpha * 255]).astype(np.uint8)
    img = Image.fromarray(rgba, 'RGBA')
    box = img.getchannel('A').point(lambda v: 255 if v > 24 else 0).getbbox()
    if box:
        pad = int(max(box[2] - box[0], box[3] - box[1]) * 0.06)
        l, t, r, b = box
        side = max(r - l, b - t) + 2 * pad
        cx, cy = (l + r) // 2, (t + b) // 2
        canvas = Image.new('RGBA', (side, side), (0, 0, 0, 0))
        canvas.paste(img.crop((l, t, r, b)), (side // 2 - (r - l) // 2, side // 2 - (b - t) // 2))
        img = canvas
    img = img.resize((size, size), Image.LANCZOS)
    if boost != 1.0:
        # icon nhỏ cần đậm hơn: tăng bão hoà và hạ nhẹ độ sáng để nét viền và màu không bị nhạt trên nền hồng
        r, g, b, al = img.split()
        h, sa, v = Image.merge('RGB', (r, g, b)).convert('HSV').split()
        sa = sa.point(lambda x: min(255, int(x * boost)))
        v = v.point(lambda x: int(255 * ((x / 255) ** (1 + (boost - 1) * 0.5))))
        img = Image.merge('HSV', (h, sa, v)).convert('RGB')
        img.putalpha(al)
    img.save(path_out, optimize=True)


def one(name):
    scene = name in SCENES
    prompt = (SCENE_STYLE + SCENES[name]) if scene else (STYLE + ICONS[name])
    raw = os.path.join(RAW, name + '.png')
    for attempt in range(5):
        try:
            data = generate(prompt)
            open(raw, 'wb').write(data)
            break
        except Exception as e:  # noqa: BLE001
            err = str(e)[:200]
            if '429' in err:
                time.sleep(30 * (attempt + 1))  # quota theo phút: chờ rồi thử lại
            if attempt == 4:
                return name, 'ERROR ' + err
    dst = os.path.join(OUT, name + '.png')
    old = os.path.join(OLD, name + '.png')
    if os.path.exists(dst) and not os.path.exists(old):
        shutil.copy2(dst, old)
    cut_white(raw, dst, 768 if scene else 384, 1.0 if scene else 1.3)
    return name, 'ok'


if __name__ == '__main__':
    names = [n for n in list(ICONS) + list(SCENES) if not sys.argv[1:] or n in sys.argv[1:]]
    with cf.ThreadPoolExecutor(1) as ex:
        for n, r in ex.map(one, names):
            print(n, r, flush=True)


def reprocess(names=None):
    # chỉ xử lý lại từ ảnh thô đã có, không gọi API
    for n in list(ICONS) + list(SCENES):
        if names and n not in names:
            continue
        raw = os.path.join(RAW, n + '.png')
        if os.path.exists(raw):
            sc = n in SCENES
            cut_white(raw, os.path.join(OUT, n + '.png'), 768 if sc else 384, 1.0 if sc else 1.3)
