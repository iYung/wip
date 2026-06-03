#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Zipping game files into game.love..."
zip -r game.love main.lua conf.lua lua/ assets/

echo "Running love.js to build web output..."
npx love.js game.love web/ --title "plant game"

echo "Copying controls.js and coi-serviceworker.js into web/..."
cp web-template/controls.js web/controls.js
cp node_modules/coi-serviceworker/coi-serviceworker.js web/coi-serviceworker.js

echo "Injecting coi-serviceworker.js and controls.js script tags into web/index.html..."
sed -i 's|</head>|  <script src="coi-serviceworker.js"></script>\n</head>|' web/index.html
sed -i 's|</body>|<script src="controls.js"></script>\n</body>|' web/index.html

echo "Cleaning up game.love..."
rm game.love

echo "Build complete. Output is in web/"
