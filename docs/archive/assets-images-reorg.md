## Assets Images Reorg Checklist

- [x] Task A — `assets/` — `git mv` all PNG files from `assets/` root to `assets/images/`; also `git mv assets/cashier_wall.psd assets/psds/cashier_wall.psd`
- [x] Task B — `lua/game/assets.lua` — replace every `"assets/<name>.png"` path with `"assets/images/<name>.png"`, including the dynamic path in `load_accessory` (line 75) and the two loop-built paths for plants (line 27), heat lamps (line 61), and ads (line 66)
- [x] Task C — `lua/game/scenes/start_scene.lua`, `lua/game/scenes/settings_menu.lua` — update all direct `love.graphics.newImage("assets/...")` calls to use `assets/images/` prefix
- [x] Task D — `architecture.md`, `coding-notes.md`, `progress.md` — update every inline reference to `assets/<name>.png` paths to use `assets/images/<name>.png`
