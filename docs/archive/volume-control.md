# Volume Control Checklist

- [x] Task A — `lua/headless/stubs.lua` — Add `love.audio.setVolume = noop` alongside the existing `play` stub so `SettingsState:set_volume()` never hits a nil in headless/test mode.

- [x] Task B — `lua/game/settings_state.lua` — Add `self.volume = 100` in `new()`. Add `SettingsState:set_volume(v)`: clamp `v` to `[0, 100]`, store as `self.volume`, call `love.audio.setVolume(self.volume / 100)`.

- [x] Task C — `lua/game/scenes/settings_menu.lua` — Five changes:
  1. Change `ITEMS` to `{ "Fullscreen / Window", "Volume", "Keybinds", "Exit Settings", "Leave Game" }`.
  2. Add `self._prev_left = false` and `self._prev_right = false` in `new()`.
  3. In `open()`, snapshot `self._prev_left = love.keyboard.isDown("left") or love.keyboard.isDown("a")` and `self._prev_right = love.keyboard.isDown("right") or love.keyboard.isDown("d")`.
  4. In `update()` main-screen path: read `left`/`right` keys; when `self.selected == 2` and left edge-fires call `self._state:set_volume(self._state.volume - 10)`; right → `+ 10`; update `_prev_left`/`_prev_right` at end.
  5. In `_confirm()`: shift existing branches to indices 3/4/5; index 2 (Volume) is a no-op. In `draw()`: for `i == 2` use two-column layout — `love.graphics.print("Volume", BTN_X + 10, ty)` and `love.graphics.printf("< " .. tostring(self._state.volume) .. "% >", BTN_X, ty, BTN_W - 10, "right")`.

  **Depends on Task B** (calls `set_volume`).

- [x] Task D — `tests/test_settings_state.lua` — At the top of the file add `local _setVolume_last = nil; love.audio = love.audio or {}; love.audio.setVolume = function(v) _setVolume_last = v end`. Add four new tests after the existing eight:
  - `new()` defaults `volume` to 100
  - `set_volume(50)` sets `s.volume == 50` and called `love.audio.setVolume(0.5)`
  - `set_volume(-10)` clamps: `s.volume == 0`
  - `set_volume(150)` clamps: `s.volume == 100`

  **Depends on Task B**.

- [x] Task E — `tests/test_settings_menu.lua` — Two parts:
  1. **Fix index-dependent tests** broken by the 4→5 item expansion: Test 8 (add one `sim_key(m,"down")`), Test 9 (assert wraps to 5), Test 10 (add one `sim_key`+assert for 5→4), Test 14 (add one down; assert `selected==4`; item label "Exit Settings"), Test 15 (add one down; assert `selected==5`; item label "Leave Game"), Test 16 (add one down to reach Leave Game), Test 19 (5 downs wraps to 1), Test 20 (two downs to reach Keybinds at index 3), Test 35 (`m.selected = 3` instead of 2).
  2. **Add volume tests** at the end (before `love.event.quit = _real_quit`): add `love.audio.setVolume = function() end` stub near the top; test that left on volume row decreases `state.volume` by 10; right increases by 10; left/right on a non-volume row leaves `state.volume` unchanged.

  **Depends on Task C**.
