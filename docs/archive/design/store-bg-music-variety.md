## Goal

Add two more background music tracks for the store scene. Each time the player enters the store from the main menu, one of three tracks is picked at random and looped.

## Affected files

- `lua/game/sound.lua` — load bg2/bg3 tracks; rename "bg" key to "bg1"; add `Sound.play_random_music(names, fade_duration)`
- `lua/game/scenes/store_scene.lua` — replace `Sound.fade_music("bg", 1, 2)` with a call to the new random-pick helper
- `assets/music/background2.mp3` — placeholder (drop file in to activate)
- `assets/music/background3.mp3` — placeholder (drop file in to activate)
- `tests/test_sound.lua` — add coverage for `play_random_music`

## What changes

### sound.lua

- Load `background2.mp3` as track key `"bg2"` and `background3.mp3` as `"bg3"`, each starting stopped and silent (same pattern as the current `"bg"` track).
- Rename the existing `"bg"` key to `"bg1"` so all three are consistent.
- Add `Sound.play_random_music(names, fade_duration)`:
  - Stops every track in `names` that is currently playing.
  - Picks one entry at random (`math.random`).
  - Fades the chosen track in over `fade_duration` seconds (delegates to `Sound.fade_music`).
  - Missing tracks (file not present at load time) are silently skipped so the game works even with placeholder filenames not yet on disk.

### store_scene.lua

In `StoreScene:on_enter()` replace:
```lua
Sound.stop_music("menu")
Sound.fade_music("bg", 1, 2)
```
with:
```lua
Sound.stop_music("menu")
Sound.play_random_music({"bg1", "bg2", "bg3"}, 2)
```

Re-randomization happens on every entry — no persistence between visits.

## What stays the same

- Menu music behaviour (`menu.mp3`, `Sound.play_music("menu")`, fade-out on New Game / Load Game) is untouched.
- All other `Sound.*` functions and their call sites are untouched.
- The fade system (rate, target, stop_on_done) is reused as-is.
- Exit from the store does not stop the bg track (same as today).

## Open questions

None — placeholders confirmed, re-randomize-every-entry confirmed.
