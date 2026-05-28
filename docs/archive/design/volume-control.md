# Volume Control

## Goal

Make the master sound volume adjustable from the settings menu. The existing `Sound` module plays all effects at the Love2D default volume (1.0). This feature adds a Volume row to the main settings screen so players can set volume to any multiple of 10% between 0% and 100%.

---

## Affected files

**Modified:**
- `lua/game/settings_state.lua` — add `volume` property and `set_volume()` method
- `lua/game/scenes/settings_menu.lua` — add Volume row (slot 2), left/right input, updated draw
- `lua/headless/stubs.lua` — add `love.audio.setVolume` no-op stub
- `tests/test_settings_state.lua` — tests for new `volume` default and `set_volume`
- `tests/test_settings_menu.lua` — update index-dependent tests; add volume adjustment tests

---

## What changes

### `lua/game/settings_state.lua`

- Add `self.volume = 100` in `new()` (default = full volume)
- Add `SettingsState:set_volume(v)`:
  - Clamps `v` to `[0, 100]`
  - Stores as `self.volume`
  - Calls `love.audio.setVolume(self.volume / 100)` to apply immediately

### `lua/game/scenes/settings_menu.lua`

**ITEMS table** changes from 4 to 5 entries:
```
1. Fullscreen / Window
2. Volume             ← new
3. Keybinds
4. Exit Settings
5. Leave Game
```

**Navigation** — no change to up/down/confirm/escape logic; only the wrapping bound changes from 4 to 5 (`#ITEMS` is already used dynamically, so `_btn_y0` and wrap arithmetic update automatically).

**Left/right input** — added to the main-screen `update()` path (not the keybind sub-screen):
- Read `left = love.keyboard.isDown("left") or love.keyboard.isDown("a")`
- Read `right = love.keyboard.isDown("right") or love.keyboard.isDown("d")`
- Edge-trigger: `_prev_left` / `_prev_right` (same pattern as `_prev_up` etc.)
- When `self.selected == 2` and left fires → `self._state:set_volume(self._state.volume - 10)`
- When `self.selected == 2` and right fires → `self._state:set_volume(self._state.volume + 10)`
- `open()` snapshots `_prev_left` / `_prev_right` to prevent key bleed

**`_confirm()`** — index shift:
- `selected == 2` (Volume): no-op (left/right handles adjustment)
- `selected == 3` (Keybinds): opens keybind sub-screen (was 2)
- `selected == 4` (Exit Settings): close (was 3)
- `selected == 5` (Leave Game): quit (was 4)

**`draw()`** — Volume row rendered with two-column layout (matching keybind sub-screen style):
- Left: `"Volume"` printed at `BTN_X + 10`
- Right: `"< XX% >"` right-aligned in the button, where `XX` is `self._state.volume`

### `lua/headless/stubs.lua`

Add `love.audio.setVolume = noop` alongside the existing `play` stub.

### Tests

`test_settings_state.lua`:
- Add stub for `love.audio.setVolume` at top to track calls
- New tests: default volume is 100; `set_volume(50)` updates `volume` and calls `setVolume(0.5)`; `set_volume(-10)` clamps to 0; `set_volume(150)` clamps to 100

`test_settings_menu.lua`:
- Add `love.audio.setVolume = function() end` stub (no-op; tests check `state.volume` directly)
- Update all tests that hardcode item indices or item count (tests 8–10, 14–16, 19–20, 35) for the new 5-item menu
- New tests: left/right on volume row adjusts `state.volume`; left/right on non-volume row does nothing

---

## What stays the same

- `lua/game/sound.lua` — untouched; `Sound.play()` already goes through `love.audio`, so the global volume set by `set_volume` applies automatically to all cloned sources
- No persistence: volume is memory-only, same as fullscreen and keybinds today
- Keybind sub-screen, capture mode, and all sub-screen navigation are unchanged
- Headless tests continue to run silently; `love.audio.setVolume` is a stub no-op

---

## Open questions

None — all answered before writing this doc.
