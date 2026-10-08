import sys, os
from PIL import Image
OUT=r'F:\Project Ai\GinBaby\app\assets\art'
names=sys.argv[2:]
S=200
sheet=Image.new('RGB',(S*len(names),S*2),(0,0,0))
for i,n in enumerate(names):
    im=Image.open(os.path.join(OUT,n+'.png')).convert('RGBA').resize((S,S))
    for j,bg in enumerate([(253,246,240),(58,48,64)]):
        c=Image.new('RGBA',(S,S),bg+(255,)); c.alpha_composite(im); sheet.paste(c.convert('RGB'),(i*S,j*S))
sheet.save(sys.argv[1])
