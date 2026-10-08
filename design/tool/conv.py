import sys, os
from PIL import Image

src, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
for n in ['7', '8', '9', '10']:
    im = Image.open(os.path.join(src, n + '.webp'))
    print(n, im.size, im.mode)
    im.convert('RGB').save(os.path.join(out, 'ref' + n + '.png'))
