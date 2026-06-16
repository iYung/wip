## Bg Track Cycling Checklist

- [x] Task A — `lua/core/sound.lua` + `main.lua` — Add a `looping` boolean field to the music manifest; honour it in `Sound.load` instead of always calling `src:setLooping(true)`. Set bg1–bg4 to `looping = false` in `main.lua` so they stop at the end of one play instead of repeating. `menu` keeps its implicit looping behaviour (no field = default true).

- [x] Task B — `lua/game/scenes/store_scene.lua` — Replace the random-pick-and-never-change bg music logic with a sequential cycle:
  - In `StoreScene.new()`: add `self._bg_list = {"bg1", "bg2", "bg3", "bg4"}` and `self._bg_index = math.random(4)`.
  - In `StoreScene:on_enter()`: replace the `play_random_music` guard block with — if no track in `_bg_list` is currently playing, call `Sound.fade_music(_bg_list[_bg_index], 1, 2)`.
  - In `StoreScene:update(dt)`: after existing logic, check `not Sound.is_music_playing(_bg_list[_bg_index])`; if true, advance `_bg_index` to `(_bg_index % #_bg_list) + 1` and call `Sound.fade_music(_bg_list[_bg_index], 1, 2)`.
