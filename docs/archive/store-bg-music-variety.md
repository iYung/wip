## Store BG Music Variety Checklist

- [x] Task A — `lua/game/sound.lua` — Rename the `"bg"` track key to `"bg1"` throughout (load block and any internal references). Load `assets/music/background2.mp3` as `"bg2"` and `assets/music/background3.mp3` as `"bg3"` using the same pattern as the existing bg track: stream source, looping, volume 0, not played on load.

- [x] Task B — `lua/game/sound.lua` — Add `Sound.play_random_music(names, fade_duration)`: iterate `names`, stop any that are currently playing, pick one at random with `math.random`, then call `Sound.fade_music(picked, 1, fade_duration)`. Skip any name not present in `_music_tracks` so missing placeholder files don't error.

- [x] Task C — `lua/game/scenes/store_scene.lua` — In `StoreScene:on_enter()` replace `Sound.fade_music("bg", 1, 2)` with `Sound.play_random_music({"bg1", "bg2", "bg3"}, 2)`.

- [x] Task D — `tests/test_sound.lua` — Add tests for `Sound.play_random_music`: (1) with all three tracks present, the chosen track fades in and the others stay stopped; (2) with some tracks missing from `_music_tracks`, it falls back gracefully to the available ones without erroring.
