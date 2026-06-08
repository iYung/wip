## Music Fades Checklist

- [x] Task A — `lua/game/sound.lua` — Replace the single `_music` variable with `_music_tracks = {}`. Each entry keyed by track name (`"menu"`, `"bg"`) holds `{ src, fade_vol, fade_target, fade_rate, stop_on_done }`. In `Sound.load()`, load `"assets/music/menu.mp3"` as a looping `"stream"` source into `_music_tracks["menu"]` (set `fade_vol=1`, `fade_target=1`, `fade_rate=0`, `stop_on_done=false`) and play it immediately at `_music_volume`. Load `"assets/music/background.wav"` the same way into `_music_tracks["bg"]` but do NOT play it (leave it stopped and silent). Remove the old `_music` variable and its `love.audio.play` call.

- [x] Task B — `lua/game/sound.lua` — Add `Sound.update(dt)`. Iterate over all entries in `_music_tracks`. For each entry where `fade_rate ~= 0`, advance `fade_vol` toward `fade_target` by `fade_rate * dt`, clamp `fade_vol` to `[0, 1]`, apply `entry.src:setVolume(entry.fade_vol * _music_volume)`. If `fade_vol` has reached `fade_target`, set `fade_rate = 0`; if `stop_on_done` is true, call `entry.src:stop()` and set `stop_on_done = false`. (depends on Task A)

- [x] Task C — `lua/game/sound.lua` — Add `Sound.play_music(name)`. Look up `_music_tracks[name]`; if the entry exists, set `entry.fade_vol = 1`, `entry.fade_target = 1`, `entry.fade_rate = 0`, `entry.stop_on_done = false`, call `entry.src:setVolume(_music_volume)`, then `entry.src:play()`. (depends on Task A)

- [x] Task D — `lua/game/sound.lua` — Add `Sound.fade_music(name, target_vol, duration)`. Look up `_music_tracks[name]`; if the entry exists: if `target_vol > 0` and `entry.src:isPlaying()` is false, set `entry.fade_vol = 0`, call `entry.src:setVolume(0)`, then `entry.src:play()`. Set `entry.fade_target = target_vol`, `entry.fade_rate = (target_vol - entry.fade_vol) / duration`, `entry.stop_on_done = (target_vol == 0)`. (depends on Task A)

- [x] Task E — `lua/game/sound.lua` — Add `Sound.stop_music(name)`. Look up `_music_tracks[name]`; if the entry exists, call `entry.src:stop()`, then reset `entry.fade_vol = 1`, `entry.fade_target = 1`, `entry.fade_rate = 0`, `entry.stop_on_done = false`. (depends on Task A)

- [x] Task F — `lua/game/sound.lua` — Update `Sound.set_music_volume(v)`. Replace the old `if _music ~= nil then _music:setVolume(v) end` block with a loop over `_music_tracks`: for each entry, if `entry.src:isPlaying()` is true, call `entry.src:setVolume(entry.fade_vol * v)`. (depends on Task A)

- [x] Task G — `lua/headless/stubs.lua` — Add `play`, `stop`, and `isPlaying` no-ops to the stub source object returned by `make_stub_source()`. Specifically: `src.play = noop`, `src.stop = noop`, `src.isPlaying = function() return false end`. This prevents new `Sound` calls from crashing in headless tests.

- [x] Task H — `main.lua` — In `love.update(dt)`, inside the `if not _visual_mode then` branch, add `Sound.update(dt)` as the first statement before the `if settings_menu and settings_menu.is_open then` block. (depends on Tasks B–F)

- [x] Task I — `lua/game/scenes/start_scene.lua` — In `StartScene:on_enter()`, after the existing asset loads, call `Sound.play_music("menu")` only if the menu track is not already playing. Use the internal track's `src:isPlaying()` via a guard: look up `Sound`'s track state — since `Sound` does not expose the source directly, add `Sound.is_music_playing(name)` as a thin public helper in `sound.lua` (returns `_music_tracks[name] and _music_tracks[name].src:isPlaying()` or `false`) and call `if not Sound.is_music_playing("menu") then Sound.play_music("menu") end`. (depends on Tasks C, G) [NOTE: `Sound.is_music_playing` helper is already implemented in sound.lua]

- [x] Task J — `lua/game/scenes/start_scene.lua` — In `StartScene:_confirm()`, for the cases where `self.selected == 1` (New Game) or `self.selected == 2` (Continue), add `Sound.fade_music("menu", 0, 2)` immediately before the `self.scene_manager:switch(...)` call. Do not add a delay; the fade runs in the background via `Sound.update`. (depends on Task D)

- [x] Task K — `lua/game/scenes/store_scene.lua` — In `StoreScene:on_enter()`, at the top of the function body (before the `if not self._initialized` block), add `Sound.stop_music("menu")` followed by `Sound.fade_music("bg", 1, 2)`. (depends on Tasks D, E)
