#!/usr/bin/env python3
from PIL import Image, ImageDraw

img  = Image.new("RGBA", (400, 800), (0, 0, 0, 0))
wall = (int(0.32*255), int(0.22*255), int(0.38*255), 255)
d    = ImageDraw.Draw(img)
d.rectangle([0,   0, 400, 287], fill=wall)
d.rectangle([0, 500, 400, 800], fill=wall)
img.save("assets/cashier_wall.png")
print("cashier_wall.png")
