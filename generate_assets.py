#!/usr/bin/env python3
"""Generate solid-color rectangle PNGs for luagame sprites."""
from PIL import Image, ImageDraw
import os

os.makedirs("assets", exist_ok=True)

MARKER = [(85, 30), (85, 60), (115, 45)]  # right-pointing triangle, head area

def rect(path, w, h, r, g, b, a=255):
    img = Image.new("RGBA", (w, h), (int(r*255), int(g*255), int(b*255), a))
    img.save(f"assets/{path}")
    print(f"  {path}")

def rect_faced(path, w, h, r, g, b, a=255):
    img = Image.new("RGBA", (w, h), (int(r*255), int(g*255), int(b*255), a))
    ImageDraw.Draw(img).polygon(MARKER, fill=(20, 20, 20, 255))
    img.save(f"assets/{path}")
    print(f"  {path}")

# ── Player (120×240) – fixed colors baked in ──────────────────
rect_faced("player_idle.png",      120, 240, 0.30, 0.55, 1.00)
rect_faced("player_walk.png",      120, 240, 0.20, 0.45, 0.90)
rect_faced("player_idle_held.png", 120, 240, 0.30, 0.75, 0.55)
rect_faced("player_walk_held.png", 120, 240, 0.20, 0.65, 0.45)

# ── Customer (white – body_color tint stays dynamic) ──────────
rect_faced("customer.png",        120, 240, 1, 1, 1)
rect("customer_bubble.png",        60,  60, 1, 1, 1)   # tinted to plant colors[3]

# ── Plants (white – colors from plant_data tint stays) ────────
rect("plant_bubble.png", 60, 60, 1, 1, 1)         # tinted yellow
for pt in range(1, 7):
    for stage in range(1, 4):
        rect(f"plant_{pt}_{stage}.png", 120, 120, 1, 1, 1)

# ── Items (120×120) – fixed colors baked in ───────────────────
rect("watering_can.png",   120, 120, 0.30, 0.60, 1.00)
rect("grafter_empty.png",  120, 120, 1.00, 0.50, 0.00)
rect("grafter_loaded.png", 120, 120, 1.00, 0.90, 0.00)
rect("garbage_bin.png",    120, 120, 0.90, 0.20, 0.20)
rect("pc_store.png",       120, 120, 0.70, 0.75, 0.90)

# ── Slot (120×200) – baked border color ───────────────────────
rect("slot.png", 200, 200, 0.35, 0.28, 0.20)

# ── Cashier wall (400×800, transparent window y:340-500) ──────
img = Image.new("RGBA", (400, 800), (0, 0, 0, 0))
wall = (int(0.32*255), int(0.22*255), int(0.38*255), 255)
d = ImageDraw.Draw(img)
d.rectangle([0,   0, 400, 287], fill=wall)
d.rectangle([0, 500, 400, 800], fill=wall)
img.save("assets/cashier_wall.png")
print("  cashier_wall.png")

print("\nDone.")
