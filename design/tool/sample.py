import os
from PIL import Image

src = r'C:\Users\ADMINI~1\AppData\Local\Temp\claude\C--Users-Administrator-AppData-Roaming-Claude-scratch-workspaces-36c53904-cc1f-49bc-8d61-4c8fc36f346f-017f8003-68a3-4419-a7cb-0134b41e40c1-scratch-2026-10-06-496cbf\4830feb7-fbe8-4e10-98da-26d40cab725c\images'
out = r'F:\Project Ai\GinBaby\design\ref'
for n in ['11', '12', '13', '14']:
    p = os.path.join(out, n + '.webp')
    im = Image.open(p).convert('RGB')
    im.save(os.path.join(out, 'ref%s.png' % n))
    print(n, im.size)


def px(im, x, y, r=4):
    box = im.crop((x - r, y - r, x + r, y + r)).resize((1, 1), Image.BOX)
    c = box.getpixel((0, 0))
    return '#%02X%02X%02X' % c


pts = {
    '11': {'bg_topleft': (110, 160), 'bg_belowcard': (470, 930), 'card_timer': (470, 905), 'side_left_tile': (150, 560), 'side_right_tile': (790, 560),
           'amt_left': (170, 1040), 'amt_right': (430, 1040), 'amt_total': (790, 1040), 'note_row': (400, 1200), 'recent_card': (470, 1290), 'title': (150, 245),
           'btn_pause': (440, 790), 'ring': (470, 500), 'toggle': (790, 965)},
    '12': {'bg': (100, 100), 'chip_all': (150, 470), 'chip_breast': (470, 470), 'chip_pump': (560, 470), 'chip_sleep': (700, 470), 'search': (400, 553), 'card_breast': (600, 710), 'card_pump': (600, 850), 'card_sleep': (600, 1000), 'dot_breast': (219, 698), 'dot_pump': (219, 832), 'dot_sleep': (219, 975), 'tab_active': (381, 1530), 'tabbar': (470, 1600)},
    '13': {'tile_pump': (140, 450), 'tile_breast': (330, 450), 'tile_bottle': (520, 450), 'tile_sleep': (700, 450), 'chart_card': (470, 700), 'delta_chip': (190, 600), 'hl_pink': (130, 1400), 'hl_green': (370, 1400), 'hl_lilac': (600, 1400), 'bar': (240, 880), 'bar_light': (360, 880)},
    '14': {'bg': (100, 700), 'card': (150, 400), 'sel_color': (140, 560), 'unsel_color': (260, 560), 'sel_tex': (140, 740), 'sel_amt': (150, 940), 'unsel_amt': (400, 940), 'normal_bar': (560, 1060), 'save_btn': (200, 1155), 'save_btn_r': (780, 1155), 'recent_row': (700, 1310), 'warn_pill': (700, 1385), 'ok_pill': (700, 1310)},
}
for n, d in pts.items():
    im = Image.open(os.path.join(out, 'ref%s.png' % n))
    print(n, {k: px(im, *v) for k, v in d.items()})
