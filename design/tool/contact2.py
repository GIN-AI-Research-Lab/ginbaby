import sys, os
from PIL import Image, ImageDraw
OUT=r'F:\Project Ai\GinBaby\app\assets\art'
names=sys.argv[2:]
S=170; cols=6
rows=(len(names)+cols-1)//cols
sheet=Image.new('RGB',(S*cols,S*rows),(253,246,240))
d=ImageDraw.Draw(sheet)
for i,n in enumerate(names):
    im=Image.open(os.path.join(OUT,n+'.png')).convert('RGBA'); im.thumbnail((S-10,S-22))
    x,y=(i%cols)*S,(i//cols)*S
    sheet.paste(im,(x+5,y+3),im); d.text((x+4,y+S-14),n,fill=(90,60,60))
sheet.save(sys.argv[1])
