## Background Music Checklist

- [x] Task 1 — `lua/game/sound.lua` — Add music source and per-source volume control (independent; no dependencies).
  - Add module-level `_sfx_volume = 1.0` and `_music_volume = 1.0` at the top alongside `_src = {}`.
  - Add `_music = nil` for the looping music `Source`.
  - In `Sound.load()`, after the SFX loading loop, attempt to load `assets/music/background.mp3` as a `"stream"` source: if `love.filesystem.getInfo("assets/music/background.mp3")` returns truthy, call `love.audio.newSource(...)`, set looping true via `_music:setLooping(true)`, set volume via `_music:setVolume(_music_volume)`, then call `love.audio.play(_music)`. If the file is absent, do nothing (silent skip).
  - In `Sound.play()`, call `local clone = s:clone()` then `clone:setVolume(_sfx_volume)` before passing the clone to `love.audio.play()`.
  - Add `Sound.set_sfx_volume(v)` — stores `v` into `_sfx_volume`; no other action needed (future clones pick up the new level automatically).
  - Add `Sound.set_music_volume(v)` — stores `v` into `_music_volume`; if `_music ~= nil`, also calls `_music:setVolume(v)` immediately so a playing track responds in real time.

- [x] Task 2 — `lua/game/settings_state.lua` — Rename `volume` to `sfx_volume`, add `music_volume`, rewire setters to call Sound (depends on Task 1 because it calls `Sound.set_sfx_volume` and `Sound.set_music_volume`).
  - Add `local Sound = require("lua/game/sound")` at the top of the file.
  - In `SettingsState.new()`, rename `self.volume = 100` to `self.sfx_volume = 100` and add `self.music_volume = 100`.
  - Remove the existing `set_volume()` method entirely.
  - Add `SettingsState:set_sfx_volume(v)`: clamp `v` to `[0, 100]` using `math.max(0, math.min(100, v))`, store into `self.sfx_volume`, then call `Sound.set_sfx_volume(self.sfx_volume / 100)`. Do NOT call `love.audio.setVolume()`.
  - Add `SettingsState:set_music_volume(v)`: clamp `v` to `[0, 100]`, store into `self.music_volume`, then call `Sound.set_music_volume(self.music_volume / 100)`. Do NOT call `love.audio.setVolume()`.

- [x] Task 3 — `lua/game/scenes/settings_menu.lua` — Expand ITEMS to 6 entries, fix all indices, add Music Volume row rendering and input (depends on Task 2 because it calls `set_sfx_volume` and `set_music_volume` on the state).
  - Change `ITEMS` to: `{ "Fullscreen / Window", "SFX Volume", "Music Volume", "Keybinds", "Exit Settings", "Leave Game" }`.
  - In `update()`, change the left/right handling so that:
    - `self.selected == 2` calls `self._state:set_sfx_volume(self._state.sfx_volume - 10)` (left) and `self._state:set_sfx_volume(self._state.sfx_volume + 10)` (right).
    - `self.selected == 3` calls `self._state:set_music_volume(self._state.music_volume - 10)` (left) and `self._state:set_music_volume(self._state.music_volume + 10)` (right).
    - Remove all references to the old `set_volume` / `state.volume`.
  - In `_confirm()`, update the index shift:
    - `selected == 4` → open keybinds sub-screen (was 3).
    - `selected == 5` → close (was 4).
    - `selected == 6` → `love.event.quit()` (was 5).
    - Remove the old `elseif self.selected == 3` keybinds branch and replace with `elseif self.selected == 4`.
  - In `draw()`, inside the `for i = 1, #ITEMS` loop, update the per-row rendering:
    - `i == 1` — unchanged (Fullscreen/Window toggle label).
    - `i == 2` — label `"SFX Volume"` on the left, `"< XX% >"` on the right using `self._state.sfx_volume`.
    - `i == 3` — label `"Music Volume"` on the left, `"< XX% >"` on the right using `self._state.music_volume`. Use the same two-column print pattern as the SFX Volume row.
    - `i >= 4` — `love.graphics.printf(ITEMS[i], ...)` centered (same as existing else branch).
  - `_btn_y0` already uses `#ITEMS` dynamically, so no change needed there.

- [x] Task 4 — `lua/headless/stubs.lua` — Update the audio stub to match the new runtime contract (independent; no dependencies on other tasks, but should be done before running tests that exercise Sound or SettingsState).
  - Remove the `love.audio.setVolume = noop` line (it is no longer called at runtime, and removing it lets any accidental call cause a visible test error rather than silently passing).
  - Ensure `love.audio.newSource` stub is present and returns a stub source object with `setLooping`, `setVolume`, and `clone` methods in addition to `clone`. Update `make_stub_source()` to add `setLooping = noop` and `setVolume = noop` fields so that `Sound.load()`'s calls to `_music:setLooping(true)` and `_music:setVolume(v)` do not error in headless mode.

