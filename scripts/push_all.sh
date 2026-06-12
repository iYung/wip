#!/usr/bin/env bash
# Push all release targets to itch.io via butler.
# Run from the project root: bash scripts/push_all.sh
set -euo pipefail

cd "$(dirname "$0")/.."

echo "=== HTML5 ==="
butler push web/ gahei/frobert:html5

echo ""
echo "=== Mac ==="
butler push dist/frobert-mac.zip gahei/frobert:mac

echo ""
echo "=== Windows ==="
butler push dist/frobert-win.zip gahei/frobert:windows

echo ""
echo "All pushes complete."
