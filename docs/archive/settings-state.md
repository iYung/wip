## Settings State Checklist

Tasks A and B are independent and can run in parallel.
Tasks C and D depend on A and B and can run in parallel with each other after A and B complete.

---

- [x] Task A — `lua/game/settings_state.lua` — Create new file using the same Lua class pattern as `game_state.lua`. `SettingsState.new()` returns a table with `self.fullscreen = false`. Add `SettingsState:toggle_fullscreen()` which flips `self.fullscreen` and calls `love.window.setFullscreen(self.fullscreen)`. Return the class at end of file.

- [x] Task B — `lua/game/scenes/settings_menu.lua` — Update `SettingsMenu.new()` to accept a `settings_state` argument and store it as `self._state`. In `_confirm()`, replace `love.window.setFullscreen(not love.window.getFullscreen())` with `self._state:toggle_fullscreen()`. In `draw()`, replace `love.window.getFullscreen()` with `self._state.fullscreen` for the label logic on item 1.

- [x] Task C — `main.lua` — After tasks A and B. Add `local SettingsState = require("lua/game/settings_state")` with the other requires at the top. In `love.load()`, construct `local ss = SettingsState.new()` before `SettingsMenu.new()`, then pass it: `settings_menu = SettingsMenu.new(ss)`.

- [x] Task D — `tests/test_settings_menu.lua` (update) and `tests/test_settings_state.lua` (new) — After tasks A and B.
  - In `test_settings_menu.lua`: require `SettingsState`, replace `love.window.getFullscreen` stub with a direct `SettingsState` instance (`local state = SettingsState.new()`), pass it to all `SettingsMenu.new(state)` calls. Remove the `_fullscreen` / `love.window.getFullscreen` stub since `draw()` no longer calls it. Keep the `love.window.setFullscreen` stub (still called by `SettingsState:toggle_fullscreen`). Update Test 17 to check `state.fullscreen` instead of `_fullscreen`.
  - Create `tests/test_settings_state.lua`: test that `new()` defaults `fullscreen` to false, `toggle_fullscreen()` sets it to true and calls `love.window.setFullscreen(true)`, a second toggle sets it back to false and calls `love.window.setFullscreen(false)`.
