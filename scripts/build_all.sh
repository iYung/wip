#!/usr/bin/env bash
# Build all release targets: web, mac, windows.
# Run from the project root: bash scripts/build_all.sh
set -euo pipefail

cd "$(dirname "$0")/.."

echo "=== Web ==="
bash scripts/build_web.sh

echo ""
echo "=== Mac ==="
bash scripts/build_mac.sh

echo ""
echo "=== Windows ==="
bash scripts/build_win.sh

echo ""
echo "All builds complete."
echo "  web/               → upload to itch.io as HTML5"
echo "  dist/frobert-mac.zip → upload to itch.io as macOS"
echo "  dist/frobert-win.zip → upload to itch.io as Windows"
echo ""
echo "Push to itch.io:"
echo "  butler push web/                 gahei/frobert:html5"
echo "  butler push dist/frobert-mac.zip gahei/frobert:mac"
echo "  butler push dist/frobert-win.zip gahei/frobert:windows"
