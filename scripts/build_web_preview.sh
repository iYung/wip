#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

bash scripts/build_web.sh

echo "Copying controls.js into web/..."
cp web-template/controls.js web/controls.js

echo "Injecting controls.js script tag into web/index.html..."
sed -i 's|</body>|<script src="controls.js"></script>\n</body>|' web/index.html

echo "Preview build complete. Output is in web/"
