#!/usr/bin/env python3
"""Convert a PNG to a multi-size .ico for Windows executables."""
import argparse
from PIL import Image

SIZES = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]

def make_ico(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    frames = [img.resize(s, Image.LANCZOS) for s in SIZES]
    frames[0].save(output_path, format="ICO", append_images=frames[1:], sizes=SIZES)
    print(f"Created {output_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert PNG to .ico")
    parser.add_argument("input",  nargs="?", default="assets/images/icon.png")
    parser.add_argument("output", nargs="?", default="assets/images/icon.ico")
    args = parser.parse_args()
    make_ico(args.input, args.output)
