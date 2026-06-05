## Goal

Move all PNG images from the `assets/` root into `assets/images/`, matching the subfolder convention already used by `music/`, `psds/`, `shaders/`, and `sounds/`. Also move the stray `cashier_wall.psd` from `assets/` root into `assets/psds/` where it belongs.

## Affected files

**Assets moved**
- `assets/*.png` → `assets/images/*.png` (~62 files, including newly added `water_drone.png` / `water_drone2.png`)
- `assets/cashier_wall.psd` → `assets/psds/cashier_wall.psd`

**Code updated**
- `lua/game/assets.lua` — all hardcoded `"assets/<name>.png"` paths, including the dynamic `load_accessory` builder
- `lua/game/scenes/start_scene.lua` — 6 direct `love.graphics.newImage` calls
- `lua/game/scenes/settings_menu.lua` — 4 direct `love.graphics.newImage` calls

**Docs updated**
- `architecture.md` — inline path references to image files
- `coding-notes.md` — `assets/` folder description
- `progress.md` — feature write-ups that cite individual asset paths

## What changes

1. New `assets/images/` subfolder holds all PNG files.
2. `assets/psds/cashier_wall.psd` added (stray PSD moved in).
3. Every `"assets/<name>.png"` string in Lua becomes `"assets/images/<name>.png"`.
4. Markdown docs updated to reflect the new paths.

## What stays the same

- `assets/music/`, `assets/psds/`, `assets/shaders/`, `assets/sounds/` — untouched.
- All Lua asset *names* (the table keys on `A`) — no API changes.
- `scripts/build_web.sh` and `scripts/download_sounds.sh` — neither references PNG paths, so no changes needed.
- `.love` bundle build command (`zip -r game.love ... assets/`) — still packages the whole `assets/` tree, no change.

## Open questions

None.
