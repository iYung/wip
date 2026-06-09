# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

read mds before working
move completed step mds to archive

## Commands

```bash
# Run the game
love .

# Run a single test (headless, no window)
love . --headless tests/test_basics.lua

# Run all tests
love . --headless

# Watch a test play out in a real window
love . --visual tests/test_basics.lua

# Build for web
bash scripts/build_web.sh
```

Tests exit with code 0 (pass) or 1 (fail). CI runs `love . --headless` on every push and PR.

**Never run `generate_assets.py`** — the user has custom art; running it overwrites their PNG files.

## Architecture

This is a Love2D game written in Lua. The full architecture reference is in `architecture.md`; `coding-notes.md` has folder structure, conventions, and data table formats.

**Frame loop:** `main.lua` → `SceneManager` → active `Scene` → `Drawer` (sorted by priority) → `Camera` transform.

**Scenes:** `StartScene` (title) → `StoreScene` (main gameplay) ↔ `BuyScene` (PC store carousel). `SettingsMenu` is a pause overlay, not a Scene subclass.

**SceneManager is not a stack** — `switch(scene)` replaces the current scene outright, no push/pop. `BuyScene` holds a reference to the *same* `StoreScene` instance and calls `scene_manager:switch(self.store_scene)` to return, which re-fires `StoreScene:on_enter()`. Code that re-checks state in `on_enter()` (e.g. music restart, `_bg_playing` guard) therefore runs every time the player exits the buy screen. `StoreScene` uses a `self._initialized` flag to skip one-time setup on these re-entries.

**Shared state:** `GameState` survives scene switches and is passed everywhere. It holds the `Store`, `Player`, `currency`, `unlocked_plants`, `stage3_counts` (quest triggers), `seen_scripts`, and upgrade levels.

**Persistence:** `Save` (`lua/game/save.lua`) serializes `GameState` to `save.dat`. `SettingsState` (`lua/game/settings_state.lua`) manages keybinds, fullscreen, and volume levels; persisted to `settings.dat`. Both files use the same `pcall`-wrapped read pattern to handle missing or corrupt files gracefully.

**Sound music system:** music tracks in `lua/game/sound.lua` carry a `playing_intent` flag that records whether the game wants the track playing, independent of whether the OS currently has the source active. `love.focus` in `main.lua` calls `Sound.on_focus(focused)` which restarts any track with `playing_intent = true` that the OS silently stopped. Use `Sound.play_music` / `Sound.fade_music` / `Sound.stop_music` — never call `entry.src:play()` directly — so `playing_intent` stays accurate.

**Web audio:** audio does not work in the web build. See `docs/web-audio.md` for the full diagnosis and next steps to try. Do not spend time debugging it outside that document's scope.

**Testing:** `lua/headless/stubs.lua` no-ops all Love2D graphics/audio globals so tests run without a window. `HeadlessInput` (`lua/headless/input.lua`) replaces the keyboard. Tests are plain Lua files in `tests/`; `runner.lua` drives them.

**Assets:** All PNGs load once via `lua/game/assets.lua` (require-cached). Use `A = require("lua/game/assets")` then `A.image_name`. Optional assets use `try_img`; required assets use `img()` and must exist.

**Shaders:** GLSL sources in `assets/shaders/`; Lua wrappers in `lua/game/shaders/`. Each wrapper is require-cached and exposes `apply(...) / clear()`. Active shaders: `ColorReplace` (player/customer tinting), `WallPattern` (repeating wall texture), `CRT` (BuyScene post-process), `Sway` (parallax plant sway), `MenuBg` (start screen scrolling pattern).

**Items:** All carriable objects extend `Item` (`lua/game/items/item.lua`). `Plant`, `WateringCan`, `Grafter`, `PCStore`, `GarbageBin`, `Intercom`, `WaterDrone`, `SellBin`.

**Data tables:** `lua/game/data/` — `plant_data.lua`, `customer_scripts.lua`, `speed_tiers.lua`, `growth_tiers.lua`. Customer scripts use `id:chapter` keys in `seen_scripts` for multi-visit character arcs.

## Conventions

- `snake_case` files/variables, `PascalCase` classes, `UPPER_SNAKE_CASE` constants
- One class per file; require paths relative to project root with no leading `./`
- All classes follow the `MyClass.__index = MyClass` / `setmetatable({}, MyClass)` pattern
- Logical resolution: 1280×720; world coordinates sized to feel natural at that resolution
- Grass (plant_type 1) is always pre-unlocked in `GameState.new()` — `unlocked_plants[1] = true`
- PC Store catalogue descriptions: max 2 lines; entries that append dynamic text at draw time must use a 1-line base description
