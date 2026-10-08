# -*- coding: utf-8 -*-
"""Sinh bộ icon tranh màu nước bằng API ảnh của OpenAI (gpt-image-1) rồi lưu vào app/assets/art.

Cách dùng (PowerShell):
    $env:OPENAI_API_KEY = "khoá của bạn"      # đặt trên máy bạn, đừng gửi qua chat
    python design\\tool\\gen_icons.py              # sinh các icon còn thiếu
    python design\\tool\\gen_icons.py --only thermometer --force
Không có thư viện ngoài ngoại trừ Pillow (đã có) để thu nhỏ ảnh.
"""
import argparse
import base64
import io
import json
import os
import sys
import urllib.request

from PIL import Image

STYLE = (
    "Cute soft watercolor illustration icon for a baby-care app, pastel pink, peach and cream palette, "
    "gentle thin outlines, soft highlights, single object centered, plain transparent background, no text, "
    "no shadow, children's picture-book style, consistent with a mother-and-baby watercolor set. Object: "
)

ICONS = {
    'thermometer': 'a baby digital thermometer, white and pink',
    'medicine': 'a small medicine bottle with a dosing syringe, pastel',
    'note': 'a small notebook with a pencil and a tiny heart',
    'vaccine': 'a cute syringe with a small bandage and heart',
    'growth': 'a baby scale with a soft measuring tape',
    'solids': 'a baby bowl with a spoon and little carrot and pumpkin',
    'book': 'an open picture book with a small bookmark heart',
    'health': 'a stethoscope forming a heart',
    'mind': 'a lotus flower with a tiny heart',
    'noise': 'a crescent moon with soft sound waves and a music note',
    'family': 'three simple round figures (mom, dad, baby) holding hands with hearts',
    'clock': 'a soft round alarm clock with a pink bow',
    'wonder': 'a bright star with little sparkles and a tiny rocket',
    'wallet': 'a coin purse with a few coins',
    'fund': 'a pink piggy bank with a coin',
    'fridge': 'a small fridge holding two milk bottles',
    'star': 'a golden star crown',
    'settings': 'a gear with a small heart in the middle',
}

OUT = os.path.join(os.path.dirname(__file__), '..', '..', 'app', 'assets', 'art')


def generate(key, name):
    body = json.dumps({
        'model': 'gpt-image-1',
        'prompt': STYLE + ICONS[name],
        'size': '1024x1024',
        'background': 'transparent',
        'output_format': 'png',
        'n': 1,
    }).encode()
    req = urllib.request.Request(
        'https://api.openai.com/v1/images/generations',
        data=body,
        headers={'Content-Type': 'application/json', 'Authorization': 'Bearer ' + key},
    )
    with urllib.request.urlopen(req, timeout=180) as r:
        data = json.loads(r.read())
    raw = base64.b64decode(data['data'][0]['b64_json'])
    im = Image.open(io.BytesIO(raw)).convert('RGBA')
    bbox = im.getchannel('A').point(lambda v: 255 if v > 8 else 0).getbbox()
    if bbox:
        im = im.crop(bbox)
    side = max(im.size)
    canvas = Image.new('RGBA', (side, side), (0, 0, 0, 0))
    canvas.paste(im, ((side - im.width) // 2, (side - im.height) // 2))
    canvas = canvas.resize((320, 320), Image.LANCZOS)
    path = os.path.join(OUT, 'ic_%s.png' % name)
    canvas.save(path, optimize=True)
    return path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--only', help='chỉ sinh một icon, ví dụ thermometer')
    ap.add_argument('--force', action='store_true', help='ghi đè tệp đã có')
    a = ap.parse_args()
    key = os.environ.get('OPENAI_API_KEY')
    if not key:
        sys.exit('Chưa đặt biến môi trường OPENAI_API_KEY.')
    names = [a.only] if a.only else list(ICONS)
    for n in names:
        if n not in ICONS:
            print('Không có icon tên', n)
            continue
        target = os.path.join(OUT, 'ic_%s.png' % n)
        if os.path.exists(target) and not a.force:
            print('bỏ qua (đã có):', n)
            continue
        try:
            print('đã tạo', generate(key, n))
        except Exception as e:  # noqa: BLE001
            print('lỗi', n, e)


if __name__ == '__main__':
    main()
