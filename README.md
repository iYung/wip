# Frobert Grows Plants With Increasing Speed and Quantity For Profit

A side-scrolling plant shop game made with [LÖVE](https://love2d.org/) (Lua).

Tend your shop, grow plants, serve quirky customers, and reinvest the profits into more slots, faster legs, and rarer flowers. Features a cast of returning characters with multi-chapter story arcs.

- **Web (desktop):** [play on itch.io](https://gahei.itch.io/frobert)
- **Download (Mac / Windows):** [itch.io page](https://gahei.itch.io/frobert)

---

## Running Locally

Requires [LÖVE 11.5](https://love2d.org/).

```bash
love .
```

---

## Tests

```bash
# Run all tests headless (no window)
love . --headless

# Run a single test
love . --headless tests/test_basics.lua

# Watch a test in a real window
love . --visual tests/test_basics.lua
```

Tests exit with code 0 (pass) or 1 (fail). CI runs `love . --headless` on every push and PR.

---

## Releasing

### One-shot build

Builds all three targets (web, Mac, Windows) in sequence:

```bash
bash scripts/build_all.sh
```

Outputs:
- `web/` — HTML5 build
- `dist/frobert-mac.zip` — macOS app bundle
- `dist/frobert-win.zip` — Windows executable + DLLs

LÖVE runtimes are downloaded on first run and cached in `dist/runtimes/` — subsequent builds skip the download.

### Individual builds

```bash
bash scripts/build_web.sh   # → web/
bash scripts/build_mac.sh   # → dist/frobert-mac.zip
bash scripts/build_win.sh   # → dist/frobert-win.zip
```

### Testing the web build locally

```bash
cd web && python3 -m http.server 8000
# open http://localhost:8000
```

### Uploading to itch.io

Requires [butler](https://itch.io/docs/butler/). Install it once:

```bash
# Download the itch.io butler CLI (not the macOS Butler.app from Homebrew)
mkdir -p ~/bin
curl -L -o ~/bin/butler.zip https://broth.itch.zone/butler/darwin-amd64/LATEST/archive/default
cd ~/bin && unzip -o butler.zip && rm butler.zip
# Add ~/bin to PATH in ~/.zshrc if not already there
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
butler login
```

Push all three builds:

```bash
butler push web/                 gahei/frobert:html5
butler push dist/frobert-mac.zip gahei/frobert:mac
butler push dist/frobert-win.zip gahei/frobert:windows
```

Butler is versioned — each push increments the build number on itch.io automatically.

### Icons

Icons are generated from `assets/images/icon.png` by the build scripts automatically. To regenerate manually:

```bash
python3 scripts/make_icns.py   # → assets/images/icon.icns (macOS)
python3 scripts/make_ico.py    # → assets/images/icon.ico  (Windows)
```

Both scripts accept optional positional args: `input.png output_path`.

> **Windows exe icon:** embedding the icon inside the `.exe` requires `rcedit`, which only runs on Windows. The `.ico` is included in the zip alongside the exe.

---

## Architecture

See [architecture.md](architecture.md) for class reference and [coding-notes.md](coding-notes.md) for folder structure, conventions, and data formats.

**Key files:**

| File | Purpose |
|------|---------|
| `main.lua` | Entry point; Love2D callbacks |
| `conf.lua` | Window config |
| `lua/core/` | Engine-level classes (Sprite, Camera, Drawer, Scene) |
| `lua/game/` | Game logic (Player, Store, Items, Sound, Save) |
| `lua/game/scenes/` | StoreScene, BuyScene, StartScene |
| `lua/game/data/` | Plant data, customer scripts, speed/growth tiers |
| `assets/` | Images, sounds, music, shaders |
| `tests/` | Headless test suite |
