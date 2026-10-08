# -*- coding: utf-8 -*-
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from vertex_img import generate
PROMPT = ("A square mobile app icon, soft hand-painted watercolor style. A large pastel pink heart in the center containing a tiny sleeping baby wrapped in a cream blanket, "
          "small cream and sage leaves around, gentle thin coral-brown outlines. The artwork fills the whole square canvas edge to edge with a smooth blush pink to peach gradient background, "
          "no white border, no rounded corners, no text, no letters, simple and clear enough to read at small sizes.")
out = r'F:\Project Ai\GinBaby\design\icons\raw\appicon.png'
open(out, 'wb').write(generate(PROMPT))
print('saved')
