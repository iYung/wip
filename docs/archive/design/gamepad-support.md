## Goal

Add gamepad support so players can use a controller to play the game. Bindings are fixed (not configurable). The HUD and start-screen key hints automatically switch between keyboard labels and gamepad labels depending on which device the player last used.

## Affected files

- `lua/core/input.lua` — gamepad polling, mode tracking, mode-aware `key_for()`
- `main.lua` — gamepad callbacks; mode switching on keyboard vs gamepad events
- `lua/game/scenes/settings_menu.lua` — gamepad navigation in `update()` and `open()`
- `lua/game/scenes/start_scene.lua` — fix key-hint display to use `key_for()` instead of reading `_map` directly
- `lua/headless/stubs.lua` — stub `love.joystick` so tests don't crash

## What changes

### 1. Fixed gamepad mapping (not rebindable)

| Action      | Gamepad input                           |
|-------------|------------------------------------------|
| move_up     | Left stick up (lefty < −0.3) OR D-pad up |
| move_down   | Left stick down (lefty > 0.3) OR D-pad down |
| move_left   | Left stick left (leftx < −0.3) OR D-pad left |
| move_right  | Left stick right (leftx > 0.3) OR D-pad right |
| interact    | A button                                 |
| settings    | Start button (mirrors ESC on keyboard)   |

### 2. Mode tracking in `Input`

Add `_mode` ("keyboard" | "gamepad") and `_joystick` (active Love2D joystick, or nil) fields to `Input`.

- Mode starts as "keyboard".
- Mode switches to "gamepad" when a gamepad button is pressed (`love.gamepadpressed`) or when `update()` detects any axis movement above the deadzone.
- Mode switches back to "keyboard" when any keyboard key is pressed (`love.keypressed`).

### 3. Gamepad polling in `Input:update()`

After the existing keyboard loop, if `_joystick` is set and connected, poll its axes and buttons for the five actions and OR the result into the same `_down`/`_pressed` tables that keyboard already writes. This means **all existing scene code that calls `input:pressed()` or `input:is_down()` gets gamepad support for free** — StoreScene, BuyScene, and StartScene navigation all work without changes beyond the Input class.

### 4. Mode-aware `key_for(action)`

When `_mode == "gamepad"`, return a gamepad label instead of the keyboard key string:

| Action      | Gamepad label |
|-------------|---------------|
| move_up     | `↑`           |
| move_down   | `↓`           |
| move_left   | `←`           |
| move_right  | `→`           |
| interact    | `[A]`         |

All HUD label generation in StoreScene and BuyScene already calls `key_for()`, so their displays automatically switch — no changes needed in those files.

### 5. `main.lua` callbacks

- `love.gamepadpressed(joystick, button)` — sets `input._joystick`, `input._mode = "gamepad"`. If button == "start", toggles the settings menu (same as ESC).
- `love.joystickadded(joystick)` — if `isGamepad()` and no current joystick, sets `input._joystick`.
- `love.joystickremoved(joystick)` — if it was the active joystick, clears `input._joystick` and scans for another connected gamepad.
- `love.keypressed(key)` — add `input._mode = "keyboard"` before existing logic.

### 6. Settings menu gamepad navigation

`SettingsMenu` already holds `self._input`. Add a module-local helper `_joy_nav(input)` that checks the joystick's axes and buttons and returns `{up, down, left, right, confirm, back}` booleans. In `open()` snapshot gamepad state. In each `update()` block that reads keyboard state, OR in the joystick nav values.

- D-pad / left stick → navigate rows
- A → confirm / start capture
- B → back / close subscreen (mirrors ESC)
- Start → close settings menu

The keybind-capture subscreen requires a keyboard key press to assign a binding; this is intentional — gamepad buttons are not rebindable. The player can press B to exit the capture prompt without assigning.

### 7. Start scene key-hint display

Lines 166–179 read `self.input._map` directly to build the key hint text in the bottom-right corner. Replace with `self.input:key_for(action)` calls so the display shows gamepad arrows and `[A]` when a controller is active.

### 8. Headless stubs

Add `love.joystick = { getJoysticks = function() return {} end }` to `lua/headless/stubs.lua` so nothing in `Input:update()` crashes when `love.joystick` is unavailable.

## What stays the same

- All keyboard behavior and feel is identical.
- Keybind rebinding (settings menu) remains keyboard-only.
- All scenes use the same `Input` instance — no new injection points.
- The HUD text format stays the same (e.g. `"↑/↓: SWAP WITH TOMATO"`); only the key tokens change.
- Only one gamepad is supported at a time (the first connected); multi-gamepad is out of scope.
- Web build is unaffected (Love2D gamepad callbacks simply don't fire there).

## Open questions

None — all answered by the user before writing this doc.
