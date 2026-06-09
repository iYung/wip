# Checklist: Music Focus Resume

## `lua/game/sound.lua` — add `playing_intent` field to track entries

- [x] In `Sound.load()`, line 38–44 (`_music_tracks["menu"]` table literal): add `playing_intent = true` as a field (true because `menu_src:play()` is called immediately after on line 45).

- [x] In `Sound.load()`, line 51–57 (`_music_tracks["bg1"]` table literal): add `playing_intent = false` as a field (bg1 starts stopped).

- [x] In `Sound.load()`, line 64–70 (`_music_tracks["bg2"]` table literal): add `playing_intent = false` as a field (bg2 starts stopped).

- [x] In `Sound.load()`, line 77–83 (`_music_tracks["bg3"]` table literal): add `playing_intent = false` as a field (bg3 starts stopped).

- [x] In `Sound.load()`, line 90–96 (`_music_tracks["bg4"]` table literal): add `playing_intent = false` as a field (bg4 starts stopped).

## `lua/game/sound.lua` — set `playing_intent` on every play/stop call site

- [x] In `Sound.play_music()` (line 167, after `entry.src:play()`): set `entry.playing_intent = true`.

- [x] In `Sound.fade_music()` (line 177, after `entry.src:play()` in the `target_vol > 0` branch): set `entry.playing_intent = true`.

- [x] In `Sound.stop_music()` (line 188, after `entry.src:stop()`): set `entry.playing_intent = false`.

- [x] In `Sound.update()` (line 151–153, the `stop_on_done` branch that calls `entry.src:stop()` and sets `entry.stop_on_done = false`): also set `entry.playing_intent = false` in that same block.

- [x] In `Sound.play_random_music()` (line 210–215, inside the loop that calls `entry.src:stop()` for currently-playing valid tracks): also set `entry.playing_intent = false` for each stopped entry.

## `lua/game/sound.lua` — add `Sound.on_focus(focused)` function

- [x] Add a new function `Sound.on_focus(focused)` anywhere before the `return Sound` line (line 229). The function must: (1) guard with `if not love.audio then return end`; (2) when `focused` is true, iterate `_music_tracks` and, for each entry where `entry.playing_intent == true` and `entry.src:isPlaying() == false`, call `entry.src:setVolume(entry.fade_vol * _music_volume)` then `entry.src:play()`; (3) do nothing on focus-out.

## `main.lua` — wire up `love.focus`

- [x] (Depends on the `Sound.on_focus` item above.) In `main.lua`, after the `love.quit` function (line 185–190), add a new top-level callback:
  ```lua
  function love.focus(focused)
      Sound.on_focus(focused)
  end
  ```
  `Sound` is already required at line 34, so no new require is needed.
