# Background Music

## Goal

Add looping background music that plays continuously across all scenes (title + gameplay), with its own volume slider in the settings menu independent of the existing SFX volume slider. The SFX slider is renamed from "Volume" to "SFX Volume".

---

## Affected files

**Modified:**
- `lua/game/sound.lua` — add music source, `set_sfx_volume()`, `set_music_volume()`, apply per-clone SFX volume
- `lua/game/settings_state.lua` — rename `volume`→`sfx_volume`, add `music_volume`; rewire setters to call Sound directly instead of `love.audio.setVolume()`
- `lua/game/scenes/settings_menu.lua` — rename "Volume" row to "SFX Volume", add "Music Volume" row (item 3), update all hard-coded indices
- `lua/headless/stubs.lua` — add any new Love2D stubs needed by updated Sound / SettingsState
- `tests/test_settings_state.lua` — update for renamed fields; add music_volume tests
- `tests/test_settings_menu.lua` — update for 6-item menu and new indices; add music volume row tests
- `tests/test_sound.lua` — add tests for `set_sfx_volume` and `set_music_volume`

**New (optional asset):**
- `assets/music/background.mp3` — placeholder slot; Sound gracefully skips if absent

---

## What changes

### Why `love.audio.setVolume()` is dropped

Love2D's global `love.audio.setVolume()` is a master multiplier that scales **all** sources, including music. If we kept it for SFX, changing SFX volume would also scale music volume — the two sliders would not be independent. The fix is to set the global to `1.0` and never touch it again, applying per-category volume at the source level instead.

---

### `lua/game/sound.lua`

- Add module-level `_sfx_volume = 1.0` and `_music_volume = 1.0`
- Add `_music = nil` for the looping background `Source`
- In `Sound.load()`: after loading SFX, attempt to load `assets/music/background.mp3` as a `"stream"` source. If the file exists: set looping true, set volume to `_music_volume`, and call `love.audio.play(_music)`. If absent: silently skip (same pattern as `try_img` in assets.lua).
- In `Sound.play()`: apply `clone:setVolume(_sfx_volume)` on each clone before playing.
- Add `Sound.set_sfx_volume(v)` (v is 0..1) — stores `_sfx_volume`. Already-playing fire-and-forget clones are unaffected; new clones pick up the new level.
- Add `Sound.set_music_volume(v)` (v is 0..1) — stores `_music_volume`; if `_music` is loaded, calls `_music:setVolume(v)` immediately.

### `lua/game/settings_state.lua`

- Rename `self.volume` → `self.sfx_volume` (default 100)
- Add `self.music_volume = 100`
- Replace `set_volume()` with `set_sfx_volume(v)`: clamps to [0,100], stores, calls `Sound.set_sfx_volume(self.sfx_volume / 100)`. Requires `lua/game/sound` at top of file (no circular dependency — Sound doesn't require SettingsState).
- Add `set_music_volume(v)`: clamps to [0,100], stores, calls `Sound.set_music_volume(self.music_volume / 100)`.
- Remove the `love.audio.setVolume()` call entirely.

### `lua/game/scenes/settings_menu.lua`

ITEMS table becomes 6 entries:
```
1. Fullscreen / Window
2. SFX Volume          ← renamed
3. Music Volume        ← new
4. Keybinds            ← was 3
5. Exit Settings       ← was 4
6. Leave Game          ← was 5
```

- `_confirm()` index shift: selected==4 opens keybinds, selected==5 closes, selected==6 quits.
- Left/right input: when `self.selected == 2` → `set_sfx_volume`; when `self.selected == 3` → `set_music_volume`. Both rows render with the same two-column `"< XX% >"` layout.
- `draw()`: add the Music Volume row with label `"Music Volume"` left and `"< XX% >"` right using `self._state.music_volume`.
- `_btn_y0` uses `#ITEMS` dynamically, so vertical centering adjusts automatically.

### `lua/headless/stubs.lua`

- Remove the `love.audio.setVolume` stub (no longer called at runtime).
- Add `love.audio.newSource` stub if not already present (needed for Sound.load() in any future headless tests that call it; currently Sound.load() guards with `if not love.audio`).

---

## What stays the same

- `main.lua` — no changes; `Sound.load()` is already called after the settings state is created, and the global volume starts at 1.0 by default.
- The keybind sub-screen and capture mode — entirely unchanged.
- No persistence — volume values are memory-only, consistent with all other settings today.
- Music is entirely optional: the game runs and sounds correctly with no music file present.
- SFX fire-and-forget behaviour — `Sound.play()` still clones and discards; only new clones pick up a changed SFX volume (in-flight clones are too short-lived to matter).

---

## Open questions

None — all answered before writing this doc.
