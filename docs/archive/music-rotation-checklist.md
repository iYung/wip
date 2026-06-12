# Checklist: Music Rotation (no repeat, no looping)

## `lua/game/sound.lua` — load-time setup

- [x] In `Sound.load()`, remove `setLooping(true)` from the bg1, bg2, bg3, bg4 track entries only; leave `menu` looping unchanged.
- [x] In `Sound.load()`, set `entry.is_bg = true` for bg1, bg2, bg3, bg4; leave all other tracks without this field (or `false`).

## `lua/game/sound.lua` — `play_random_music` exclusion parameter

- [x] Add an optional third parameter `exclude_name` to `Sound.play_random_music(names, fade_duration, exclude_name)`.
- [x] Build a `valid` list inside `play_random_music` that filters out `exclude_name`; if the filtered list is empty, fall back to all entries in `names` that exist in `_music_tracks`.
- [x] Use `valid[math.random(#valid)]` to pick the next track; call `Sound.fade_music(picked, 1, fade_duration)` to start it.

## `lua/game/sound.lua` — `Sound.update` end-of-track detection

- [x] Change `Sound.update(dt)` signature to `Sound.update(dt, on_bg_ended)` (second arg optional).
- [x] Inside the per-track loop in `Sound.update`, after existing fade logic, add the end-of-track check: if `entry.is_bg and entry.playing_intent and not entry.stop_on_done and not entry.src:isPlaying()` then set `entry.playing_intent = false` and call `on_bg_ended(name)` if the callback is provided.
- [x] Confirm no separate `_bg_ended_fired` flag is needed — the `entry.playing_intent = false` assignment is the sole guard against re-firing.

## `lua/game/sound.lua` — `Sound.get_playing_bg()` helper (optional, if needed by StoreScene)

- [x] Add `Sound.get_playing_bg()` that iterates `_music_tracks`, returns the name of the first entry where `entry.is_bg and entry.playing_intent`, or `nil` if none.

## `lua/game/scenes/store_scene.lua` — wire callback in `update`

- [x] In `StoreScene:update(dt)`, change the `Sound.update(dt)` call to pass an `on_bg_ended` callback:
  ```lua
  Sound.update(dt, function(ended_name)
      Sound.play_random_music({"bg1","bg2","bg3","bg4"}, 2, ended_name)
  end)
  ```
- [x] Verify `StoreScene:on_enter()` is NOT modified — the existing `_bg_playing` guard and initial `play_random_music` call remain as-is.

## Verify other callers of `Sound.update`

- [x] Search the codebase for all other `Sound.update(` call sites (e.g. `main.lua`, `BuyScene`); confirm they pass only `dt` and that the new optional second parameter does not break them.
