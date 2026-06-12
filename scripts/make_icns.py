#!/usr/bin/env python3
"""Convert a PNG to .icns for macOS app bundles. Requires macOS (uses iconutil)."""
import argparse
import os
import subprocess
import tempfile
from PIL import Image

SIZES = [16, 32, 128, 256, 512]

def make_icns(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")

    with tempfile.TemporaryDirectory() as tmp:
        iconset = os.path.join(tmp, "icon.iconset")
        os.makedirs(iconset)

        for size in SIZES:
            img.resize((size, size),         Image.LANCZOS).save(os.path.join(iconset, f"icon_{size}x{size}.png"))
            img.resize((size * 2, size * 2), Image.LANCZOS).save(os.path.join(iconset, f"icon_{size}x{size}@2x.png"))

        subprocess.run(["iconutil", "-c", "icns", iconset, "-o", output_path], check=True)

    print(f"Created {output_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert PNG to .icns")
    parser.add_argument("input",  nargs="?", default="assets/images/icon.png")
    parser.add_argument("output", nargs="?", default="assets/images/icon.icns")
    args = parser.parse_args()
    make_icns(args.input, args.output)
