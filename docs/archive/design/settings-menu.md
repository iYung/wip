# Settings Menu

## Goal

Pressing Esc during gameplay opens a pause/settings overlay with two buttons: "Fullscreen / Window" (stub — no implementation) and "Leave Game" (quits). The start screen gains a "Settings" button that opens the same overlay. The game pauses while the menu is open.

## Affected files

- `main.lua` — Esc handling, overlay lifecycle (update/draw), game pause logic
- `lua/game/scenes/start_scene.lua` — add "Settings" menu item, pass open-settings callback
- `lua/game/scenes/settings_menu.lua` — new file, the overlay object

## What changes

### `lua/game/scenes/settings_menu.lua` (new)

A plain Lua table (not a Scene subclass — no Camera/Drawer needed). Responsibilities:

- Tracks `is_open`, `selected` index, and a list of items: `{"Fullscreen / Window", "Leave Game"}`.
- Navigation: `up`/`down` arrows (edge-wrap). Confirm: `e` or `f` (matching in-game action keys) or `return`/`space` (matching start-scene confirm keys). Close without action: `escape`.
- `draw()` renders a semi-transparent dimmed background over whatever is on screen, then a centred panel with the two button entries (matching start-scene button art style).
- `update(dt)` reads raw `love.keyboard.isDown` state the same way `start_scene.lua` does (edge-triggered via `_prev_*` flags).
- Selecting "Fullscreen / Window" calls `love.window.setFullscreen(not love.window.getFullscreen())`. The button label reads "Fullscreen" when windowed and "Window" when fullscreen.
- Selecting "Leave Game" calls `love.event.quit()`.

### `main.lua`

- `love.keypressed`: when `key == "escape"`, instead of immediately quitting, check whether the current scene allows Esc-to-settings (see below). If yes, toggle `settings_menu.is_open`. If the menu is already open, close it (Esc = back).
- `love.update`: when `settings_menu.is_open`, call `settings_menu:update(dt)` and skip `scene_manager:update(dt)` (game pauses).
- `love.draw`: after rendering the canvas to screen, if `settings_menu.is_open`, call `settings_menu:draw()` on top (drawn outside the canvas so it always fills the screen at native resolution).

Scenes that allow Esc-to-settings declare `self.esc_opens_settings = true`. `StoreScene` and `BuyScene` get this flag; `StartScene` does not (it has its own Settings button instead).

### `lua/game/scenes/start_scene.lua`

- Add `"Settings"` to the `ITEMS` list (between "Continue" and "Exit").
- `StartScene.new` receives an additional `open_settings` callback (no-arg function).
- In `_confirm()`, selecting "Settings" calls `open_settings()`.
- `main.lua` passes `function() settings_menu:open() end` as the callback.

## What stays the same

- Scene system, SceneManager, all existing scenes and their logic.
- The `core/input.lua` action-map system (settings menu reads raw keyboard directly, same pattern as `start_scene`).
- Fullscreen/window toggle uses `love.window.setFullscreen` — already fully handled by LÖVE.
- All existing Esc behaviour in visual/headless test modes is unchanged (settings menu is only created in normal game mode).

## Open questions

None — all resolved before writing this doc.
- Esc scope: gameplay only; start screen uses a menu button instead. ✓
- Pause while open: yes. ✓
- Navigation: arrow keys + e/f/return/space. ✓