- [x] Task 5 — `tests/test_sound.lua` — Add tests for `set_sfx_volume` and `set_music_volume` (depends on Tasks 1 and 4).
  - Add a test that calls `Sound.set_sfx_volume(0.5)` and then calls `Sound.play("pick_up")`; verify no error is raised (headless mode guard still applies). Print `PASS: set_sfx_volume sets level without error`.
  - Add a test that calls `Sound.set_sfx_volume(0)` and `Sound.set_sfx_volume(1)` to confirm boundary values do not error. Print `PASS: set_sfx_volume accepts boundary values`.
  - Add a test that calls `Sound.set_music_volume(0.7)` and verifies no error is raised. Print `PASS: set_music_volume sets level without error`.
  - Add a test that calls `Sound.set_music_volume(0)` and `Sound.set_music_volume(1)` to confirm boundary values do not error. Print `PASS: set_music_volume accepts boundary values`.

- [x] Task 6 — `tests/test_settings_state.lua` — Update for renamed fields; add `sfx_volume` and `music_volume` tests (depends on Tasks 2 and 4).
  - Remove the `love.audio.setVolume` spy setup at the top (`_setVolume_last` variable and override) — it is no longer needed.
  - Replace Test 9 (`new() defaults volume to 100`) to assert `sv.sfx_volume == 100` instead of `sv.volume == 100`. Update print message to `"PASS: new() defaults sfx_volume to 100"`.
  - Add a test asserting `sv.music_volume == 100` on a fresh `SettingsState.new()`. Print `"PASS: new() defaults music_volume to 100"`.
  - Replace Tests 10–12 (the three `set_volume` tests) with equivalent tests for `set_sfx_volume`:
    - Test: `set_sfx_volume(50)` stores `sfx_volume == 50` (no assertion on `love.audio.setVolume`). Print `"PASS: set_sfx_volume stores value"`.
    - Test: `set_sfx_volume(-10)` clamps to `sfx_volume == 0`. Print `"PASS: set_sfx_volume clamps to 0"`.
    - Test: `set_sfx_volume(150)` clamps to `sfx_volume == 100`. Print `"PASS: set_sfx_volume clamps to 100"`.
  - Add equivalent tests for `set_music_volume`:
    - Test: `set_music_volume(70)` stores `music_volume == 70`. Print `"PASS: set_music_volume stores value"`.
    - Test: `set_music_volume(-5)` clamps to `music_volume == 0`. Print `"PASS: set_music_volume clamps to 0"`.
    - Test: `set_music_volume(200)` clamps to `music_volume == 100`. Print `"PASS: set_music_volume clamps to 100"`.

- [x] Task 7 — `tests/test_settings_menu.lua` — Update for 6-item menu and new indices; add music volume row tests (depends on Tasks 3, 4, and 6 because the menu reads `sfx_volume`/`music_volume` from state).
  - Remove the `love.audio.setVolume = function() end` stub at the top (no longer called; let any accidental call fail visibly).
  - Update Test 8 (down wrap): change from `5->1` to `6->1`: add one more `sim_key(m, "down")` call so all 6 items are traversed before wrapping. Update assertions and print message to reference 6 items.
  - Update Test 9 (up from 1 wraps to last item): assert `m.selected == 6` instead of `5`. Update print message.
  - Update Test 10 (up navigation): extend to navigate through all 6 rows (add assertions for `selected == 5` and `selected == 6` in the chain). Update print message.
  - Update Test 14 (Exit Settings at index 4 → now index 5): add an extra `sim_key(m, "down")` so selection reaches index 5 (Exit Settings). Update assertion and print message.
  - Update Test 15 (Leave Game at index 5 → now index 6): add an extra `sim_key(m, "down")` so selection reaches index 6. Update assertion and print message.
  - Update Test 16 (e key confirms Leave Game): same index fix as Test 15 — navigate to index 6 before confirming.
  - Update Test 19 (item count wraps at 5 → now wraps at 6): add one more `sim_key(m, "down")` (6 total) and assert `m.selected == 1`. Update print message to `"PASS: item count wraps at 6"`.
  - Update Test 20 (item 3 opens keybinds → now item 4): add an extra `sim_key(m, "down")` so selection reaches index 4 before confirming. Update assertion and print message.
  - Update Test 35 (sub-screen re-entry at `m.selected = 3` → now `m.selected = 4`): change `m.selected = 3` to `m.selected = 4`. Update print message.
  - Update Tests 36–38 (volume row at index 2 still index 2 — but field name and method change):
    - Test 36: set `state.sfx_volume = 50` (was `state.volume`), navigate to index 2, press left, assert `state.sfx_volume == 40`. Update print message to `"PASS: left on SFX Volume row decreases sfx_volume"`.
    - Test 37: set `state.sfx_volume = 50`, navigate to index 2, press right, assert `state.sfx_volume == 60`. Update print message.
    - Test 38: set `state.sfx_volume = 50`, stay on row 1, press left then right, assert `state.sfx_volume == 50`. Update print message.
  - Add Test 39: Music Volume row (index 3) responds to left/right:
    - Set `state.music_volume = 50`, navigate to index 3, press left, assert `state.music_volume == 40`. Print `"PASS: left on Music Volume row decreases music_volume"`.
  - Add Test 40: Music Volume row (index 3) increases on right:
    - Set `state.music_volume = 50`, navigate to index 3, press right, assert `state.music_volume == 60`. Print `"PASS: right on Music Volume row increases music_volume"`.
  - Add Test 41: left/right on row 1 (Fullscreen) does not change `music_volume`:
    - Set `state.music_volume = 50`, ensure `m.selected == 1`, press left then right, assert `state.music_volume == 50`. Print `"PASS: left/right on non-music row leaves music_volume unchanged"`.
